/**
 * 互动按钮栏组件
 * 封装点赞、收藏、评论等互动按钮
 */
@Component
export struct InteractiveBar {
  @Prop likeCount: number = 0;
  @Prop commentCount: number = 0;
  @Prop isLiked: boolean = false;
  @Prop isCollected: boolean = false;
  onLikeClick?: () => void;
  onCollectClick?: () => void;
  onCommentClick?: () => void;

  build() {
    Row() {
      // 点赞
      Row() {
        Text(this.isLiked ? '❤️' : '🤍')
          .fontSize(18)
        Text(`${this.likeCount}`)
          .fontSize(14)
          .fontColor(this.isLiked ? '#FF6B6B' : '#999')
          .fontWeight(this.isLiked ? FontWeight.Medium : FontWeight.Normal)
          .margin({ left: 4 })
      }
      .padding({ left: 12, right: 16, top: 8, bottom: 8 })
      .borderRadius(20)
      .backgroundColor(this.isLiked ? '#FFF0F0' : '#F5F5F5')
      .margin({ right: 10 })
      .onClick(() => {
        if (this.onLikeClick) {
          this.onLikeClick();
        }
      })

      // 收藏
      Row() {
        Text(this.isCollected ? '⭐' : '☆')
          .fontSize(18)
        Text(this.isCollected ? '已收藏' : '收藏')
          .fontSize(14)
          .fontColor(this.isCollected ? '#FFB800' : '#999')
          .fontWeight(this.isCollected ? FontWeight.Medium : FontWeight.Normal)
          .margin({ left: 4 })
      }
      .padding({ left: 12, right: 16, top: 8, bottom: 8 })
      .borderRadius(20)
      .backgroundColor(this.isCollected ? '#FFF8E1' : '#F5F5F5')
      .margin({ right: 10 })
      .onClick(() => {
        if (this.onCollectClick) {
          this.onCollectClick();
        }
      })

      // 评论
      Row() {
        Text('💬')
          .fontSize(18)
        Text(`${this.commentCount}`)
          .fontSize(14)
          .fontColor('#999')
          .margin({ left: 4 })
      }
      .padding({ left: 12, right: 16, top: 8, bottom: 8 })
      .borderRadius(20)
      .backgroundColor('#F5F5F5')
      .onClick(() => {
        if (this.onCommentClick) {
          this.onCommentClick();
        }
      })
    }
  }
}
