import promptAction from '@ohos.promptAction'
import http from '@ohos.net.http'

// 聊天消息类
export class ChatMessage {
  sender: string // 'User' 或 'AI'
  content: string
  timestamp: Date

  constructor(sender: string, content: string, timestamp: Date) {
    this.sender = sender
    this.content = content
    this.timestamp = timestamp
  }
}

// 定义消息接口
interface MessageInterface {
  role: string
  content: string
}

// 定义请求数据接口
interface RequestDataInterface {
  model: string
  messages: MessageInterface[]
}

// 定义消息内容接口
interface MessageContentInterface {
  content: string
}

// 定义消息选择接口
interface MessageChoiceInterface {
  message: MessageContentInterface
}

// 定义API响应接口
interface ApiResponseInterface {
  choices: MessageChoiceInterface[]
}

// AI服务类 - 处理对话逻辑
export class AIChatService {
  // Kimi API Key
  private static API_KEY = ''
  // API基础URL
  private static BASE_URL = ''

  // 牡丹知识系统提示词
  private static SYSTEM_PROMPT = `你是一个专业的牡丹花卉专家，名为"牡丹小精灵"。你拥有关于牡丹的丰富知识，包括但不限于：
  1. 牡丹的品种分类：中国传统名品如"姚黄"、"魏紫"、"赵粉"、"洛阳红"等，以及现代培育的各类新品种。
  2. 牡丹的栽培技术：包括土壤选择、施肥方法、浇水技巧、修剪方式、病虫害防治等。
  3. 牡丹的历史文化：牡丹在中国历史上的地位、文学艺术中的表现、民间传说等。
  4. 牡丹的观赏价值：花期特点、观赏重点、不同品种的美学特性等。
  5. 牡丹的药用价值：牡丹皮、牡丹籽等的药用功效与应用。
  6. 牡丹的园艺应用：在园林景观中的配置、盆栽技巧等。
  7. 牡丹与其他花卉的区别：如牡丹与芍药的区别。
  8. 世界各地的牡丹：包括中国洛阳、菏泽等牡丹名产地，以及日本、美国等国家的牡丹特色。
  请用亲切、专业的语气回答用户的问题，根据问题的具体内容提供详细准确的信息。如果用户问的问题超出了牡丹相关知识范围，请礼貌地引导用户回到牡丹话题。你的回答应该简洁明了，易于理解，但同时要体现出专业性。
  在回答关于牡丹栽培的问题时，请考虑到不同地区的气候差异，给出适合用户所在地区的建议。如果用户没有提供地区信息，可以询问或提供适用于一般情况的建议。
  请记住，你是牡丹领域的专家，你的目标是帮助用户了解、欣赏和栽培牡丹，传播牡丹文化的美好。
  非常重要：输出的内容绝对不要使用markdown的格式，不要使用标题、加粗、斜体、代码块等任何markdown语法，直接使用纯文本输出即可。`

  // 使用Kimi API获取回复 - 支持对话上下文
  static async callKimiAPI(messages: MessageInterface[]): Promise<string> {
    let httpRequest: http.HttpRequest | undefined;
    try {
      // 创建HTTP请求客户端
      httpRequest = http.createHttp();
      if (!httpRequest) {
        throw new Error('HTTP客户端创建失败');
      }

      const apiKey = AIChatService.API_KEY;
      const baseUrl = AIChatService.BASE_URL;

      // 添加系统提示词到消息开头
      const messagesWithSystemPrompt: MessageInterface[] = [
        { role: 'system', content: AIChatService.SYSTEM_PROMPT } as MessageInterface,
        ...messages
      ];

      // 准备请求数据
      const requestData: RequestDataInterface = {
        model: 'moonshot-v1-8k',
        messages: messagesWithSystemPrompt
      };

      // 设置请求选项，包括超时时间
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + apiKey
        },
        extraData: JSON.stringify(requestData),
        connectTimeout: 10000, // 10秒连接超时
        readTimeout: 30000     // 30秒读取超时
      };

      // 发送POST请求
      let response = await httpRequest.request(baseUrl, options);

