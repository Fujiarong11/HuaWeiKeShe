/**
 * 话题广场页面
 * 展示所有话题，支持搜索和关注
 */
import { TopicModel } from '../model/TopicModel';
import { TopicCard } from '../components/TopicCard';
import { SearchBar } from '../components/SearchBar';
import { EmptyPlaceholder } from '../components/EmptyPlaceholder';
import { TopicViewModel } from '../viewmodel/TopicViewModel';
import { router } from '@kit.ArkUI';

@Component
export struct TopicSquarePage {
  @StorageLink('currentUserId') currentUserId: string = '';
  private viewModel: TopicViewModel = TopicViewModel.getInstance();
  @State searchKeyword: string = '';
  @State dataVersion: number = 0;

  async aboutToAppear(): Promise<void> {
    await this.viewModel.loadAllTopics();
    this.dataVersion++;
  }

  build() {
    Column() {
      // 标题
      Text('话题广场')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
        .width('100%').padding({ left: 16, right: 16, top: 8 })

      // 搜索
      SearchBar({
        placeholder: '搜索话题...',
        onChange: (value: string) => {
          this.searchKeyword = value;
          this.viewModel.searchTopics(value);
          this.dataVersion++;
        }
      })

      // 已关注话题区域
      if (this.viewModel.followedTopicDataSource.totalCount() > 0 && !this.searchKeyword) {
        Column() {
          Row() {
            Text('我的关注').fontSize(15).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
            Blank()
            Text(`${this.viewModel.followedTopicDataSource.totalCount()} 个话题`)
              .fontSize(12).fontColor('#BBB')
          }
          .width('100%').padding({ left: 16, right: 16 }).margin({ top: 8 })

          Scroll() {
            Row() {
              ForEach(
                this.viewModel.followedTopicDataSource.getDataArray() as TopicModel[],
                (topic: TopicModel) => {
                  Text(topic.name)
                    .fontSize(13).fontColor(topic.color || '#4A90D9')
                    .backgroundColor(this.hexToRgba(topic.color || '#999', 0.1))
                    .borderRadius(12)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .margin({ right: 8 })
                    .onClick(() => {
                      AppStorage.setOrCreate('searchKeyword', topic.name);
                      router.pushUrl({
                        url: 'pages/SearchPage',
                        params: { topicId: topic.id }
                      });
                    })
                },
                (topic: TopicModel) => topic.id
              )
            }.padding({ left: 16, right: 16 })
          }
          .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
          .width('100%').height(36)
        }
      }

      // 全部分类标题
      Text(this.searchKeyword ? '搜索结果' : '全部分类')
        .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
        .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // 话题网格
      if (this.dataVersion > 0 && this.viewModel.allTopicDataSource.totalCount() > 0) {
        Grid() {
          LazyForEach(this.viewModel.allTopicDataSource, (topic: TopicModel) => {
            GridItem() {
              TopicCard({
                topic: topic,
                onCardClick: () => {
                  AppStorage.setOrCreate('searchKeyword', topic.name);
                  router.pushUrl({
                    url: 'pages/SearchPage',
                    params: { topicId: topic.id }
                  });
                },
                onFollowToggle: () => {
                  this.viewModel.toggleFollow(topic.id, this.currentUserId);
                  this.dataVersion++;
                }
              })
            }
          }, (topic: TopicModel) => topic.id)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(10).rowsGap(10)
        .padding({ left: 16, right: 16 })
        .width('100%').layoutWeight(1).scrollBar(BarState.Off)
      } else if (this.viewModel.isLoading) {
        Column() {
          LoadingProgress().width(36).height(36)
          Text('正在加载...').fontSize(14).fontColor('#999').margin({ top: 12 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        EmptyPlaceholder({
          icon: '🏷️',
          title: '没有找到相关话题',
          description: '试试其他关键词吧'
        })
        .width('100%').layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F6FA')
  }

  private hexToRgba(hex: string, alpha: number): string {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }
}
