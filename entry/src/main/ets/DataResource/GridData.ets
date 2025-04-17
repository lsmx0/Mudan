@Component
export struct Gridcomponent {
  @State currentFlower: Flower = new Flower($r('app.media.haihuang'), '', '')
  private flowerDialogController: CustomDialogController = new CustomDialogController({
    builder: this.flowerDialogBuilder,
    customStyle: true,
    alignment: DialogAlignment.Center
  })

  @Builder
  flowerDialogBuilder() {
    Column() {
      Text(this.currentFlower.text)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 15, bottom: 8 })
        .fontColor('#333333')

      Image(this.currentFlower.icon)
        .width('85%')
        .height(200)
        .objectFit(ImageFit.Cover)
        .borderRadius(10)
        .margin({ bottom: 12 })

      Text(this.currentFlower.recomendation)
        .fontSize(16)
        .padding(15)
        .textAlign(TextAlign.Center)
        .fontColor('#666666')
        .margin({ bottom: 10 })

      Button('关闭')
        .width(120)
        .height(40)
        .fontSize(16)
        .backgroundColor('#FF7777')
        .fontColor(Color.White)
        .borderRadius(20)
        .margin({ bottom: 15 })
        .onClick(() => {
          this.flowerDialogController.close()
        })
    }
    .width('90%')
    .borderRadius(15)
    .backgroundColor(Color.White)
    .padding({ top: 10, bottom: 10 })
  }

  build() {
    Grid() {
      ForEach(flowers, (flower: Flower) => {
        GridItem() {
          Column({ space: 5 }) {
            Image(flower.icon)
              .borderRadius(10)
              .width(150)
              .height(150)
            Button(flower.text)
              .width(100)
              .fontSize(15)
              .onClick(() => {
                this.currentFlower = flower
                this.flowerDialogController.open()
              }).backgroundColor(0x317aff)
          }
          .width('50%')
          .height(200)
        }
      })
    }
    .columnsTemplate('1fr 1fr')
  }
}

export class Flower {
  icon: Resource; //图片
  text: string;   //名称
  recomendation:string;//简介

  constructor(icon: Resource, text: string,recomendation:string) {
    this.icon = icon;
    this.text = text;
    this.recomendation=recomendation;
  }
}
export let flowers: Flower[] = [
  new Flower($r('app.media.haihuang'),'海黄','海黄，海黄牡丹多年生，植株较高，株形半开张，茎青绿色，小型长叶，叶边红，有锯齿，黄绿色泛红。花蔷薇型，黄色，外瓣大，向内渐小，排列紧密，雄蕊多，柱头黄，房衣浅包。'),
  new Flower($r('app.media.liantianjin'), '镰田锦','镰田锦，是一种毛茛科、芍药属植物。形态特征抗逆、优质；菊花型；花浅粉色；花瓣形状相似；排列整齐；层次分明；自外向内逐渐变小。生长环境亚热带；温带。分布范围山东省。'),
  new Flower($r('app.media.baiwangshizi'),'白王狮子','白王狮子，花白色，菊花型。花梗硬，花态直上。晚开品种。株型直立，中型长叶，叶尖，稍黄绿，稍有红晕，叶柄上凹紫红色，花无莲鹤质感厚，房衣、柱头、花丝、乳黄色，花药黄色，花期晚于莲鹤，花药长。'),
  new Flower($r('app.media.fangji'),'芳纪','芳纪，从日本引进，花色纯正，在红色系牡丹中，颜色最为艳丽，饱和度也比较高，花朵的形态呈荷花型，而且香味也比较浓郁，花朵紧密，开花后植株直立向上，不藏叶也不垂头。'),
  new Flower($r('app.media.huajing'),'花競','花競，它是日本品种，菊花型。形态特征花蕾圆形。花粉红色，花径23cm×9cm。花瓣多轮，排列整齐，雌雄蕊正常，房衣、柱头均为白色。花梗长，花朵直上。花期中。植株高大，直立。'),
  new Flower($r('app.media.zhaozi'),'赵紫','赵紫，它是一种毛茛科、芍药属植物。形态特征抗逆、优质；皇冠型花蕾扁圆形；花紫色；外瓣2轮；形大；质硬；基部有紫色晕。生长环境亚热带；温带。分布范围山东省。'),
  new Flower($r('app.media.changshoule'),'长寿乐','长寿乐，是一种毛茛科、芍药属植物。形态特征抗病、抗虫、抗逆、优质；花紫色略带蓝色；蔷薇型；花瓣质硬；宽大平展；基部墨紫色斑雌雄蕊正常；房衣紫红色。生长环境亚热带。'),
  new Flower($r('app.media.zhongguolong'),'中国龙','中国龙，引进的稀有品种，花朵外瓣较大、内瓣较小，基部还有紫黑色的斑，在深红色的花瓣间，黄色的花蕊镶嵌其中，它的花朵并未仰面朝天，而是侧身绽放。'),
  new Flower($r('app.media.xinqifushen'),'新七福神','新七福神是一种毛茛科、芍药属植物。七福神是日本神话中主持人间福德的七位神。由于这种牡丹的枝条较多，且高低错落，花朵凸显富贵之态，便取名为"新七福神。"'),
  new Flower($r('app.media.xvgang'),'旭港','旭港，牡丹花品种。花火红色，蔷薇型。花色为大红色，花大色艳，但花期较晚，容易养活，适合家庭及新手种植。"旭港"牡丹：属于日本牡丹，花期晚，花火红色，花朵蔷薇型，花朵侧开，花瓣多轮，较圆整，雌雄蕊正常。'),
  new Flower($r('app.media.lianhe'),'莲鹤','莲鹤牡丹，引进品种。花的颜色是白色的，花瓣宽大圆整，柱头、房衣、花丝均为白色。株型中高，直立晚花品种。看上去洁白无瑕，干净神圣，芍药属植物。名字的寓意也很吉利，有年年益寿的含义。'),
  new Flower($r('app.media.daodachen'),'岛大臣','岛大臣, 国外牡丹交流品种，菊花型，花紫红色，花瓣6轮以上，花瓣形状相似，层次分明，自外向内逐渐变小，雄蕊正常或减少变小，中花，中度喜光稍耐半阴，喜温和，具有一定耐寒性，忌酷热，适宜高燥，惧湿涝。'),
  new Flower($r('app.media.huawang'),'花王','花王牡丹属于日本牡丹，花期中晚，花紫红色，花朵蔷薇型，花茎粗，花朵直上，花瓣排列紧密，由外至内逐轮缩小，雄蕊稍有瓣化，雌蕊变小。叶片大型长叶，生长势强，分枝力强，成花率高，不耐早春寒，抗病性弱。'),
  new Flower($r('app.media.baqiandaichun'),'八千代椿','八千代椿，菊花型。花胭脂红色。花瓣肥厚，鲜艳，硕大，色彩艳丽。雄蕊多，花丝外围短，近花心处长，黑紫色，花蕾长圆尖形。经多年的培育，如今不但在洛阳等地大量繁殖，在其他地区也广泛栽植。'),
  new Flower($r('app.media.hanyingshizi'),'寒樱狮子','寒樱狮子，荷花型，花瓣基部粉色，边缘白色，雄蕊多数，花内外瓣大且均匀。')
];


