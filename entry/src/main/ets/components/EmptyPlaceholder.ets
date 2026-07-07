/**
 * 空状态占位组件
 */
@Component
export struct EmptyPlaceholder {
  @Prop icon: string = '📭';
  @Prop title: string = '暂无内容';
  @Prop description: string = '';

  build() {
    Column() {
      Text(this.icon)
        .fontSize(48)
        .margin({ bottom: 12 })

      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#999')

      if (this.description) {
        Text(this.description)
          .fontSize(13)
          .fontColor('#BBB')
          .margin({ top: 6 })
          .textAlign(TextAlign.Center)
          .width('80%')
      }
    }
    .width('100%')
    .height('60%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
