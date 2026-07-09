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
      // 点赞 — 红色爱心
      Row() {
        Text(this.isLiked ? '❤️' : '🤍')
          .fontSize(20)
        Text(this.isLiked ? `${this.likeCount}` : `${this.likeCount}`)
          .fontSize(14)
          .fontColor(this.isLiked ? '#E8634A' : '#999')
          .fontWeight(this.isLiked ? FontWeight.Bold : FontWeight.Normal)
          .margin({ left: 4 })
      }
      .padding({ left: 14, right: 18, top: 10, bottom: 10 })
      .borderRadius(22)
      .backgroundColor(this.isLiked ? '#FFF0F0' : '#F5F5F5')
      .border({ width: this.isLiked ? 1 : 0, color: '#FFD0D0', style: BorderStyle.Solid })
      .margin({ right: 10 })
      .onClick(() => {
        if (this.onLikeClick) {
          this.onLikeClick();
        }
      })

      // 收藏 — 黄色星星
      Row() {
        Text(this.isCollected ? '⭐' : '☆')
          .fontSize(20)
        Text(this.isCollected ? '已收藏' : '收藏')
          .fontSize(14)
          .fontColor(this.isCollected ? '#F0AD4E' : '#999')
          .fontWeight(this.isCollected ? FontWeight.Bold : FontWeight.Normal)
          .margin({ left: 4 })
      }
      .padding({ left: 14, right: 18, top: 10, bottom: 10 })
      .borderRadius(22)
      .backgroundColor(this.isCollected ? '#FFF8E1' : '#F5F5F5')
      .border({ width: this.isCollected ? 1 : 0, color: '#FFE082', style: BorderStyle.Solid })
      .margin({ right: 10 })
      .onClick(() => {
        if (this.onCollectClick) {
          this.onCollectClick();
        }
      })

      // 评论
      Row() {
        Text('💬')
          .fontSize(20)
        Text(`${this.commentCount}`)
          .fontSize(14)
          .fontColor('#999')
          .margin({ left: 4 })
      }
      .padding({ left: 14, right: 18, top: 10, bottom: 10 })
      .borderRadius(22)
      .backgroundColor('#F5F5F5')
      .onClick(() => {
        if (this.onCommentClick) {
          this.onCommentClick();
        }
      })
    }
  }
}
