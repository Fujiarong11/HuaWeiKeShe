/**
 * 首页推荐页面
 * 展示个性化推荐的问题信息流，支持下拉刷新
 */
import { QuestionModel } from '../../model/QuestionModel';
import { TopicModel } from '../../model/TopicModel';
import { QuestionCard } from '../../components/QuestionCard';
import { LoadingFooter } from '../../components/LoadingFooter';
import { EmptyPlaceholder } from '../../components/EmptyPlaceholder';
import { HomeViewModel } from '../../viewmodel/HomeViewModel';
import { HomeTabType } from '../../common/constants/CommonConstants';
import { router } from '@kit.ArkUI';

@Component
export struct HomePage {
  @StorageLink('currentUserId') currentUserId: string = '';
  @StorageLink('homeRefreshTrigger') homeRefreshTrigger: number = 0;
  private viewModel: HomeViewModel = HomeViewModel.getInstance();
  @State currentTab: number = 0;
  @State dataVersion: number = 0;
  @State isRefreshing: boolean = false;
  private lastRefreshTrigger: number = 0;
  private tabTitles: string[] = ['推荐', '热门', '最新', '关注'];
  private tabTypes: HomeTabType[] = [
    HomeTabType.RECOMMEND,
    HomeTabType.HOT,
    HomeTabType.NEWEST,
    HomeTabType.FOLLOWING
  ];

  async aboutToAppear(): Promise<void> {
    await this.loadData();
  }

  onPageShow(): void {
    if (this.homeRefreshTrigger !== this.lastRefreshTrigger) {
      this.lastRefreshTrigger = this.homeRefreshTrigger;
      this.loadData();
    }
  }

  build() {
    Column() {
      // 顶部搜索栏
      Row() {
        Text('校园问答')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
        Blank()
        Text('🔍')
          .fontSize(18).width(36).height(36).borderRadius(18)
          .backgroundColor('#F5F5F5').textAlign(TextAlign.Center)
          .onClick(() => {
            AppStorage.setOrCreate('searchKeyword', '');
            router.pushUrl({ url: 'pages/discover/SearchPage' });
          })
      }
      .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 4 })

      // 分类切换标签
      Scroll() {
        Row() {
          ForEach(this.tabTitles, (title: string, index: number) => {
            Text(title)
              .fontSize(14)
              .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.currentTab === index ? '#4A90D9' : '#666')
              .margin({ right: 20 }).padding({ bottom: 6 })
              .border({
                width: this.currentTab === index ? { bottom: 2 } : { bottom: 0 },
                color: '#4A90D9'
              })
              .onClick(() => {
                this.currentTab = index;
                this.viewModel.switchTab(this.tabTypes[index], this.currentUserId);
                this.dataVersion++;
              })
          })
        }.padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
      .width('100%').height(40)

      // 关注话题横滑栏
      if (this.viewModel.topicDataSource.totalCount() > 0) {
        Scroll() {
          Row() {
            ForEach(this.viewModel.topicDataSource.getDataArray() as TopicModel[], (topic: TopicModel) => {
              Text(topic.name)
                .fontSize(12).fontColor(topic.color || '#999')
                .backgroundColor(this.hexToRgba(topic.color || '#999', 0.1))
                .borderRadius(12)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .margin({ right: 8 })
                .onClick(() => {
                  AppStorage.setOrCreate('searchKeyword', topic.name);
                  router.pushUrl({
                    url: 'pages/discover/SearchPage',
                    params: { topicId: topic.id }
                  });
                })
            }, (topic: TopicModel) => topic.id)
          }.padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
        .width('100%').height(36)
      }

      // 下拉刷新 + 问题列表
      Refresh({ refreshing: $$this.isRefreshing }) {
        if (this.dataVersion > 0 && this.viewModel.questionDataSource.totalCount() > 0 ||
          !this.viewModel.isLoading && this.viewModel.questionDataSource.totalCount() > 0) {
          List() {
            LazyForEach(this.viewModel.questionDataSource, (question: QuestionModel) => {
              ListItem() {
                QuestionCard({
                  question: question,
                  showTopicTags: true,
                  onCardClick: () => {
                    router.pushUrl({
                      url: 'pages/question/QuestionDetailPage',
                      params: { questionId: question.id }
                    });
                  },
                  onAuthorClick: (userId: string) => {
                    AppStorage.setOrCreate('targetUserId', userId);
                    router.pushUrl({ url: 'pages/user/UserProfilePage' });
                  }
                })
                .margin({ left: 16, right: 16, top: 6, bottom: 6 })
              }
            }, (question: QuestionModel) => question.id)

            ListItem() {
              LoadingFooter({
                isLoading: this.viewModel.isLoading,
                hasMore: this.viewModel.hasMore,
                text: '— 没有更多问题了 —'
              })
            }
          }
          .width('100%').layoutWeight(1).backgroundColor('#F5F6FA')
          .scrollBar(BarState.Off)
          .onReachEnd(() => {
            this.viewModel.loadMore(this.currentUserId);
          })
        } else if (this.viewModel.isLoading && this.dataVersion === 0) {
          Column() {
            LoadingProgress().width(36).height(36)
            Text('正在加载...').fontSize(14).fontColor('#999').margin({ top: 12 })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          Column() {
            EmptyPlaceholder({
              icon: '📝',
              title: '暂无内容',
              description: '还没有人提问，快去发布第一个问题吧'
            })
          }
          .width('100%').layoutWeight(1)
        }
      }
      .onRefreshing(() => {
        this.onRefresh();
      })
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#F5F6FA')
  }

  private async onRefresh(): Promise<void> {
    this.isRefreshing = true;
    await this.loadData();
    this.isRefreshing = false;
  }

  private async loadData(): Promise<void> {
    if (this.currentUserId) {
      await this.viewModel.refresh(this.currentUserId);
      await this.viewModel.loadFollowedTopics(this.currentUserId);
      this.dataVersion++;
    }
  }

  private hexToRgba(hex: string, alpha: number): string {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }
}