      // 解析响应
      if (response.responseCode === 200) {
        const responseText = response.result?.toString() || '';
        if (!responseText) {
          console.error('API返回了空响应');
          return AIChatService.getFallbackResponse('API返回空响应');
        }

        try {
          const responseData: ApiResponseInterface = JSON.parse(responseText);
          if (responseData && responseData.choices && responseData.choices.length > 0 &&
          responseData.choices[0].message && responseData.choices[0].message.content) {
            return responseData.choices[0].message.content;
          } else {
            console.error('API响应格式不正确:', responseText);
            return AIChatService.getFallbackResponse('API格式错误');
          }
        } catch (parseError) {
          console.error('解析API响应出错:', parseError);
          return AIChatService.getFallbackResponse('解析API响应出错');
        }
      } else {
        console.error('API调用失败，状态码：', response.responseCode);
        const lastMessage = messages.length > 0 ? messages[messages.length - 1].content : '用户消息';
        return AIChatService.getFallbackResponse(lastMessage);
      }
    } catch (error) {
      console.error('API调用出错：', error);
      const lastMessage = messages.length > 0 ? messages[messages.length - 1].content : '用户消息';
      return AIChatService.getFallbackResponse(lastMessage);
    } finally {
      // 确保始终关闭HTTP客户端，避免资源泄漏
      if (httpRequest) {
        try {
          httpRequest.destroy();
        } catch (error) {
          console.error('销毁HTTP客户端失败:', error);
        }
      }
    }
  }

  // 本地回复作为备用
  static getFallbackResponse(userInput: string): string {
    const lowerInput = userInput.toLowerCase()

    // 详细的牡丹知识问答规则
    if (lowerInput.includes('你好') || lowerInput.includes('您好') || lowerInput.includes('hi') || lowerInput.includes('hello')) {
      return '您好！我是牡丹小精灵，很高兴为您提供关于牡丹花的专业咨询服务。有什么关于牡丹的问题我可以帮助您解答吗？'
    } else if (lowerInput.includes('名字') || lowerInput.includes('叫什么')) {
      return '我是牡丹小精灵，专门为牡丹爱好者提供专业的咨询服务。我的名字寓意着智慧与灵性，希望能为您带来关于牡丹的智慧之光。'
    } else if (lowerInput.includes('谢谢') || lowerInput.includes('感谢')) {
      return '不客气！分享牡丹知识是我的荣幸。如果您还有其他关于牡丹的问题，随时可以询问我。祝您赏花愉快！'
    } else if (lowerInput.includes('养') || lowerInput.includes('种植') || lowerInput.includes('栽培')) {
      return '牡丹栽培需要注意以下几点：\n\n1. 环境：选择阳光充足、通风良好的位置，牡丹喜光但忌强光暴晒，适宜半阴环境。\n2. 土壤：偏碱性、肥沃疏松、排水良好的沙质壤土最佳，pH值在6.5-7.5之间。\n3. 栽种时间：北方地区以秋季为佳(9-10月)，南方则春季(2-3月)更适宜。\n4. 种植方法：挖60厘米见方的坑，施入充分腐熟的有机肥作基肥，株距50-70厘米。\n5. 水分管理：保持土壤湿润但不积水，尤其是生长期和花期需水较多。\n6. 施肥：每年春季萌芽前、花后和秋季各施一次有机肥。\n7. 修剪：花后及时摘除残花，秋季修剪过密枝条。\n8. 越冬保护：北方地区冬季需覆盖保护，防止冻害。'
    } else if (lowerInput.includes('品种') || lowerInput.includes('种类')) {
      return '牡丹品种繁多，中国传统上按花色分为九大色系：\n\n1. 白色系：如"白雪塔"、"冰清玉洁"等，洁白典雅。\n2. 黄色系：如"姚黄"、"金钱桂"等，被视为最珍贵的品种之一。\n3. 粉色系：如"霓裳羽衣"、"赵粉"等，温婉可人。\n4. 红色系：如"火炼金丹"、"骥红"等，热烈奔放。\n5. 紫色系：如"魏紫"、"紫佩金章"等，华贵典雅。\n6. 绿色系：如"碧桃春"、"绿香球"等，清新脱俗。\n7. 黑色系：如"墨龙珠"、"乌云漏月"等，神秘深邃。\n8. 蓝色系：通过特殊技术培育，如"蓝宝石"等。\n9. 复色系：如"二乔"、"锦上添花"等，多色相间。\n\n其中最著名的是"洛阳四大名品"：姚黄、魏紫、赵粉和尉粉。近代还有许多名贵品种如"冠世芳"、"凤丹紫"等。'
    } else if (lowerInput.includes('历史') || lowerInput.includes('文化')) {
      return '牡丹在中国有着悠久的历史和深厚的文化底蕴：\n\n1. 历史渊源：牡丹原产于中国，最早在周代就有记载，汉代已开始人工栽培。\n2. 兴盛时期：唐代是牡丹文化的重要发展期，武则天曾下令将洛阳的牡丹移栽长安；宋代达到鼎盛，出现了专门的牡丹谱录。\n3. 文化地位：牡丹被称为"花中之王"、"国色天香"，象征着富贵、尊贵和美好。\n4. 文学艺术：李白、白居易、欧阳修等众多文人墨客都有咏牡丹诗词；牡丹也是中国传统绘画的重要题材。\n5. 园艺发展：洛阳自古就是牡丹名产地，宋代"洛阳牡丹甲天下"，形成了独特的牡丹园艺文化。\n6. 民间传说：有"神奇的牡丹仙子"、"吕洞宾醉酒题诗"等众多民间故事。\n7. 现代意义：1994年，牡丹被定为中国国花(与梅花并列)，成为国家形象的重要象征。'
    } else if (lowerInput.includes('花期') || lowerInput.includes('什么时候开花')) {
      return '牡丹的花期因品种、地区和气候而异：\n\n1. 一般花期：在北方地区通常为4月中旬至5月中旬，南方地区可能提前至3月下旬开始。\n2. 品种差异：根据开花时间可分为早、中、晚三类品种：\n   - 早花品种：如"凤丹紫"、"葛巾紫"等，比一般品种提前7-10天开花。\n   - 中花品种：如"姚黄"、"魏紫"等主流品种，在当地牡丹盛花期开放。\n   - 晚花品种：如"朱砂莲"、"玉楼春"等，比一般品种晚7-15天开花。\n3. 地区差异：由南向北，花期逐渐推迟，如杭州约在3月底至4月中旬，洛阳在4月中下旬，北京则在4月底至5月中旬。\n4. 延长观赏：通过合理搭配早、中、晚花期品种，可以将牡丹观赏期延长至1个多月。\n5. 气候影响：温暖春季会使花期提前，寒冷春季则会推迟花期。全球气候变化也在影响牡丹的传统花期规律。'
    } else if (lowerInput.includes('牡丹') && lowerInput.includes('芍药') && (lowerInput.includes('区别') || lowerInput.includes('不同'))) {
      return '牡丹与芍药的主要区别：\n\n1. 植物类型：牡丹是落叶灌木，芍药是多年生草本植物。\n2. 茎干特征：牡丹有木质化的枝干，冬季不会完全枯萎；芍药的茎是草质的，冬季地上部分会完全枯萎。\n3. 叶片形态：牡丹叶片较大，分裂较深，呈革质；芍药叶片较小，分裂较浅，质地较薄。\n4. 花朵特点：牡丹花朵多为单瓣或半重瓣，花色多样；芍药多为重瓣，花色相对较少。\n5. 花期时间：一般而言，芍药花期略晚于牡丹，牡丹4-5月开花，芍药5-6月开花。\n6. 生长习性：牡丹喜阳光，较耐寒；芍药稍耐阴，也耐寒。\n7. 分类地位：牡丹属于毛茛科牡丹属，芍药属于毛茛科芍药属。\n8. 药用价值：牡丹以根皮(丹皮)入药，芍药多以根(白芍、赤芍)入药。\n9. 文化地位：牡丹被称为"花中之王"，芍药被称为"花相"或"花中之相"。'
    } else if (lowerInput.includes('药用') || lowerInput.includes('药材') || lowerInput.includes('医药')) {
      return '牡丹的药用价值主要体现在以下几方面：\n\n1. 药用部位：主要利用牡丹的根皮，中医称为"丹皮"或"牡丹皮"；其次是种子，称为"牡丹籽"。\n2. 主要功效：丹皮性微寒，味辛、苦，具有清热凉血、活血化瘀、退虚热的功效。\n3. 化学成分：含有芍药苷、牡丹酚、丹皮酚等多种活性成分。\n4. 常见应用：\n   - 用于热入营血、温病发斑、血热吐衄等症。\n   - 治疗血瘀经闭、痛经、跌打损伤等瘀血症。\n   - 对肝郁化火、胁痛、乳痈、痈疽肿毒有较好效果。\n5. 现代研究：现代药理学研究表明，丹皮具有抗菌、抗炎、镇痛、降血压、抗氧化等作用。\n6. 常见方剂：\n   - 丹栀逍遥散：用于肝郁化火。\n   - 四物汤加丹皮：用于血热症。\n   - 牡丹皮散：清热凉血。\n7. 使用注意：脾胃虚寒、气血虚弱者慎用；孕妇应在医生指导下使用。'
    } else if (lowerInput.includes('盆栽') || lowerInput.includes('盆景')) {
      return '牡丹盆栽技巧：\n\n1. 盆器选择：选用透气性好的陶盆或紫砂盆，直径30-40厘米，深度25-30厘米，确保有足够的排水孔。\n2. 土壤配方：使用疏松肥沃、排水良好的土壤，可配制腐叶土3份、园土2份、河沙1份、腐熟有机肥1份的混合土。\n3. 栽种时间：北方地区以秋季(9-10月)为宜，南方地区春季(2-3月)更适合。\n4. 栽植方法：\n   - 植株选择：选择2-3年生、有2-3个芽的健壮植株。\n   - 栽植深度：根颈与盆土平齐或略低0.5-1厘米。\n   - 栽后管理：浇透水，置半阴处养护7-10天。\n5. 日常管理：\n   - 光照：生长期需充足光照，夏季需遮阳。\n   - 浇水：保持土壤湿润但不积水，冬季控制浇水。\n   - 施肥：春季萌芽前、花后、秋季各施一次腐熟有机肥。\n6. 越冬保护：北方地区冬季可移入冷室或用草绳包裹盆体保温。\n7. 常见问题：\n   - 不开花：光照不足、施肥不当或根系受损。\n   - 黄叶：可能是浇水过多或缺少养分。\n   - 花蕾干枯：温度变化大或光照强度突变。\n8. 观赏布置：可与山石、小型绿植搭配，制作精美盆景，室内观赏时间宜短，避免通风不良导致落叶。'
    } else {
      return '关于您提到的问题，我作为专业的牡丹知识顾问，需要告诉您牡丹作为中国的传统名花，有着丰富的文化底蕴和种植技术。牡丹有"国色天香"、"花中之王"的美誉，品种繁多，栽培历史悠久。\n\n您可以向我询问有关牡丹的以下方面：\n1. 各类牡丹品种的特点和欣赏要点\n2. 不同地区的牡丹栽培技术和经验\n3. 牡丹的历史文化和文学艺术表现\n4. 牡丹的药用价值和养生知识\n5. 牡丹盆栽和园林应用的专业建议\n\n请告诉我您想了解哪方面的牡丹知识，我会为您提供专业详细的解答。'
    }
  }

  // 生成回复（组合API调用和本地回复）
  static async generateResponse(userInput: string): Promise<string> {
    try {
      // 创建类型正确的消息数组
      const messages: MessageInterface[] = [{
        role: 'user',
        content: userInput
      } as MessageInterface];

      // 尝试调用Kimi API
      return await AIChatService.callKimiAPI(messages);
    } catch (error) {
      console.error('生成回复出错：', error)
      // 如果API调用失败，使用本地回复作为备用
      return AIChatService.getFallbackResponse(userInput)
    }
  }
}

