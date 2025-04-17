@Component
export struct Swipercomponent{
  private imageArray: Resource[] = [
    $r('app.media.shouye1'),
    $r('app.media.shouye2'),
    $r('app.media.shouye3'),
    $r('app.media.shouye4')
  ];

  build() {
    Column(){
      Swiper() {
        ForEach(this.imageArray, (img: Resource, index: number) => {
          Image(img)
            .width('100%')
            .objectFit(ImageFit.Cover)
        }, (img: Resource, index: number) => index.toString())
      }
      .autoPlay(true)
      .height('25%')
      .loop(true)
      .interval(3000)
      .duration(1000)
      .indicator(true)

      Text('-----牡丹花介绍-----')
        .fontSize(25)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width('100%')
        .height(40)
        .backgroundColor('#87CEFA')
    }
  }
}