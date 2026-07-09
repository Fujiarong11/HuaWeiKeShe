/**
 * 回答卡片组件
 * 用于问题详情页中的回答列表展示
 */
import { AnswerModel } from '../model/AnswerModel';
import { UserInfoBar } from './UserInfoBar';

@Component
export struct AnswerCard {
  @ObjectLink answer: AnswerModel;
  @Prop isQuestionAuthor: boolean = false;
  onAccept?: (answerId: string) => void;
  onLike?: (answerId: string) => void;
  onComment?: (answerId: string) => void;
  onAuthorClick?: (userId: string) => void;

  build() {
    Column() {
      // 采纳标记
      if (this.answer.isAccepted) {
        Row() {
          Text('✓ 最佳答案')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#5CB85C')
            .borderRadius(4)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        }
        .width('100%')
        .margin({ bottom: 10 })
      }

      // 作者信息栏（双击进入主页）
      Row() {
        UserInfoBar({
          user: this.answer.author,
          avatarSize: 32,
          showReputation: true,
          showTime: this.answer.formattedTime,
          onUserClick: (userId: string) => {
            if (this.onAuthorClick) {
              this.onAuthorClick(userId);
            }
          }
        })

        // 采纳按钮（仅问题作者可见）
        if (this.isQuestionAuthor && !this.answer.isAccepted) {
          Text('采纳')
            .fontSize(12)
            .fontColor('#5CB85C')
            .fontWeight(FontWeight.Medium)
            .border({ width: 1, color: '#5CB85C', style: BorderStyle.Solid })
            .borderRadius(14)
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .onClick(() => {
              if (this.onAccept) {
                this.onAccept(this.answer.id);
              }
            })
        }
      }
      .width('100%')

      // 回答内容
      Text(this.answer.content)
        .fontSize(15)
        .fontColor('#333')
        .lineHeight(24)
        .width('100%')
        .margin({ top: 10 })
        .maxLines(8)

      // 互动按钮栏
      Row() {
        // 点赞
        Row() {
          Text(this.answer.isLiked ? '👍' : '👍')
            .fontSize(14)
          Text(`${this.answer.likeCount}`)
            .fontSize(13)
            .fontColor(this.answer.isLiked ? '#FF6B6B' : '#999')
            .margin({ left: 4 })
        }
        .onClick(() => {
          if (this.onLike) {
            this.onLike(this.answer.id);
          }
        })
        .margin({ right: 20 })

        // 评论
        Row() {
          Text('💬')
            .fontSize(14)
          Text(`${this.answer.commentCount}`)
            .fontSize(13)
            .fontColor('#999')
            .margin({ left: 4 })
        }
        .onClick(() => {
          if (this.onComment) {
            this.onComment(this.answer.id);
          }
        })

        Blank()

        // 分享
        Text('分享')
          .fontSize(12)
          .fontColor('#999')
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ top: 8, bottom: 8 })
  }
}
