/**
 * 服务卡片组件（应用内）
 * 展示热门问题排行 + 邀请回答提醒，可按浏览量排序
 */
import { QuestionModel } from '../model/QuestionModel';
import { getHotQuestions, getPendingInviteCount } from '../store/DataStore';
import { router } from '@kit.ArkUI';

@Component
export struct ServiceCard {
  @StorageLink('currentUserId') currentUserId: string = '';
  @State hotQuestions: QuestionModel[] = [];
  @State inviteCount: number = 0;
  @State dataVersion: number = 0;

  async aboutToAppear(): Promise<void> {
    await this.loadData();
  }

  async loadData(): Promise<void> {
    // 从内存 store 获取热门问题（按浏览量+点赞+回答综合排名）
    this.hotQuestions = await getHotQuestions(3);
    // 获取待处理的邀请回答数
    if (this.currentUserId) {
      this.inviteCount = getPendingInviteCount(this.currentUserId);
    }
    this.dataVersion++;
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('🔥 热门问题')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')

        Blank()

        if (this.inviteCount > 0) {
          Row() {
            Text('📩')
              .fontSize(12)
            Text(`${this.inviteCount} 条邀请`)
              .fontSize(11)
              .fontColor('#E8634A')
              .fontWeight(FontWeight.Bold)
              .margin({ left: 2 })
          }
          .backgroundColor('#FFF0F0')
          .borderRadius(12)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 4 })

      // 问题排行列表
      if (this.hotQuestions.length === 0) {
        Row() {
          LoadingProgress().width(16).height(16)
          Text(' 加载中...')
            .fontSize(12)
            .fontColor('#BBB')
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.Center)
      } else {
        ForEach(this.hotQuestions, (q: QuestionModel, index: number) => {
          Row() {
            // 排名徽章
            Text(`${index + 1}`)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(index === 0 ? '#FF6B6B' : index === 1 ? '#FFB800' : '#BBB')
              .width(20)
              .height(20)
              .borderRadius(10)
              .backgroundColor(index === 0 ? '#FFEBEE' : index === 1 ? '#FFF8E1' : '#F5F5F5')
              .textAlign(TextAlign.Center)
              .margin({ right: 10 })

            // 标题
            Text(q.title)
              .fontSize(13)
              .fontColor('#333')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            // 热度数据
            Text(`👁 ${q.viewCount}`)
              .fontSize(10)
              .fontColor('#BBB')
              .margin({ left: 6 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/question/tiezi',
              params: { questionId: q.id }
            });
          })
        }, (q: QuestionModel) => q.id)
      }

      // 底部
      Row() {
        Text('查看全部热门 →')
          .fontSize(11)
          .fontColor('#4A90D9')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 10 })
      .justifyContent(FlexAlign.End)
      .onClick(() => {
        // 切到首页的"热门"tab
        AppStorage.setOrCreate('homeRefreshTrigger',
          (AppStorage.get<number>('homeRefreshTrigger') || 0) + 1);
        router.replaceUrl({ url: 'pages/home/Index' });
      })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 6, bottom: 2 })
  }
}
