/**
 * 话题卡片组件
 * 用于话题广场 Grid 展示
 */
import { TopicModel } from '../model/TopicModel';

@Component
export struct TopicCard {
  @ObjectLink topic: TopicModel;
  onCardClick?: () => void;
  onFollowToggle?: () => void;

  build() {
    Column() {
      // 图标
      Text(this.topic.icon || '📌')
        .fontSize(28)
        .width(48)
        .height(48)
        .borderRadius(12)
        .backgroundColor(this.hexToRgba(this.topic.color || '#999', 0.15))
        .textAlign(TextAlign.Center)

      // 名称
      Text(this.topic.name)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A1A')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: 8 })

      // 描述
      Text(this.topic.description)
        .fontSize(11)
        .fontColor('#999')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: 2 })

      // 统计 + 关注按钮
      Row() {
        Text(`${this.topic.followerCount} 关注`)
          .fontSize(10)
          .fontColor('#BBB')
          .layoutWeight(1)

        Text(this.topic.isFollowed ? '已关注' : '+ 关注')
          .fontSize(11)
          .fontColor(this.topic.isFollowed ? '#999' : '#4A90D9')
          .fontWeight(FontWeight.Medium)
          .border({
            width: 1,
            color: this.topic.isFollowed ? '#DDD' : '#4A90D9',
            style: BorderStyle.Solid
          })
          .borderRadius(10)
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .onClick(() => {
            if (this.onFollowToggle) {
              this.onFollowToggle();
            }
          })
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .onClick(() => {
      if (this.onCardClick) {
        this.onCardClick();
      }
    })
  }

  private hexToRgba(hex: string, alpha: number): string {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }
}
