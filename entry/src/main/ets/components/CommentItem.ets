/**
 * 评论条目组件
 */
import { CommentModel } from '../model/CommentModel';
import { UserInfoBar } from './UserInfoBar';
import { router } from '@kit.ArkUI';

@Component
export struct CommentItem {
  @ObjectLink comment: CommentModel;
  onLike?: (commentId: string) => void;
  onAuthorClick?: (userId: string) => void;

  build() {
    Row() {
      // 头像
      Text(this.comment.author.name ? this.comment.author.name.charAt(0) : '?')
        .fontSize(14)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor(this.getAvatarColor(this.comment.author.name))
        .textAlign(TextAlign.Center)
        .alignSelf(ItemAlign.Start)
        .onClick(() => {
          if (this.onAuthorClick && this.comment.author.id) {
            this.onAuthorClick(this.comment.author.id);
          }
        })

      Column() {
        // 用户名 + 时间
        Row() {
          Text(this.comment.author.name || '匿名')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#4A90D9')
            .onClick(() => {
              if (this.onAuthorClick && this.comment.author.id) {
                this.onAuthorClick(this.comment.author.id);
              }
            })

          if (this.comment.replyTo) {
            Text(' 回复 ')
              .fontSize(12)
              .fontColor('#CCC')
            Text(this.comment.replyTo.name || '')
              .fontSize(13)
              .fontColor('#4A90D9')
          }

          Blank()

          Row() {
            Text(this.comment.formattedTime)
              .fontSize(11)
              .fontColor('#BBB')

            Text('  ')
              .fontSize(11)

            Row() {
              Text('👍')
                .fontSize(12)
              Text(` ${this.comment.likeCount}`)
                .fontSize(12)
                .fontColor(this.comment.isLiked ? '#FF6B6B' : '#BBB')
            }
            .onClick(() => {
              if (this.onLike) {
                this.onLike(this.comment.id);
              }
            })
          }
        }
        .width('100%')

        // 评论内容
        Text(this.comment.content)
          .fontSize(14)
          .fontColor('#333')
          .lineHeight(20)
          .width('100%')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Top)
  }

  private getAvatarColor(name: string): string {
    const colors = ['#4A90D9', '#E8634A', '#5CB85C', '#F0AD4E', '#9B59B6',
      '#1ABC9C', '#E91E63', '#FF9800', '#3F51B5', '#FF5722'];
    if (!name) { return colors[0]; }
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = name.charCodeAt(i) + ((hash << 5) - hash);
    }
    return colors[Math.abs(hash) % colors.length];
  }
}
