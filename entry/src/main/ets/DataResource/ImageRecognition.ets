import http from '@ohos.net.http';
import picker from '@ohos.file.picker';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import image from '@ohos.multimedia.image';
import mediaLibrary from '@ohos.multimedia.mediaLibrary';
import fs from '@ohos.file.fs';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import fileIo from '@ohos.file.fs';
import { flowers, Flower } from './GridData';

interface Category {
  id: number;
  name: string;
  score: number;
}

// 添加结果对象的接口定义
interface ResultData {
  categories: Category[];
  image: string;
}

interface RecognitionResult {
  logId: string;
  errorCode: number;
  errorMsg: string;
  result: ResultData;
}

interface RecognitionRequest {
  image: string;
}

interface ButtonOption {
  text: string;
  color: string;
}

interface HttpRequestOptions {
  method: http.RequestMethod;
  header: Record<string, string>;
  extraData: string;
  expectDataType: http.HttpDataType;
}

interface DialogResult {
  index: number;
}

// 添加媒体库查询选项接口定义
interface MyMediaFetchOptions {
  selections: string;
  selectionArgs: string[];
}

@Component
export struct ImageRecognition {
  @State private imageUri: string = '';
  @State private isLoading: boolean = false;
  @State private recognitionResult: string = '';
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  
  // API相关配置
  private readonly API_URL: string = "";
  private readonly TOKEN: string = "";

  // 选择图片
  async selectImage() {
    // 请求必要的权限
    await this.requestPermissions();
    
    try {
      // 提供两种选择方式
      promptAction.showDialog({
        title: '选择操作',
        message: '请选择使用测试图片还是从相册选择图片？',
        buttons: [
          {
            text: '测试图片',
            color: '#87CEFA'
          },
          {
            text: '从相册选择',
            color: '#87CEFA'
          }
        ]
      }).then((value: DialogResult) => {
        if (value.index === 0) {
          // 使用测试图片
          this.testWithSimpleRequest();
        } else {
          // 从相册选择
          this.selectFromGallery();
        }
      }).catch((err: Error) => {
        console.error('弹窗显示失败:', err);
      });
    } catch (err) {
      console.error('选择图片失败，错误详情:', err);
      promptAction.showToast({
        message: '选择图片失败',
        duration: 2000
      });
    }
  }

  // 请求必要的权限
  private async requestPermissions() {
    try {
      let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      await atManager.requestPermissionsFromUser(context, [
        "ohos.permission.WRITE_MEDIA",
        "ohos.permission.READ_MEDIA",
      ], (err, data) => {
        if (err) {
          console.log(`请求权限失败: ${JSON.stringify(err)}`);
        } else {
          console.info('权限请求结果:', JSON.stringify(data));
          console.info('权限列表:', data.permissions);
          console.info('授权结果:', data.authResults); // 如果是0则有权限
        }
      });
    } catch (err) {
      console.error('请求权限时发生错误:', err);
    }
  }

  // 从相册选择图片
  private async selectFromGallery() {
    try {
      const photoPicker = new picker.PhotoViewPicker();
      const result = await photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE
      });

