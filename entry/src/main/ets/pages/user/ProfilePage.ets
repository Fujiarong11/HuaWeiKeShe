/**
 * 个人中心页面
 * 展示当前用户信息、问答统计、关注粉丝等
 */
import { UserModel } from '../../model/UserModel';
import { QuestionModel, QuestionStatus } from '../../model/QuestionModel';
import { AnswerModel } from '../../model/AnswerModel';
import { QuestionCard } from '../../components/QuestionCard';
import { UserViewModel } from '../../viewmodel/UserViewModel';
import { DatabaseHelper, AnswerRow } from '../../data/DatabaseHelper';
import { TopicModel } from '../../model/TopicModel';
import { getStore, deleteQuestion, deleteAnswer } from '../../mock/MockData';
import * as QuestionApi from '../../api/QuestionApi';
import type { QuestionResponse } from '../../api/QuestionApi';
import * as UserApi from '../../api/UserApi';
import type { UserResponse } from '../../api/UserApi';
import * as InteractionApi from '../../api/InteractionApi';
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
  @State favoriteQuestions: QuestionModel[] = [];
  @State followedTopicCount: number = 0;
  @State followedTopics: TopicModel[] = [];
  @State isRefreshing: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.loadUserContent();
  }

  async onRefresh(): Promise<void> {
    this.isRefreshing = true;
    await this.loadUserContent();
    this.isRefreshing = false;
  }

  async loadUserContent(): Promise<void> {
    if (!this.currentUserId) { return; }

    // 从后端加载我的问题（不用本地 store）
    const questions: QuestionModel[] = [];
    if (/^\d+$/.test(this.currentUserId)) {
      const res = await QuestionApi.getUserQuestions(this.currentUserId);
      if (res.code === 0 && res.data) {
        const list: object[] = res.data as object[];
        for (const item of list) {
          const r: QuestionResponse = item as QuestionResponse;
          const q: QuestionModel = new QuestionModel();
          q.id = String(r.id);
          q.title = r.title;
          q.content = r.content;
          q.author = this.currentUser ? this.currentUser : new UserModel();
          q.topicIds = r.topicIds || [];
          q.status = r.status === 'RESOLVED' ? QuestionStatus.RESOLVED : QuestionStatus.OPEN;
          q.viewCount = r.viewCount || 0;
          q.likeCount = r.likeCount || 0;
          q.followerCount = r.followerCount || 0;
          q.answerCount = r.answerCount || 0;
          q.createdAt = r.createdAt || '';
          q.updatedAt = r.updatedAt || '';
          questions.push(q);
        }
      }
    }

    // 回答还是从本地DB加载（暂未迁移）
    const dbAnswers: AnswerRow[] = await DatabaseHelper.queryAnswersByAuthor(this.currentUserId);
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

    // 从后端刷新关注/粉丝计数
    if (this.currentUser) {
      const uRes = await UserApi.getUserById(this.currentUser.id);
      if (uRes.code === 0 && uRes.data) {
        const uResp: UserResponse = uRes.data as UserResponse;
        // 创建新对象引用，确保 @StorageLink 能检测到变化触发UI刷新
        const updated: UserModel = new UserModel();
        updated.id = this.currentUser.id;
        updated.phone = this.currentUser.phone;
        updated.name = this.currentUser.name;
        updated.avatar = this.currentUser.avatar;
        updated.bio = this.currentUser.bio;
        updated.college = this.currentUser.college;
        updated.major = this.currentUser.major;
        updated.grade = this.currentUser.grade;
        updated.reputation = this.currentUser.reputation;
        updated.acceptedCount = this.currentUser.acceptedCount;
        updated.totalAnswers = this.currentUser.totalAnswers;
        updated.totalQuestions = this.currentUser.totalQuestions;
        updated.followedTopicIds = this.currentUser.followedTopicIds;
        // 从后端取最新计数
        updated.followerCount = uResp.followerCount || 0;
        updated.followingCount = uResp.followingCount || 0;
        updated.createdAt = this.currentUser.createdAt;
        this.currentUser = updated;
        AppStorage.setOrCreate('currentUser', updated);
      }
    }

    // 从后端加载收藏的问题列表
    await this.loadFavoriteQuestions();

    const store = getStore();
    const user: UserModel | undefined = this.currentUser ?? undefined;
    if (user && user.followedTopicIds) {
      this.followedTopicCount = user.followedTopicIds.length;
      this.followedTopics = store.topics.filter((t: TopicModel) => user.followedTopicIds.includes(t.id));
    } else {
      this.followedTopicCount = 0;
      this.followedTopics = [];
    }
  }

  /** 加载收藏的问题（后端 API） */
  async loadFavoriteQuestions(): Promise<void> {
    if (!this.currentUserId || !/^\d+$/.test(this.currentUserId)) {
      this.favoriteQuestions = [];
      return;
    }
    try {
      const res = await InteractionApi.getUserFavorites(this.currentUserId);
      if (res.code === 0 && res.data) {
        const list: object[] = res.data as object[];
        const questions: QuestionModel[] = [];
        for (const item of list) {
          const r: QuestionResponse = item as QuestionResponse;
          const q: QuestionModel = new QuestionModel();
          q.id = String(r.id);
          q.title = r.title;
          q.content = r.content;
          q.author = this.currentUser ? this.currentUser : new UserModel();
          q.topicIds = r.topicIds || [];
          q.status = r.status === 'RESOLVED' ? QuestionStatus.RESOLVED : QuestionStatus.OPEN;
          q.viewCount = r.viewCount || 0;
          q.likeCount = r.likeCount || 0;
          q.followerCount = r.followerCount || 0;
          q.answerCount = r.answerCount || 0;
          q.createdAt = r.createdAt || '';
          q.updatedAt = r.updatedAt || '';
          questions.push(q);
        }
        this.favoriteQuestions = questions;
      }
    } catch (e) {
      this.favoriteQuestions = [];
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
      Column() {
        Refresh({ refreshing: $$this.isRefreshing }) {
          Scroll() {
            Column() {
              Text('')
                .width(0).height(0).fontSize(0)
                .id(`refresh_${this.profileRefreshTrigger}`)
                .onAppear(() => {
                  this.loadUserContent();
                })

              // 顶部个人信息卡片
            Column() {
              Row() {
                Text(this.currentUser!.name.charAt(0))
                  .fontSize(32).fontColor(Color.White).fontWeight(FontWeight.Bold)
                  .width(72).height(72).borderRadius(36)
                  .backgroundColor('#4A90D9').textAlign(TextAlign.Center)

                Column() {
                  Text(this.currentUser!.name)
                    .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
                  Text(this.currentUser!.bio || '这个人很懒，什么都没写...')
                    .fontSize(13).fontColor('#999').maxLines(1).margin({ top: 4 })
                  Text(`${this.currentUser!.college} · ${this.currentUser!.major}`)
                    .fontSize(12).fontColor('#BBB').margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start).margin({ left: 14 }).layoutWeight(1)
              }.width('100%')

              Row() {
                this.StatColumn('声望', this.currentUser!.reputation)
                this.StatColumn('采纳率', `${this.currentUser!.acceptanceRate}%`)
                Column() {
                  Text(`${this.currentUser!.followingCount}`)
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
                  Text(`${this.currentUser!.followerCount}`)
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
            .margin({ left: 16, right: 16, top: 5 })

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

              Text(`收藏 (${this.favoriteQuestions.length})`)
                .fontSize(15)
                .fontWeight(this.activeTab === 2 ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.activeTab === 2 ? '#4A90D9' : '#666')
                .padding({ bottom: 8 }).margin({ left: 24 })
                .border({ width: this.activeTab === 2 ? { bottom: 2 } : { bottom: 0 }, color: '#4A90D9' })
                .onClick(() => { this.activeTab = 2; })
            }
            .width('100%').padding({ left: 16, right: 16 }).margin({ top: 12 })

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
                          url: 'pages/question/QuestionDetailPage',
                          params: { questionId: question.id }
                        });
                      },
                      onAuthorClick: (userId: string) => {
                        AppStorage.setOrCreate('targetUserId', userId);
                        router.pushUrl({ url: 'pages/user/UserProfilePage' });
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
            } else if (this.activeTab === 1) {
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
            } else {
              // 收藏 Tab
              if (this.favoriteQuestions.length === 0) {
                Column() {
                  Text('⭐').fontSize(36)
                  Text('还没有收藏过问题').fontSize(14).fontColor('#999')
                }.width('100%').padding(40).alignItems(HorizontalAlign.Center)
              } else {
                ForEach(this.favoriteQuestions, (question: QuestionModel) => {
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
                }, (question: QuestionModel) => question.id)
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
        .width('100%').layoutWeight(1).backgroundColor('#F5F6FA').scrollBar(BarState.Off)
      }
      .onRefreshing(() => {
        this.onRefresh();
      })
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#F5F6FA')
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
