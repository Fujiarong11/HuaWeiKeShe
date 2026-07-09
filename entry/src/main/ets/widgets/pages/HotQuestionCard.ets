/**
 * 热门问题 + 邀请回答 服务卡片
 * 2×2 / 2×4 规格，展示 Top 3 热门问题，点击可进入应用
 */
@Entry
@Component
struct HotQuestionCard {
  @LocalStorageProp('title') title: string = '🔥 热门问题';
  @LocalStorageProp('question1') question1: string = '';
  @LocalStorageProp('question2') question2: string = '';
  @LocalStorageProp('question3') question3: string = '';
  @LocalStorageProp('answerCount1') answerCount1: string = '';
  @LocalStorageProp('answerCount2') answerCount2: string = '';
  @LocalStorageProp('answerCount3') answerCount3: string = '';
  @LocalStorageProp('qid1') qid1: string = '';
  @LocalStorageProp('qid2') qid2: string = '';
  @LocalStorageProp('qid3') qid3: string = '';
  @LocalStorageProp('inviteTitle') inviteTitle: string = '📩 邀请回答';
  @LocalStorageProp('inviteCount') inviteCount: string = '';
  @LocalStorageProp('updateTime') updateTime: string = '';

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .layoutWeight(1)

        Text(this.updateTime)
          .fontSize(9)
          .fontColor('#CCC')
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 6 })

      // 热门问题列表
      if (this.question1) {
        this.QuestionRow(this.question1, this.answerCount1, this.qid1, 0)
      }
      if (this.question2) {
        this.QuestionRow(this.question2, this.answerCount2, this.qid2, 1)
      }
      if (this.question3) {
        this.QuestionRow(this.question3, this.answerCount3, this.qid3, 2)
      }

      // 分隔线
      if (this.question1 && this.inviteCount) {
        Divider()
          .strokeWidth(0.5)
          .color('#EEE')
          .margin({ left: 12, right: 12 })
      }

      // 邀请回答提醒
      if (this.inviteCount) {
        Row() {
          Text(this.inviteTitle)
            .fontSize(12)
            .fontColor('#E8634A')

          Blank()

          Text(this.inviteCount)
            .fontSize(11)
            .fontColor('#BBB')
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 5, bottom: 5 })
      }

      Blank()

      // 底部提示 — 点击整卡进入应用首页
      Text('点击问题进入应用查看 →')
        .fontSize(10)
        .fontColor('#4A90D9')
        .width('100%')
        .textAlign(TextAlign.End)
        .padding({ right: 12, bottom: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .borderRadius(8)
  }

  @Builder
  QuestionRow(question: string, count: string, qid: string, index: number) {
    Row() {
      Text(`${index + 1}`)
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(index === 0 ? '#FF6B6B' : index === 1 ? '#FFB800' : '#BBB')
        .width(18)
        .height(18)
        .borderRadius(9)
        .backgroundColor(index === 0 ? '#FFEBEE' : index === 1 ? '#FFF8E1' : '#F5F5F5')
        .textAlign(TextAlign.Center)
        .margin({ right: 8 })

      Text(question)
        .fontSize(12)
        .fontColor('#333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      if (count) {
        Text(count)
          .fontSize(9)
          .fontColor(index === 0 ? '#FF6B6B' : '#999')
          .backgroundColor(index === 0 ? '#FFEBEE' : '#F5F5F5')
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .margin({ left: 4 })
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
    .onClick(() => {
      if (qid) {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: {
            url: 'pages/question/QuestionDetailPage',
            params: { questionId: qid }
          }
        });
      }
    })
  }
}
