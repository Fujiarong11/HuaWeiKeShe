/**
 * 个人中心页面
 * 展示当前用户信息、问答统计、关注粉丝等
 */
import { UserModel } from '../model/UserModel';
import { QuestionModel, QuestionStatus } from '../model/QuestionModel';
import { AnswerModel } from '../model/AnswerModel';
import { QuestionCard } from '../components/QuestionCard';
import { UserViewModel } from '../viewmodel/UserViewModel';
import { DatabaseHelper, QuestionRow, AnswerRow } from '../data/DatabaseHelper';
import { TopicModel } from '../model/TopicModel';
import { getStore } from '../mock/MockData';
import { router } from '@kit.ArkUI';

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

  async aboutToAppear(): Promise<void> {
    await this.loadUserContent();
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

    // 加载关注的话题
    const store = getStore();
    const user: UserModel | undefined = store.users.find(u => u.id === this.currentUserId);
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
      Scroll() {
        Column() {
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
              this.StatColumn('采纳率', '0%')
              Column() {
                Text(`${this.followedTopicCount}`)
                  .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#4A90D9')
                Text('关注话题')
                  .fontSize(12).fontColor('#999').margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Center)
              .onClick(() => { this.showFollowedTopics(); })
              this.StatColumn('粉丝', this.currentUser.followerCount)
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
                  }.margin({ top: 8 })
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

  /**
   * 点击关注话题，跳转到话题广场查看已关注的话题
   */
  private showFollowedTopics(): void {
    // 切换到话题广场 Tab（Tab 1）
    AppStorage.setOrCreate('switchToTab', 1);
  }
}
