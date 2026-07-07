/**
 * 个人中心页面
 * 展示当前用户信息、问答统计、关注粉丝等
 */
import { UserModel } from '../model/UserModel';
import { QuestionModel } from '../model/QuestionModel';
import { AnswerModel } from '../model/AnswerModel';
import { QuestionCard } from '../components/QuestionCard';
import { UserViewModel } from '../viewmodel/UserViewModel';
import { getStore } from '../mock/MockData';
import { router } from '@kit.ArkUI';

@Component
export struct ProfilePage {
  @StorageLink('currentUser') currentUser: UserModel | null = null;
  @StorageLink('currentUserId') currentUserId: string = '';
  private userVM: UserViewModel = UserViewModel.getInstance();
  @State activeTab: number = 0; // 0=提问, 1=回答
  @State myQuestions: QuestionModel[] = [];
  @State myAnswers: AnswerModel[] = [];

  async aboutToAppear(): Promise<void> {
    await this.loadUserContent();
  }

  async loadUserContent(): Promise<void> {
    if (!this.currentUserId) { return; }
    const store = getStore();
    this.myQuestions = store.questions.filter(q => q.author.id === this.currentUserId);
    this.myAnswers = store.answers.filter(a => a.author.id === this.currentUserId);
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
              this.StatColumn('采纳率', `${this.currentUser.acceptanceRate}%`)
              this.StatColumn('关注', this.currentUser.followingCount)
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

          // 底部留白
          Blank().height(40)
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
    const store = getStore();
    const q = store.questions.find(q => q.id === questionId);
    return q ? q.title : '未知问题';
  }
}
