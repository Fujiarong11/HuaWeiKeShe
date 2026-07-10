/**
 * 问题详情页 — 展示完整问题内容、回答列表、互动操作
 */
import { QuestionModel } from '../../model/QuestionModel';
import { AnswerModel } from '../../model/AnswerModel';
import { CommentModel, CommentTargetType } from '../../model/CommentModel';
import { AnswerCard } from '../../components/AnswerCard';
import { CommentItem } from '../../components/CommentItem';
import { InteractiveBar } from '../../components/InteractiveBar';
import { LoadingFooter } from '../../components/LoadingFooter';
import { UserInfoBar } from '../../components/UserInfoBar';
import { QuestionViewModel } from '../../viewmodel/QuestionViewModel';
import { AnswerSortType } from '../../common/constants/CommonConstants';
import { getStore } from '../../store/DataStore';
import { router } from '@kit.ArkUI';

@Entry
@Component
export struct QuestionDetailPage {
  @State questionId: string = '';
  @StorageLink('currentUserId') currentUserId: string = '';
  private viewModel: QuestionViewModel = QuestionViewModel.getInstance();
  @State answerText: string = '';
  @State commentText: string = '';
  @State showAnswerInput: boolean = false;
  @State showCommentFor: string = '';
  @State dataVersion: number = 0;
  @State isRefreshing: boolean = false;
  // 直接管理点赞/收藏状态（确保 UI 即时响应）
  @State likeCount: number = 0;
  @State isLiked: boolean = false;
  @State isCollected: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.loadPageData();
  }

  private async onRefresh(): Promise<void> {
    this.isRefreshing = true;
    await this.loadPageData();
    this.isRefreshing = false;
  }

  // 页面每次显示时刷新（从其他页面返回时自动更新）
  onPageShow(): void {
    if (this.questionId) {
      this.loadPageData();
    }
  }

  private async loadPageData(): Promise<void> {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['questionId']) {
      this.questionId = params['questionId'] as string;
    } else {
      this.questionId = AppStorage.get<string>('targetQuestionId') || '';
    }
    if (this.questionId) {
      this.viewModel.clearData();
      await this.viewModel.loadQuestionDetail(this.questionId);
      await this.viewModel.loadAnswers(this.questionId);
      // 同步互动状态到本地 @State
      if (this.viewModel.currentQuestion) {
        this.likeCount = this.viewModel.currentQuestion.likeCount;
        this.isLiked = this.viewModel.currentQuestion.isLiked;
        this.isCollected = this.viewModel.currentQuestion.isCollected;
      }
      this.dataVersion++;
    }
  }

  build() {
    if (this.dataVersion === 0 && this.questionId) {
      Column() {
        LoadingProgress().width(36).height(36)
        Text('加载中...').fontSize(14).fontColor('#999').margin({ top: 12 })
      }
      .width('100%').height('100%').justifyContent(FlexAlign.Center)
    } else if (!this.viewModel.currentQuestion) {
      Column() {
        Text('😕').fontSize(48)
        Text('问题加载失败').fontSize(16).fontColor('#999').margin({ top: 12 })
        Text('返回').fontSize(14).fontColor('#4A90D9').margin({ top: 16 })
          .onClick(() => { router.back(); })
      }
      .width('100%').height('100%').justifyContent(FlexAlign.Center)
    } else {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          // 顶部导航
          Row() {
            Text('←').fontSize(24).fontColor('#333')
              .onClick(() => { router.back(); })
            Text('问题详情')
              .fontSize(17).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
              .layoutWeight(1).textAlign(TextAlign.Center)
            Text('📤').fontSize(20)
          }
          .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })

          Refresh({ refreshing: $$this.isRefreshing }) {
            Scroll() {
              Column() {
              // 问题内容区
              Column() {
                Text(this.viewModel.currentQuestion.title)
                  .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
                  .lineHeight(28).width('100%')

                Text(this.viewModel.currentQuestion.content)
                  .fontSize(15).fontColor('#333').lineHeight(24)
                  .width('100%').margin({ top: 12 })

                // 话题标签
                Row() {
                  ForEach(this.viewModel.currentQuestion.topicIds, (tid: string) => {
                    Text(this.getTopicName(tid))
                      .fontSize(12).fontColor('#4A90D9')
                      .backgroundColor('#EBF3FC').borderRadius(4)
                      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                      .margin({ right: 6 })
                      .onClick(() => {
                        const topicName = this.getTopicName(tid);
                        AppStorage.setOrCreate('searchKeyword', topicName);
                        router.pushUrl({
                          url: 'pages/discover/sousuo',
                          params: { topicId: tid }
                        });
                      })
                  })
                }.width('100%').margin({ top: 12 })

                // 作者 + 统计
                Row() {
                  UserInfoBar({
                    user: this.viewModel.currentQuestion.author,
                    avatarSize: 28,
                    showTime: this.viewModel.currentQuestion.formattedTime
                  })
                  Blank()
                  Text(`${this.viewModel.currentQuestion.viewCount} 次浏览`)
                    .fontSize(12).fontColor('#BBB')
                }.width('100%').margin({ top: 12 })

                Divider().margin({ top: 12, bottom: 4 })

                // 互动按钮
                InteractiveBar({
                  likeCount: this.likeCount,
                  commentCount: this.viewModel.currentQuestion.answerCount,
                  isLiked: this.isLiked,
                  isCollected: this.isCollected,
                  onLikeClick: () => {
                    // 乐观更新：先改本地 @State，UI 立刻响应
                    this.isLiked = !this.isLiked;
                    this.likeCount += this.isLiked ? 1 : -1;
                    // 异步同步到 ViewModel + 后端
                    this.viewModel.toggleQuestionLike();
                  },
                  onCollectClick: () => {
                    this.isCollected = !this.isCollected;
                    this.viewModel.toggleQuestionCollect();
                  },
                  onCommentClick: () => { this.showAnswerInput = !this.showAnswerInput; }
                })
              }
              .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12)
              .margin({ left: 16, right: 16, top: 8 })

              // 回答标题
              Row() {
                Text(`回答 (${this.viewModel.answerDataSource.totalCount()})`)
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
                Blank()
                Row() {
                  Text(this.viewModel.answerSortType === AnswerSortType.DEFAULT ? '默认排序' : '最新')
                    .fontSize(12).fontColor('#4A90D9')
                  Text(' ▼').fontSize(10).fontColor('#4A90D9')
                }
                .onClick(() => {
                  const nextSort = this.viewModel.answerSortType === AnswerSortType.DEFAULT ?
                    AnswerSortType.NEWEST : AnswerSortType.DEFAULT;
                  this.viewModel.switchSortType(nextSort);
                  this.dataVersion++;
                })
              }
              .width('100%').padding({ left: 16, right: 16 }).margin({ top: 16, bottom: 8 })

              // 回答列表
              if (this.viewModel.answerDataSource.totalCount() === 0) {
                Column() {
                  Text('💬').fontSize(36)
                  Text('暂无回答').fontSize(14).fontColor('#999').margin({ top: 8 })
                  Text('快来写下第一条回答吧').fontSize(12).fontColor('#BBB')
                }
                .width('100%').padding(40).alignItems(HorizontalAlign.Center)
              } else {
                List() {
                  LazyForEach(this.viewModel.answerDataSource, (answer: AnswerModel) => {
                    ListItem() {
                      Column() {
                        AnswerCard({
                          answer: answer,
                          isQuestionAuthor: this.viewModel.currentQuestion!.author.id === this.currentUserId,
                          onAccept: (id: string) => { this.viewModel.acceptAnswer(id); },
                          onLike: (id: string) => { this.viewModel.toggleAnswerLike(id); },
                          onComment: (id: string) => {
                            this.showCommentFor = id;
                            this.commentText = '';
                          },
                          onAuthorClick: (uid: string) => {
                            AppStorage.setOrCreate('targetUserId', uid);
                            router.pushUrl({ url: 'pages/user/tarenzhuye' });
                          }
                        })

                        // 评论区域
                        if (this.showCommentFor === answer.id) {
                          Column() {
                            if (this.viewModel.commentMap.has(answer.id)) {
                              ForEach(
                                this.viewModel.commentMap.get(answer.id)!.getDataArray() as CommentModel[],
                                (comment: CommentModel) => {
                                  CommentItem({
                                  comment: comment,
                                  onAuthorClick: (uid: string) => {
                                    AppStorage.setOrCreate('targetUserId', uid);
                                    router.pushUrl({ url: 'pages/user/tarenzhuye' });
                                  }
                                })
                                },
                                (comment: CommentModel) => comment.id
                              )
                            }

                            Row() {
                              TextInput({ placeholder: '写下你的评论...', text: this.commentText })
                                .fontSize(13).layoutWeight(1).height(32)
                                .onChange((v: string) => { this.commentText = v; })
                              Text('发送')
                                .fontSize(13).fontColor('#4A90D9').fontWeight(FontWeight.Medium)
                                .onClick(() => {
                                  this.viewModel.submitComment(
                                    answer.id, CommentTargetType.ANSWER,
                                    this.commentText, this.currentUserId
                                  );
                                  this.commentText = '';
                                })
                            }
                            .width('100%').padding(8)
                            .backgroundColor('#F8F9FB').borderRadius(8)
                          }.margin({ top: 4 })
                        }
                      }
                      .margin({ left: 16, right: 16 })
                    }
                  }, (answer: AnswerModel) => answer.id)

                  ListItem() {
                    LoadingFooter({ isLoading: false, hasMore: false })
                  }
                }
                .width('100%').scrollBar(BarState.Off)
              }

              Blank().height(80)
            }.width('100%')
          }
          .width('100%').scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          }
          .layoutWeight(1)
          .onRefreshing(() => {
            this.onRefresh();
          })
        }
        .width('100%').height('100%').backgroundColor('#F5F6FA')

        // 底部回答输入栏
        if (this.showAnswerInput) {
          Column() {
            Divider()
            Row() {
              TextInput({ placeholder: '写下你的回答...', text: this.answerText })
                .fontSize(14).layoutWeight(1).height(40).maxLength(2000)
                .onChange((v: string) => { this.answerText = v; })

              Button('发布')
                .fontSize(14).fontColor(Color.White)
                .backgroundColor('#4A90D9').borderRadius(20)
                .height(36).padding({ left: 16, right: 16 }).margin({ left: 10 })
                .onClick(async () => {
                  const ok = await this.viewModel.submitAnswer(
                    this.questionId, this.answerText, this.currentUserId
                  );
                  if (ok) {
                    this.answerText = '';
                    this.showAnswerInput = false;
                    this.dataVersion++;
                  }
                })
            }
            .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor(Color.White)
          }
        }
      }
      .width('100%').height('100%')
    }
  }

  private getTopicName(topicId: string): string {
    const store = getStore();
    const topic = store.topics.find(t => t.id === topicId);
    return topic ? topic.name : topicId;
  }
}
