/**
 * 问题卡片组件
 * 用于首页列表、搜索结果、话题详情页中的问题展示
 */
import { QuestionModel } from '../model/QuestionModel';
import { UserInfoBar } from './UserInfoBar';
import { getStore } from '../mock/MockData';
import { router } from '@kit.ArkUI';

@Component
export struct QuestionCard {
  @ObjectLink question: QuestionModel;
  @Prop showTopicTags: boolean = true;
  onCardClick?: () => void;
  onAuthorClick?: (userId: string) => void;

  build() {
    Column() {
      // 问题标题
      Text(this.question.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A1A')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(22)
        .width('100%')

      // 话题标签
      if (this.showTopicTags && this.question.topicIds.length > 0) {
        Row() {
          Scroll() {
            Row() {
              ForEach(this.getTopicChips(), (chip: TopicChip) => {
                Text(chip.name)
                  .fontSize(11)
                  .fontColor(chip.color)
                  .backgroundColor(this.hexToRgba(chip.color, 0.12))
                  .borderRadius(4)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .margin({ right: 6 })
                  .onClick(() => {
                    AppStorage.setOrCreate('searchKeyword', chip.name);
                    router.pushUrl({
                      url: 'pages/discover/SearchPage',
                      params: { topicId: chip.id }
                    });
                  })
              }, (chip: TopicChip) => chip.id)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .margin({ top: 8 })
      }

      // 底部信息
      Row() {
        // 作者
        UserInfoBar({
          user: this.question.author,
          avatarSize: 24,
          showReputation: false,
          showTime: this.question.formattedTime,
          onUserClick: (userId: string) => {
            if (this.onAuthorClick) {
              this.onAuthorClick(userId);
            }
          }
        })

        Blank()

        // 统计信息
        Row() {
          this.StatItem(`${this.question.viewCount}`, '浏览')
          this.StatItem(`${this.question.answerCount}`, '回答')
          this.StatItem(`${this.question.likeCount}`, '点赞')

          if (this.question.status === 'resolved') {
            Text('已解决')
              .fontSize(10)
              .fontColor('#5CB85C')
              .backgroundColor('#E8F5E9')
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .margin({ left: 6 })
          }
        }
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .onClick(() => {
      if (this.onCardClick) {
        this.onCardClick();
      }
    })
  }

  @Builder
  StatItem(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#666')
      Text(label)
        .fontSize(10)
        .fontColor('#999')
        .margin({ top: 2 })
    }
    .margin({ left: 10 })
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 获取话题标签数据
   */
  private getTopicChips(): TopicChip[] {
    const store = getStore();
    return this.question.topicIds.map(tid => {
      const topic = store.topics.find(t => t.id === tid);
      return {
        id: tid,
        name: topic ? topic.name : tid,
        color: topic ? topic.color : '#999'
      } as TopicChip;
    });
  }

  /**
   * 十六进制颜色转 RGBA
   */
  private hexToRgba(hex: string, alpha: number): string {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }
}

interface TopicChip {
  id: string;
  name: string;
  color: string;
}
