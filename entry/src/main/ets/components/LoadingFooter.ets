/**
 * 加载更多底部组件
 */
@Component
export struct LoadingFooter {
  @Prop isLoading: boolean = false;
  @Prop hasMore: boolean = true;
  @Prop text: string = '';

  build() {
    Row() {
      if (this.isLoading) {
        LoadingProgress()
          .width(18)
          .height(18)
          .color('#4A90D9')
        Text('正在加载...')
          .fontSize(13)
          .fontColor('#999')
          .margin({ left: 8 })
      } else if (!this.hasMore) {
        Text(this.text || '— 没有更多了 —')
          .fontSize(13)
          .fontColor('#CCC')
      }
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
  }
}
