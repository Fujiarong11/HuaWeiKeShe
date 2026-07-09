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
      // 采纳标记（已采纳时顶部绿色提示可点击取消）
      if (this.answer.isAccepted) {
        Row() {
          Text('✓ 已采纳为最佳答案')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#5CB85C')
            .borderRadius(6)
            .padding({ left: 12, right: 12, top: 5, bottom: 5 })
          Blank()
        }
        .width('100%')
        .margin({ bottom: 10 })
      }

      // 作者信息栏
      Row() {
        UserInfoBar({
          user: this.answer.author,
          avatarSize: 32,
          showReputation: true,
          showTime: this.answer.formattedTime
        })
        Blank()
      }
      .width('100%')
      .onClick(() => {
        if (this.onAuthorClick) {
          this.onAuthorClick(this.answer.author.id);
        }
      })

      // 采纳按钮（仅问题作者可见，未采纳灰边框 / 已采纳绿实心，均可点击切换）
      if (this.isQuestionAuthor) {
        Row() {
          Text(this.answer.isAccepted ? '✓' : '✓')
            .fontSize(13)
            .fontColor(this.answer.isAccepted ? Color.White : '#5CB85C')
            .fontWeight(FontWeight.Bold)
          Text(this.answer.isAccepted ? ' 已采纳' : ' 采纳为最佳答案')
            .fontSize(12)
            .fontColor(this.answer.isAccepted ? Color.White : '#5CB85C')
            .fontWeight(FontWeight.Medium)
        }
        .backgroundColor(this.answer.isAccepted ? '#5CB85C' : 'transparent')
        .border({
          width: 1,
          color: '#5CB85C',
          style: BorderStyle.Solid
        })
        .borderRadius(16)
        .height(32)
        .padding({ left: 14, right: 14 })
        .shadow(this.answer.isAccepted
          ? { radius: 4, color: 'rgba(92,184,92,0.3)', offsetY: 2 }
          : { radius: 0, color: 'transparent', offsetY: 0 })
        .alignSelf(ItemAlign.Start)
        .margin({ top: 8 })
        .onClick(() => {
          if (this.onAccept) {
            this.onAccept(this.answer.id);
          }
        })
      }

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
          Text(this.answer.isLiked ? '❤️' : '🤍')
            .fontSize(16)
          Text(`${this.answer.likeCount}`)
            .fontSize(13)
            .fontColor(this.answer.isLiked ? '#FF6B6B' : '#999')
            .fontWeight(this.answer.isLiked ? FontWeight.Medium : FontWeight.Normal)
            .margin({ left: 4 })
        }
        .padding({ left: 8, right: 12, top: 6, bottom: 6 })
        .borderRadius(16)
        .backgroundColor(this.answer.isLiked ? '#FFF0F0' : '#F5F5F5')
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
