import { Gridcomponent } from '../DataResource/GridData'
import { Swipercomponent } from '../DataResource/SwiperData'
import { AIChat } from '../DataResource/AIChat'
import { ImageRecognition } from '../DataResource/ImageRecognition'

@Entry
@Component
struct Index {
  @State currentIndex: number = 0

  @Builder
  buildBar(index: number, title: string) {
    Column() {
      Image($r('app.media.Mudan'))
        .width(40)
        .fillColor(index === this.currentIndex ? Color.Pink : Color.White)
      Text(title)
        .fontSize(15)
        .fontColor(index === this.currentIndex ? Color.Pink : Color.White)
    }
    .border({ color: Color.Black, width: { top: 1 } })
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#87CEFA')
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        Column() {
          if (this.currentIndex === 0) {
            Swipercomponent()
              .width('100%')
            Gridcomponent()
              .backgroundColor('#87CEFA')
              .width('100%')
              .height(500)
          }
        }
      }.tabBar(this.buildBar(0, '首页'))

      TabContent() {
        Column() {
          if (this.currentIndex === 1) {
            ImageRecognition()
              .width('100%')
              .height('100%')
          }
        }
      }.tabBar(this.buildBar(1, '识别'))

      TabContent() {
        Column() {
          if (this.currentIndex === 2) {
            AIChat()
              .width('100%')
              .height('100%')
          }
        }
      }.tabBar(this.buildBar(2, '慧灵牡丹'))
    }
    .onChange(index => {
      this.currentIndex = index
    })
    .scrollable(false)
  }
}