// UI组件 - 聊天界面
@Component
export struct AIChat {
  @State inputText: string = ''
  @State chatHistory: ChatMessage[] = [
    new ChatMessage('AI', '您好！我是牡丹小精灵，很高兴为您提供关于牡丹花的咨询服务。您可以向我询问任何有关牡丹花的知识、养护方法或者欣赏指南。', new Date())
  ]
  @State isInputting: boolean = false
  @State isComponentActive: boolean = false

  // 保存控制器实例，以便在组件销毁时正确释放
  private scroller: Scroller = new Scroller()
  private textController: TextInputController = new TextInputController()
  private httpClient?: http.HttpRequest

  // 组件即将出现时调用
  aboutToAppear() {
    // 初始化组件状态
    this.isComponentActive = true
    console.info('AIChat组件已激活')
  }

  // 添加页面显示和隐藏的回调
  onPageShow() {
    console.info('AIChat页面显示')
    this.isComponentActive = true
  }

  onPageHide() {
    console.info('AIChat页面隐藏')
    this.isComponentActive = false
    // 如果有HTTP请求正在进行，取消它
    this.cancelPendingRequest()
  }

  // 添加生命周期方法
  aboutToDisappear() {
    // 清理工作，确保组件销毁时资源被正确释放
    this.isComponentActive = false
    this.cancelPendingRequest()
    console.info('AIChat组件已销毁')
  }