      if (result && result.photoUris && result.photoUris.length > 0) {
        const fileUri = result.photoUris[0];
        this.imageUri = fileUri;
        console.info('选择的图片URI:', fileUri);
        
        // 复制文件到应用缓存目录
        try {
          // 获取缓存目录
          const cacheDir = this.context.cacheDir;
          console.log('缓存目录:', cacheDir);
          
          // 创建唯一文件名
          const fileName = Date.now() + '.jpg';
          const targetPath = cacheDir + "/" + fileName;
          
          // 复制文件
          let file = fs.openSync(fileUri);
          fs.copyFileSync(file.fd, targetPath);
          fs.closeSync(file);
          
          console.info('文件已复制到:', targetPath);
          
          // 更新图片URI以使用复制后的文件
          this.imageUri = `internal://cache/${fileName}`;
          console.info('更新后的图片URI:', this.imageUri);
          
          // 开始识别
          this.recognizeImage();
        } catch (copyErr) {
          console.error('复制文件失败:', copyErr);
          promptAction.showToast({
            message: '处理图片文件失败',
            duration: 2000
          });
          this.imageUri = '';
        }
      } else {
        console.error('未选择图片');
        promptAction.showToast({
          message: '请选择一张图片',
          duration: 2000
        });
      }
    } catch (err) {
      console.error('从相册选择图片失败:', err);
      promptAction.showToast({
        message: '选择图片失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  // 使用简单的请求进行测试
  private async testWithSimpleRequest() {
    try {
      this.isLoading = true;
      console.info('开始发送简单请求测试');
      
      // 使用硬编码的简短Base64图片数据（一个小图像）
      const hardcodedBase64 = '/9j/4AAQSkZJRgABAQEAYABgAAD//gA7Q1JFQVRPUjogZ2QtanBlZyB2MS4wICh1c2luZyBJSkcgSlBFRyB2NjIpLCBxdWFsaXR5ID0gOTAK/9sAQwADAgIDAgIDAwMDBAMDBAUIBQUEBAUKBwcGCAwKDAwLCgsLDQ4SEA0OEQ4LCxAWEBETFBUVFQwPFxgWFBgSFBUU/9sAQwEDBAQFBAUJBQUJFA0LDRQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQU/8AAEQgAMgAyAwEiAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vHy8/T1 9vf4+fr/2gAMAwEAAhEDEQA/APy/ooor9MPmgooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA//2Q==';
      
      console.info('使用硬编码的Base64图片数据，长度:', hardcodedBase64.length);
      
      // 发送到识别API
      const headers: Record<string, string> = {
        "Authorization": "token " + this.TOKEN,
        "Content-Type": "application/json"
      };
      
      const payload: RecognitionRequest = {
        image: hardcodedBase64
      };
      
      console.info('发送识别请求');
      const httpClient = http.createHttp();
      const recognitionResponse = await httpClient.request(
        this.API_URL, 
        {
          method: http.RequestMethod.POST,
          header: headers,
          extraData: JSON.stringify(payload),
          expectDataType: http.HttpDataType.STRING
        }
      );
      
      console.info('识别请求返回, 状态码:', recognitionResponse.responseCode);
      
      // 显示结果
      this.recognitionResult = "状态码: " + recognitionResponse.responseCode + "\n\n响应内容:\n" + 
                             (recognitionResponse.result || '无响应内容').toString().substring(0, 1000);
                            
      promptAction.showDialog({
        title: '识别测试结果',
        message: this.recognitionResult,
        buttons: [{ text: '确定', color: '#000000' }]
      });
      
    } catch (err) {
      console.error('测试失败:', err);
      promptAction.showToast({
        message: '测试失败: ' + String(err),
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  // 将图片转换为Base64
  private async imageToBase64(uri: string): Promise<string> {
    try {
      console.info('开始获取图片文件内容，URI:', uri);
      
      // 如果是internal://cache/格式的URI，直接读取
      if (uri.startsWith('internal://cache/')) {
        try {
          const fileName = uri.substring('internal://cache/'.length);
          const filePath = this.context.cacheDir + '/' + fileName;
          console.info('读取缓存文件:', filePath);
          
          // 读取文件
          let file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
          let stat = fileIo.statSync(filePath);
          let buf = new ArrayBuffer(stat.size);
          let readLen = fileIo.readSync(file.fd, buf);
          fileIo.closeSync(file);
          
          console.info('文件读取完成, 大小:', readLen);
          
          // 直接将图片数据转为Base64
          const uint8Array = new Uint8Array(buf);
          // 创建一个新的ArrayBuffer
          const arrayBuffer: ArrayBuffer = buf.slice(0);
          const base64String = this.arrayBufferToBase64(arrayBuffer);
          console.info('缓存文件转Base64完成，长度:', base64String.length);
          
          return base64String;
        } catch (fileErr) {
          console.error('读取缓存文件失败:', fileErr);
        }
      }
      
      // 从媒体库获取图片（媒体库方式是首选）
      try {
        console.info('尝试使用媒体库API获取图片');
        
        // 获取媒体库实例
        const media = mediaLibrary.getMediaLibrary(this.context);
        
        // 首先尝试直接使用URI查询
        let fetchOptions: MyMediaFetchOptions = {
          selections: 'uri = ?',
          selectionArgs: [uri],
        };
        let fetchResult = await media.getFileAssets(fetchOptions);
        console.info('使用URI查询结果数量:', fetchResult.getCount());
        
        // 如果找不到，尝试从URI中获取ID
        if (fetchResult.getCount() === 0) {
          // datashare://device_ID/media/image/100/101/123
          const parts = uri.split('/');
          const fileId = parts[parts.length - 1];
          console.info('尝试使用ID查询:', fileId);
          
          fetchOptions = {
            selections: 'id = ?',
            selectionArgs: [fileId],
          };
          
          fetchResult.close();
          fetchResult = await media.getFileAssets(fetchOptions);
          console.info('使用ID查询结果数量:', fetchResult.getCount());
          
          // 如果还是找不到，尝试获取所有图片
          if (fetchResult.getCount() === 0) {
            fetchOptions = {
              selections: 'media_type = ?',
              selectionArgs: ['image'],
            };
            
            fetchResult.close();
            fetchResult = await media.getFileAssets(fetchOptions);
            console.info('获取所有图片数量:', fetchResult.getCount());
          }
        }
        
        // 检查查询结果
        if (fetchResult.getCount() > 0) {
          const asset = await fetchResult.getFirstObject();
          console.info('获取到媒体资源, ID:', asset.id, '名称:', asset.displayName);
          
          try {
            // 获取文件描述符
            const fd = await asset.open('r');
            console.info('文件描述符获取成功:', fd);
            
            try {
              // 使用文件描述符创建图片源
              const imageSource = image.createImageSource(fd);
              if (imageSource === null || imageSource === undefined) {
                console.error('使用文件描述符创建图片源失败');
                await asset.close(fd);
                await fetchResult.close();
                return '';
              }
              
              console.info('图片源创建成功');
              
              // 获取图片信息
              const imageInfo = await imageSource.getImageInfo();
              console.info('图片信息获取成功, 宽度:', imageInfo.size.width, '高度:', imageInfo.size.height);
              
              // 创建像素图
              const pixelMap = await imageSource.createPixelMap();
              console.info('像素图创建成功');
              
              // 将像素图转换为Buffer
              const imageBuffer = await pixelMap.getPixelBytesNumber();
              const arrayBuffer = new ArrayBuffer(imageBuffer);
              await pixelMap.readPixelsToBuffer(arrayBuffer);
              
              // 手动Base64编码
              const base64ArrayBuffer: ArrayBuffer = arrayBuffer.slice(0);
              const base64String = this.arrayBufferToBase64(base64ArrayBuffer);
              console.info('Base64编码完成，长度:', base64String.length);
              
              // 释放资源
              await pixelMap.release();
              await imageSource.release();
              await asset.close(fd);
              await fetchResult.close();
              
              return base64String;
            } catch (imageErr) {
              console.error('图像处理失败:', imageErr);
              await asset.close(fd);
            }
          } catch (fdErr) {
            console.error('获取文件描述符失败:', fdErr);
          }
          
          await fetchResult.close();
        } else {
          console.error('未在媒体库中找到图片');
        }
      } catch (mediaErr) {
        console.error('媒体库操作失败:', mediaErr);
      }
      
      // 直接尝试使用图像API（备选方案）
      console.info('尝试使用直接图像API处理图片');
      
      try {
        // 创建图片源
        const imageSource = image.createImageSource(uri);
        if (imageSource === null || imageSource === undefined) {
          console.error('创建图片源失败，URI无效');
          promptAction.showToast({
            message: '无法读取图片，请重新选择',
            duration: 2000
          });
          return '';
        }
        
        console.info('图片源创建成功');
        
        // 获取图片信息
        const imageInfo = await imageSource.getImageInfo();
        console.info('获取到图片信息, 宽度:', imageInfo.size.width, '高度:', imageInfo.size.height);
        
        // 创建像素图
        const pixelMap = await imageSource.createPixelMap();
        console.info('像素图创建成功');
        
        // 将像素图转换为Buffer
        const imageBuffer = await pixelMap.getPixelBytesNumber();
        const arrayBuffer = new ArrayBuffer(imageBuffer);
        await pixelMap.readPixelsToBuffer(arrayBuffer);
        console.info('读取像素数据完成，缓冲区大小:', arrayBuffer.byteLength);
        
        // 手动Base64编码
        const base64ArrayBuffer: ArrayBuffer = arrayBuffer.slice(0);
        const base64String = this.arrayBufferToBase64(base64ArrayBuffer);
        console.info('Base64编码完成，长度:', base64String.length);
        
        // 释放资源
        await pixelMap.release();
        await imageSource.release();
        
        return base64String;
      } catch (imageErr) {
        console.error('直接图像处理失败:', imageErr);
        promptAction.showToast({
          message: '图片处理失败，请重新选择',
          duration: 2000
        });
        return '';
      }
    } catch (err) {
      console.error('图片转Base64失败:', err);
      promptAction.showToast({
        message: '图片处理失败',
        duration: 2000
      });
      return '';
    }
  }
  
  // 手动Base64编码
  private arrayBufferToBase64(arrayBuffer: ArrayBuffer): string {
    const bytes = new Uint8Array(arrayBuffer);
    const base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let base64 = '';
    
    // 每3个字节转换为4个Base64字符
    for (let i = 0; i < bytes.length; i += 3) {
      // 获取3个字节
      const byte1 = bytes[i];
      const byte2 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      const byte3 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      
      // 将3个字节转换为4个Base64索引
      const index1 = byte1 >> 2;
      const index2 = ((byte1 & 0x03) << 4) | (byte2 >> 4);
      const index3 = ((byte2 & 0x0F) << 2) | (byte3 >> 6);
      const index4 = byte3 & 0x3F;
      
      // 添加Base64字符
      base64 += base64Chars.charAt(index1);
      base64 += base64Chars.charAt(index2);
      base64 += i + 1 < bytes.length ? base64Chars.charAt(index3) : '=';
      base64 += i + 2 < bytes.length ? base64Chars.charAt(index4) : '=';
    }
    
    return base64;
  }

  // 识别图片
  async recognizeImage() {
    if (!this.imageUri) return;

    this.isLoading = true;
    try {
      console.info('开始识别图片，图片URI:', this.imageUri);
      
      // 获取图片的Base64编码
      const imageBase64 = await this.imageToBase64(this.imageUri);
      if (!imageBase64) {
        console.error('Base64编码失败');
        return;
      }
      
      console.info('准备发送HTTP请求');
      
      // 设置请求头部
      const headers: Record<string, string> = {
        "Authorization": "token " + this.TOKEN,
        "Content-Type": "application/json"
      };
      
      // 设置请求体
      const payload: RecognitionRequest = {
        image: imageBase64
      };
      
      // 发送HTTP请求
      const httpRequest = http.createHttp();
      const options: HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(payload),
        expectDataType: http.HttpDataType.STRING
      };
      
      const response = await httpRequest.request(this.API_URL, options);
      console.info('HTTP响应状态码:', response.responseCode);
      
      // 删除调试信息弹窗，只在控制台输出调试信息
      this.recognitionResult = "状态码: " + response.responseCode + "\n\n响应内容:\n" + (response.result || '无响应内容');
      console.info('API响应内容:', this.recognitionResult);

      // 处理响应结果
      if (response.responseCode === 200) {
        try {
          // 解析JSON结果
          const apiResponse: RecognitionResult = JSON.parse(response.result as string);
          console.info('解析后的识别结果:', JSON.stringify(apiResponse));
          
          // 检查是否有错误
          if (apiResponse.errorCode === 0 && apiResponse.result && apiResponse.result.categories && apiResponse.result.categories.length > 0) {
            // 获取第一个识别结果
            const category = apiResponse.result.categories[0];
            
            // 提取花名（去掉编号）
            const flowerName = this.extractFlowerName(category.name);
            console.info('提取的花名:', flowerName);
            
            // 查找匹配的花信息
            const matchedFlower = this.findFlowerByName(flowerName);
            
            // 准备显示结果
            const confirmButton: ButtonOption = { text: '确定', color: '#000000' };
            
            if (matchedFlower) {
              // 找到匹配的花信息
              console.info('匹配到花信息:', matchedFlower.text);
              promptAction.showDialog({
                title: '识别结果',
                message: `识别结果：${flowerName}\n置信度：${(category.score * 100).toFixed(2)}%\n\n介绍：${matchedFlower.recomendation}`,
                buttons: [confirmButton]
              });
            } else {
              // 未找到匹配的花信息，只显示识别结果
              console.info('未找到匹配的花信息');
              promptAction.showDialog({
                title: '识别结果',
                message: `识别结果：${flowerName}\n置信度：${(category.score * 100).toFixed(2)}%\n\n未找到花的详细介绍信息`,
                buttons: [confirmButton]
              });
            }
          } else {
            // 处理没有结果的情况
            console.error('识别结果为空或格式错误', apiResponse);
            console.info('原始响应数据:', response.result);
            const confirmButton: ButtonOption = { text: '确定', color: '#000000' };
            promptAction.showDialog({
              title: '识别结果',
              message: '未能识别出结果或返回数据格式错误',
              buttons: [confirmButton]
            });
          }
        } catch (parseErr) {
          // 处理JSON解析错误
          console.error('JSON解析失败:', parseErr, '原始数据:', response.result);
          promptAction.showToast({
            message: 'JSON解析失败: ' + String(parseErr),
            duration: 3000
          });
        }
      } else {
        promptAction.showToast({
          message: '服务器响应错误',
          duration: 2000
        });
      }
    } catch (err) {
      console.error('识别失败:', err);
      promptAction.showToast({
        message: '识别失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  // 从花名中提取实际名称（去掉编号部分）
  private extractFlowerName(fullName: string): string {
    // 假设格式为"13 长寿乐"，提取空格后的部分
    const parts = fullName.split(' ');
    if (parts.length > 1) {
      return parts.slice(1).join(' '); // 返回空格后的所有内容
    }
    return fullName; // 如果没有空格，返回原始名称
  }

  // 根据花名查找匹配的花信息
  private findFlowerByName(flowerName: string): Flower | null {
    // 遍历flowers数组查找匹配的花
    for (const flower of flowers) {
      if (flower.text === flowerName) {
        return flower;
      }
    }
    return null; // 未找到匹配的花
  }

  build() {
    Stack() {
      // 背景图片
      Image($r('app.media.shibiebg'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // 内容区域
      Column() {
        if (this.imageUri) {
          Image(this.imageUri)
            .width(300)
            .height(300)
            .borderRadius(20)
            .margin({ bottom: 30 })
            .objectFit(ImageFit.Cover)
        }

        Button('选择图片')
          .onClick(() => this.selectImage())
          .width(200)
          .height(50)
          .backgroundColor('#87CEFA')
          .borderRadius(25)
          .fontSize(18)
          .fontColor(Color.White)
          .margin({ top: 20 })
          .enabled(!this.isLoading)

        if (this.isLoading) {
          LoadingProgress()
            .width(50)
            .height(50)
            .margin({ top: 20 })
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .padding(20)
    }
    .width('100%')
    .height('100%')
  }
}