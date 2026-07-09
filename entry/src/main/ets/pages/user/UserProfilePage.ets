/**
 * 他人主页
 */
import { UserModel } from '../model/UserModel';
import { QuestionModel } from '../model/QuestionModel';
import { AnswerModel } from '../model/AnswerModel';
import { QuestionCard } from '../components/QuestionCard';
import { UserViewModel } from '../viewmodel/UserViewModel';
import { router } from '@kit.ArkUI';

@Entry
@Component
export struct UserProfilePage {
  @StorageLink('targetUserId') userId: string = '';
  @StorageLink('currentUserId') currentUserId: string = '';
  private userVM: UserViewModel = UserViewModel.getInstance();
  @State activeTab: number = 0;
  @State dataVersion: number = 0;

  async aboutToAppear(): Promise<void> {
    if (this.userId) {
      await this.userVM.loadUserProfile(this.userId);
      // Also load questions and answers
      const store = (await import('../mock/MockData')).getStore();
      const questions = store.questions.filter(q => q.author.id === this.userId);
      const answers = store.answers.filter(a => a.author.id === this.userId);
      this.userVM.userQuestions.reloadData(questions);
      this.userVM.userAnswers.reloadData(answers);
      this.dataVersion++;
    }
  }

  build() {
    Column() {
      Row() {
        Text('←').fontSize(24).fontColor('#333')
          .onClick(() => { router.back(); })
        Text('用户主页').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text('').width(30)
      }
      .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })

      if (this.dataVersion === 0 || !this.userVM.viewingUser) {
        Column() {
          LoadingProgress().width(36).height(36)
          Text('加载中...').fontSize(14).fontColor('#999').margin({ top: 12 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            // 用户信息卡片
            Column() {
              Text(this.userVM.viewingUser.name.charAt(0))
                .fontSize(36).fontColor(Color.White).fontWeight(FontWeight.Bold)
                .width(80).height(80).borderRadius(40)
                .backgroundColor('#4A90D9').textAlign(TextAlign.Center)
              Text(this.userVM.viewingUser.name)
                .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ top: 10 })
              Text(this.userVM.viewingUser.bio)
                .fontSize(13).fontColor('#999').margin({ top: 4 })
              Text(`${this.userVM.viewingUser.college} · ${this.userVM.viewingUser.major}`)
                .fontSize(12).fontColor('#BBB').margin({ top: 4 })

              if (this.userVM.viewingUser.id !== this.currentUserId) {
                Row() {
                  Button('+ 关注')
                    .fontSize(14).fontColor(Color.White)
                    .backgroundColor('#4A90D9').borderRadius(20)
                    .height(34).padding({ left: 24, right: 24 })
                    .onClick(() => { this.userVM.toggleFollow(this.userId); })
                  Button('私信')
                    .fontSize(14).fontColor('#4A90D9')
                    .backgroundColor(Color.White).borderRadius(20)
                    .height(34).padding({ left: 24, right: 24 })
                    .border({ width: 1, color: '#4A90D9', style: BorderStyle.Solid })
                    .margin({ left: 12 })
                }.margin({ top: 14 })
              }
            }
            .width('100%').padding(24).backgroundColor(Color.White).borderRadius(12)
            .margin({ left: 16, right: 16, top: 8 }).alignItems(HorizontalAlign.Center)

            // 数据统计
            Row() {
              this.StatItem('声望', this.userVM.viewingUser.reputation)
              this.StatItem('采纳率', `${this.userVM.viewingUser.acceptanceRate}%`)
              this.StatItem('回答', this.userVM.viewingUser.totalAnswers)
              this.StatItem('关注', this.userVM.viewingUser.followingCount)
              this.StatItem('粉丝', this.userVM.viewingUser.followerCount)
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12)
            .margin({ left: 16, right: 16, top: 10 })
            .justifyContent(FlexAlign.SpaceAround)

            // 内容标签
            Row() {
              Text(`提问 (${this.userVM.userQuestions.totalCount()})`)
                .fontSize(15)
                .fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.activeTab === 0 ? '#4A90D9' : '#666')
                .padding({ bottom: 8 })
                .border({ width: this.activeTab === 0 ? { bottom: 2 } : { bottom: 0 }, color: '#4A90D9' })
                .onClick(() => { this.activeTab = 0; })
              Text(`回答 (${this.userVM.userAnswers.totalCount()})`)
                .fontSize(15)
                .fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.activeTab === 1 ? '#4A90D9' : '#666')
                .padding({ bottom: 8 }).margin({ left: 24 })
                .border({ width: this.activeTab === 1 ? { bottom: 2 } : { bottom: 0 }, color: '#4A90D9' })
                .onClick(() => { this.activeTab = 1; })
            }
            .width('100%').padding({ left: 16, right: 16 }).margin({ top: 12 })

            if (this.activeTab === 0) {
              if (this.userVM.userQuestions.totalCount() === 0) {
                Column() {
                  Text('📝').fontSize(36)
                  Text('还没有提过问题').fontSize(14).fontColor('#999')
                }.width('100%').padding(40).alignItems(HorizontalAlign.Center)
              } else {
                ForEach(this.userVM.userQuestions.getDataArray() as QuestionModel[],
                  (q: QuestionModel) => {
                    QuestionCard({
                      question: q, showTopicTags: true,
                      onCardClick: () => {
                        router.pushUrl({
                          url: 'pages/QuestionDetailPage',
                          params: { questionId: q.id }
                        });
                      }
                    }).margin({ left: 16, right: 16, top: 4, bottom: 4 })
                  }, (q: QuestionModel) => q.id)
              }
            } else {
              if (this.userVM.userAnswers.totalCount() === 0) {
                Column() {
                  Text('💬').fontSize(36)
                  Text('还没有回答过问题').fontSize(14).fontColor('#999')
                }.width('100%').padding(40).alignItems(HorizontalAlign.Center)
              } else {
                ForEach(this.userVM.userAnswers.getDataArray() as AnswerModel[],
                  (a: AnswerModel) => {
                    Column() {
                      Text(a.content)
                        .fontSize(13).fontColor('#666').maxLines(4).lineHeight(20)
                      Row() {
                        Text(`👍 ${a.likeCount}`).fontSize(11).fontColor('#BBB')
                        Text(a.isAccepted ? ' ✓ 已采纳' : '').fontSize(11).fontColor('#5CB85C')
                      }.margin({ top: 6 })
                    }
                    .width('100%').padding(14).backgroundColor(Color.White).borderRadius(10)
                    .margin({ left: 16, right: 16, top: 4, bottom: 4 })
                  }, (a: AnswerModel) => a.id)
              }
            }

            Blank().height(40)
          }.width('100%')
        }
        .width('100%').layoutWeight(1).scrollBar(BarState.Off)
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F6FA')
  }

  @Builder
  StatItem(label: string, value: string | number) {
    Column() {
      Text(`${value}`).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
      Text(label).fontSize(11).fontColor('#999').margin({ top: 3 })
    }.alignItems(HorizontalAlign.Center)
  }
}