  // 取消待处理的HTTP请求
  private cancelPendingRequest() {
    if (this.httpClient) {
      try {
        this.httpClient.destroy()
        console.info('HTTP客户端已销毁')
      } catch (error) {
        console.error('销毁HTTP客户端失败:', error)
      }
      this.httpClient = undefined
    }
  }

  // 聊天气泡
  @Builder
  ChatBubble(message: ChatMessage) {
    Row() {
      if (message.sender === 'User') {
        // 用户消息靠右
        Blank()
        Column() {
          Text(message.content)
            .fontSize(16)
            .fontColor(Color.White)
            .padding(12)
            .backgroundColor('#317AFF')
            .borderRadius(8)
        }
        .alignItems(HorizontalAlign.End)
        .width('80%')
      } else {
        // AI消息靠左
        Column() {
          Text(message.content)
            .fontSize(16)
            .fontColor(Color.Black)
            .padding(12)
            .backgroundColor(Color.White)
            .borderRadius(8)
        }
        .alignItems(HorizontalAlign.Start)
        .width('80%')

        Blank()
      }
    }
    .width('100%')
    .margin({ top: 10, bottom: 10 })
  }

  // 头部标题栏
  @Builder
  HeaderBar() {
    Row() {
      Text('牡丹小精灵')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
    }
    .width('100%')
    .height(56)
    .backgroundColor('#FF7777')
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.Center)
  }

  // 输入区域
  @Builder
  InputArea() {
    Row() {
      TextInput({
        placeholder: '请输入您想咨询的问题...',
        text: this.inputText,
        controller: this.textController
      })
        .width('75%')
        .height(50)
        .fontSize(16)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .padding({ left: 10, right: 10 })
        .onChange((value: string) => {
          this.inputText = value;
        })

      Button('发送')
        .width('20%')
        .height(50)
        .fontSize(16)
        .fontColor(Color.White)
        .backgroundColor('#FF7777')
        .borderRadius(8)
        .margin({ left: 10 })
        .enabled(this.inputText.trim().length > 0)
        .onClick(() => {
          this.sendMessage();
        })
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#E0E0E0')
  }

  build() {
    Column() {
      // 头部标题栏
      this.HeaderBar()

      // 聊天历史记录
      Scroll(this.scroller) {
        Column() {
          ForEach(this.chatHistory, (item: ChatMessage, index: number) => {
            this.ChatBubble(item)
          }, (item: ChatMessage, index: number) => index.toString())
        }
        .width('100%')
        .padding(10)
      }
      .scrollBar(BarState.Auto)
      .scrollBarColor(Color.Gray)
      .scrollBarWidth(4)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')

      // 底部输入框
      this.InputArea()
    }
    .width('100%')
    .height('100%')
  }

  // 添加AI回复消息到聊天历史
  private addAIMessage(content: string): void {
    this.chatHistory.push(new ChatMessage('AI', content, new Date()))
    this.isInputting = false
    this.scrollToBottom()
  }

  // 滚动到底部
  private scrollToBottom(): void {
    this.scroller.scrollEdge(Edge.Bottom)
  }

  // 处理API错误
  private handleApiError(error: Error): void {
    console.error('获取AI回复失败:', error)
    // 显示错误消息
    promptAction.showToast({
      message: '抱歉，无法连接到AI服务，请稍后再试',
      duration: 3000
    })
    // 添加错误回复
    this.addAIMessage('抱歉，我暂时无法回答您的问题，请稍后再试。')
  }

  // 将聊天历史转换为API消息格式
  private convertChatHistoryToMessages(): MessageInterface[] {
    // 只取最近的几条消息，避免上下文过长
    const recentMessages: ChatMessage[] = this.chatHistory.slice(-8); // 保留最近8条消息

    // 使用显式类型声明，避免对象字面量问题
    const messages: MessageInterface[] = [];

    for (let msg of recentMessages) {
      const role: string = msg.sender === 'User' ? 'user' : 'assistant';
      messages.push({
        role: role,
        content: msg.content
      } as MessageInterface);
    }

    return messages;
  }

  // 发送消息
  async sendMessage() {
    if (!this.isComponentActive) {
      console.info('组件不活跃，忽略消息发送')
      return
    }

    if (this.inputText.trim().length === 0) {
      return;
    }

    // 如果有之前的未完成HTTP请求，取消它
    this.cancelPendingRequest()

    try {
      // 保存当前输入文本
      const currentText = this.inputText.trim();

      // 添加用户消息
      const userMessage = new ChatMessage('User', currentText, new Date());
      this.chatHistory.push(userMessage);

      // 清空输入框
      this.inputText = '';

      // 设置AI正在输入状态
      this.isInputting = true;

      // 滚动到底部
      this.scrollToBottom();

      // 防御性检查，确保聊天历史有效
      if (!this.chatHistory || this.chatHistory.length === 0) {
        throw new Error('聊天历史无效');
      }

      // 如果组件已不活跃，忽略接下来的API调用
      if (!this.isComponentActive) {
        console.info('组件在准备API调用期间变为不活跃，取消操作')
        return
      }

      // 创建新的HTTP客户端用于此次请求
      this.httpClient = http.createHttp();

      // 准备对话上下文消息
      const messages = this.convertChatHistoryToMessages();

      try {
        // 使用包装的API调用
        let aiResponse = '';
        if (this.httpClient && this.isComponentActive) {
          aiResponse = await AIChatService.callKimiAPI(messages);
        } else {
          throw new Error('HTTP客户端创建失败或组件不再活跃');
        }

        // 确保组件仍然活跃再添加回复
        if (this.isComponentActive) {
          // 添加AI回复
          this.addAIMessage(aiResponse || '抱歉，服务暂时不可用，请稍后再试。');
        } else {
          console.info('组件在API调用完成后已不活跃，忽略回复')
        }
      } catch (apiError) {
        console.error('API调用失败：', apiError);

        if (this.isComponentActive) {
          // 使用备用回复
          const fallbackResponse = AIChatService.getFallbackResponse(currentText);
          this.addAIMessage(fallbackResponse);
        }
      } finally {
        // 请求完成后清理HTTP客户端
        this.cancelPendingRequest()
      }
    } catch (error) {
      // 处理任何可能的错误
      console.error('发送消息过程出错：', error);
      this.isInputting = false;

      if (this.isComponentActive) {
        // 显示友好提示
        promptAction.showToast({
          message: '发送消息失败，请稍后再试',
          duration: 3000
        });
      }
    }
  }
}