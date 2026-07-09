/**
 * 个人中心页面
 * 展示当前用户信息、问答统计、关注粉丝等
 */
import { UserModel } from '../model/UserModel';
import { QuestionModel, QuestionStatus } from '../model/QuestionModel';
import { AnswerModel } from '../model/AnswerModel';
import { QuestionCard } from '../components/QuestionCard';
import { UserViewModel } from '../viewmodel/UserViewModel';
import { DatabaseHelper, QuestionRow, AnswerRow, UserRow } from '../data/DatabaseHelper';
import { TopicModel } from '../model/TopicModel';
import { getStore, deleteQuestion, deleteAnswer } from '../mock/MockData';
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';

@Component
export struct ProfilePage {
  @StorageLink('currentUser') currentUser: UserModel | null = null;
  @StorageLink('currentUserId') currentUserId: string = '';
  @StorageLink('profileRefreshTrigger') profileRefreshTrigger: number = 0;
  private userVM: UserViewModel = UserViewModel.getInstance();
  @State activeTab: number = 0; // 0=提问, 1=回答
  @State myQuestions: QuestionModel[] = [];
  @State myAnswers: AnswerModel[] = [];
  @State followedTopicCount: number = 0;
  @State followedTopics: TopicModel[] = [];
  @State isRefreshing: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.loadUserContent();
  }

  async onRefresh(): Promise<void> {
    this.isRefreshing = true;
    await this.loadUserContent();
    // 同时刷新当前用户数据
    if (this.currentUserId) {
      const store = getStore();
      const dbUser: UserRow | null = await DatabaseHelper.queryUserById(this.currentUserId);
      if (dbUser) {
        store.syncUserFromDb(dbUser);
        // 同步更新 AppStorage 中的 currentUser
        const user: UserModel | undefined = store.users.find(u => u.id === this.currentUserId);
        if (user) {
          AppStorage.setOrCreate('currentUser', user);
        }
      }
    }
    this.isRefreshing = false;
  }

  async loadUserContent(): Promise<void> {
    if (!this.currentUserId) { return; }
    // 从数据库加载当前用户的提问和回答
    const dbQuestions: QuestionRow[] = await DatabaseHelper.queryQuestionsByAuthor(this.currentUserId);
    const dbAnswers: AnswerRow[] = await DatabaseHelper.queryAnswersByAuthor(this.currentUserId);

    const questions: QuestionModel[] = [];
    for (const row of dbQuestions) {
      const q: QuestionModel = new QuestionModel();
      q.id = row.id;
      q.title = row.title;
      q.content = row.content;
      q.author = this.currentUser ? this.currentUser : new UserModel();
      try {
        const parsed: Object = JSON.parse(row.topicIds) as Object;
        q.topicIds = parsed as string[];
      } catch (_e) {
        q.topicIds = [];
      }
      q.status = row.status === 'RESOLVED' ? QuestionStatus.RESOLVED : QuestionStatus.OPEN;
      q.viewCount = row.viewCount;
      q.likeCount = row.likeCount;
      q.followerCount = row.followerCount;
      q.answerCount = row.answerCount;
      q.createdAt = row.createdAt;
      q.updatedAt = row.updatedAt;
      questions.push(q);
    }

    const answers: AnswerModel[] = [];
    for (const row of dbAnswers) {
      const a: AnswerModel = new AnswerModel();
      a.id = row.id;
      a.questionId = row.questionId;
      a.content = row.content;
      a.author = this.currentUser ? this.currentUser : new UserModel();
      a.isAccepted = row.isAccepted === 1;
      a.likeCount = row.likeCount;
      a.commentCount = row.commentCount;
      a.createdAt = row.createdAt;
      answers.push(a);
    }

    this.myQuestions = questions;
    this.myAnswers = answers;

    // 加载关注的话题 & 刷新当前用户数据（确保关注/粉丝计数是最新的）
    const store = getStore();
    const refreshed = store.users.find(u => u.id === this.currentUserId);
    if (refreshed) {
      AppStorage.setOrCreate('currentUser', refreshed);
    }
    const user: UserModel | undefined = refreshed;
    if (user && user.followedTopicIds) {
      this.followedTopicCount = user.followedTopicIds.length;
      this.followedTopics = store.topics.filter(t => user.followedTopicIds.includes(t.id));
    } else {
      this.followedTopicCount = 0;
      this.followedTopics = [];
    }
  }

  build() {
    if (!this.currentUser) {
      Column() {
        LoadingProgress().width(36).height(36)
        Text('加载中...').fontSize(14).fontColor('#999').margin({ top: 12 })
      }
      .width('100%').height('100%').justifyContent(FlexAlign.Center)
    } else {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Scroll() {
          Column() {
            // 响应 profileRefreshTrigger 变化重新加载数据
            Text('')
              .width(0).height(0).fontSize(0)
              .id(`refresh_${this.profileRefreshTrigger}`)
              .onAppear(() => {
                this.loadUserContent();
              })

            // 顶部个人信息卡片
          Column() {
            Row() {
              // 头像
              Text(this.currentUser.name.charAt(0))
                .fontSize(32).fontColor(Color.White).fontWeight(FontWeight.Bold)
                .width(72).height(72).borderRadius(36)
                .backgroundColor('#4A90D9').textAlign(TextAlign.Center)

              Column() {
                Text(this.currentUser.name)
                  .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
                Text(this.currentUser.bio || '这个人很懒，什么都没写...')
                  .fontSize(13).fontColor('#999').maxLines(1).margin({ top: 4 })
                Text(`${this.currentUser.college} · ${this.currentUser.major}`)
                  .fontSize(12).fontColor('#BBB').margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start).margin({ left: 14 }).layoutWeight(1)
            }.width('100%')

            // 统计数字
            Row() {
              this.StatColumn('声望', this.currentUser.reputation)
              this.StatColumn('采纳率', `${this.currentUser.acceptanceRate}%`)
              Column() {
                Text(`${this.currentUser.followingCount}`)
                  .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
                Text('关注').fontSize(12).fontColor('#999').margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/FollowListPage',
                  params: { mode: 'following', userId: this.currentUserId }
                });
              })
              Column() {
                Text(`${this.currentUser.followerCount}`)
                  .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
                Text('粉丝').fontSize(12).fontColor('#999').margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/FollowListPage',
                  params: { mode: 'followers', userId: this.currentUserId }
                });
              })
            }
            .width('100%').margin({ top: 16 })
            .justifyContent(FlexAlign.SpaceAround)
          }
          .width('100%').padding(20).backgroundColor(Color.White).borderRadius(12)
          .margin({ left: 16, right: 16, top: 16 })

          // 内容切换标签
          Row() {
            Text(`提问 (${this.myQuestions.length})`)
              .fontSize(15)
              .fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.activeTab === 0 ? '#4A90D9' : '#666')
              .padding({ bottom: 8 })
              .border({ width: this.activeTab === 0 ? { bottom: 2 } : { bottom: 0 }, color: '#4A90D9' })
              .onClick(() => { this.activeTab = 0; })

            Text(`回答 (${this.myAnswers.length})`)
              .fontSize(15)
              .fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.activeTab === 1 ? '#4A90D9' : '#666')
              .padding({ bottom: 8 }).margin({ left: 24 })
              .border({ width: this.activeTab === 1 ? { bottom: 2 } : { bottom: 0 }, color: '#4A90D9' })
              .onClick(() => { this.activeTab = 1; })
          }
          .width('100%').padding({ left: 16, right: 16 }).margin({ top: 16 })

          // 内容列表
          if (this.activeTab === 0) {
            if (this.myQuestions.length === 0) {
              Column() {
                Text('📝').fontSize(36)
                Text('还没有提过问题').fontSize(14).fontColor('#999')
              }.width('100%').padding(40).alignItems(HorizontalAlign.Center)
            } else {
              ForEach(this.myQuestions, (question: QuestionModel) => {
                Stack({ alignContent: Alignment.TopEnd }) {
                  QuestionCard({
                    question: question,
                    showTopicTags: true,
                    onCardClick: () => {
                      router.pushUrl({
                        url: 'pages/QuestionDetailPage',
                        params: { questionId: question.id }
                      });
                    }
                  })

                  Text('✕')
                    .fontSize(14).fontColor('#E8634A')
                    .width(28).height(28)
                    .borderRadius(14).backgroundColor('rgba(255,255,255,0.9)')
                    .textAlign(TextAlign.Center)
                    .margin({ top: 8, right: 8 })
                    .onClick(() => { this.handleDeleteQuestion(question.id); })
                }
                .width('100%')
                .margin({ left: 16, right: 16, top: 6, bottom: 6 })
              }, (question: QuestionModel) => question.id)
            }
          } else {
            if (this.myAnswers.length === 0) {
              Column() {
                Text('💬').fontSize(36)
                Text('还没有回答过问题').fontSize(14).fontColor('#999')
              }.width('100%').padding(40).alignItems(HorizontalAlign.Center)
            } else {
              ForEach(this.myAnswers, (answer: AnswerModel) => {
                Column() {
                  Row() {
                    Text(this.getQuestionTitle(answer.questionId))
                      .fontSize(14).fontColor('#4A90D9').maxLines(1).layoutWeight(1)
                    Text(answer.isAccepted ? '✓ 已采纳' : '')
                      .fontSize(12).fontColor('#5CB85C')
                  }.width('100%')
                  Text(answer.content)
                    .fontSize(13).fontColor('#666').maxLines(3).margin({ top: 6 })
                    .lineHeight(20)
                  Row() {
                    Text(`👍 ${answer.likeCount}`).fontSize(11).fontColor('#BBB')
                    Text(`💬 ${answer.commentCount}`).fontSize(11).fontColor('#BBB').margin({ left: 12 })
                    Blank()
                    Text('删除')
                      .fontSize(11).fontColor('#E8634A')
                      .padding({ left: 8, right: 4, top: 2, bottom: 2 })
                      .onClick(() => { this.handleDeleteAnswer(answer.id); })
                  }.width('100%').margin({ top: 8 })
                }
                .width('100%').padding(14).backgroundColor(Color.White).borderRadius(10)
                .margin({ left: 16, right: 16, top: 6, bottom: 6 })
              }, (answer: AnswerModel) => answer.id)
            }
          }

          // 退出登录按钮
          Button('退出登录')
            .fontSize(15).fontColor('#E8634A')
            .backgroundColor(Color.White)
            .width('90%').height(44).borderRadius(22)
            .border({ width: 1, color: '#E8634A', style: BorderStyle.Solid })
            .margin({ top: 24, bottom: 40 })
            .onClick(() => { this.handleLogout(); })
        }.width('100%')
      }
      .width('100%').height('100%').backgroundColor('#F5F6FA').scrollBar(BarState.Off)
    }
    .onRefreshing(() => {
      this.onRefresh();
    })
    }
  }

  @Builder
  StatColumn(label: string, value: string | number) {
    Column() {
      Text(`${value}`).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
      Text(label).fontSize(12).fontColor('#999').margin({ top: 4 })
    }.alignItems(HorizontalAlign.Center)
  }

  private getQuestionTitle(questionId: string): string {
    const myQ: QuestionModel | undefined = this.myQuestions.find(q => q.id === questionId);
    if (myQ) {
      return myQ.title;
    }
    const store = getStore();
    const q: QuestionModel | undefined = store.questions.find(q => q.id === questionId);
    return q ? q.title : '未知问题';
  }

  private handleLogout(): void {
    this.userVM.logout();
  }

  private async handleDeleteQuestion(questionId: string): Promise<void> {
    const dialog = promptAction.showDialog({
      title: '确认删除',
      message: '删除提问后，该问题下的所有回答也会被删除，确定继续吗？',
      buttons: [
        { text: '取消', color: '#999' },
        { text: '删除', color: '#E8634A' }
      ]
    });
    const result = await dialog;
    if (result.index === 1) {
      await deleteQuestion(questionId);
      await this.loadUserContent();
    }
  }

  private async handleDeleteAnswer(answerId: string): Promise<void> {
    const dialog = promptAction.showDialog({
      title: '确认删除',
      message: '确定要删除这条回答吗？',
      buttons: [
        { text: '取消', color: '#999' },
        { text: '删除', color: '#E8634A' }
      ]
    });
    const result = await dialog;
    if (result.index === 1) {
      await deleteAnswer(answerId);
      await this.loadUserContent();
    }
  }
}
