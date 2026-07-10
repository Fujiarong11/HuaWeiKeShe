/**
 * 发布提问页面
 */
import { TopicModel } from '../../model/TopicModel';
import { TopicViewModel } from '../../viewmodel/TopicViewModel';
import { postQuestion, getAllTopics } from '../../store/DataStore';
import { promptAction } from '@kit.ArkUI';

@Component
export struct PostQuestionPage {
  @StorageLink('currentUserId') currentUserId: string = '';
  @State title: string = '';
  @State content: string = '';
  @State selectedTopicIds: string[] = [];
  @State allTopics: TopicModel[] = [];
  @State isPosting: boolean = false;
  @State titleCharCount: number = 0;
  @State contentCharCount: number = 0;
  @State showSuccess: boolean = false;
  private topicVM: TopicViewModel = TopicViewModel.getInstance();

  async aboutToAppear(): Promise<void> {
    this.allTopics = await getAllTopics();
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Text('取消')
          .fontSize(15).fontColor('#999')
          .onClick(() => { this.resetForm(); })

        Blank()

        Text('发布问题')
          .fontSize(17).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')

        Blank()

        Text('发布')
          .fontSize(15).fontColor(this.canPublish() ? '#4A90D9' : '#CCC')
          .fontWeight(FontWeight.Medium)
          .onClick(() => { this.handlePublish(); })
      }
      .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })

      Scroll() {
        Column() {
          // 标题输入
          TextInput({ placeholder: '写下你的问题标题（5-100字）', text: this.title })
            .fontSize(17).fontWeight(FontWeight.Medium)
            .width('100%').height(56)
            .backgroundColor(Color.White).borderRadius(12)
            .padding({ left: 16, right: 16 })
            .maxLength(100)
            .onChange((v: string) => {
              this.title = v;
              this.titleCharCount = v.length;
            })

          // 内容输入
          TextArea({ placeholder: '详细描述你的问题，越详细越容易获得优质回答...', text: this.content })
            .fontSize(15)
            .width('100%').height(200)
            .backgroundColor(Color.White).borderRadius(12)
            .padding(16)
            .maxLength(5000)
            .onChange((v: string) => {
              this.content = v;
              this.contentCharCount = v.length;
            })
            .margin({ top: 10 })

          // 选择话题
          Column() {
            Text('选择话题（1-5个）')
              .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#666')
              .width('100%').margin({ bottom: 10 })

            // 已选话题
            if (this.selectedTopicIds.length > 0) {
              Row() {
                ForEach(this.selectedTopicIds, (tid: string) => {
                  Text(this.getTopicName(tid))
                    .fontSize(13).fontColor('#4A90D9')
                    .backgroundColor('#EBF3FC').borderRadius(12)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .margin({ right: 6 })
                    .onClick(() => {
                      this.selectedTopicIds = this.selectedTopicIds.filter(id => id !== tid);
                    })
                })
              }.width('100%').padding(8)
            }

            // 话题选择网格
            Grid() {
              ForEach(this.allTopics, (topic: TopicModel) => {
                GridItem() {
                  Text(topic.name)
                    .fontSize(13)
                    .fontColor(this.selectedTopicIds.includes(topic.id) ? '#FFFFFF' : '#666')
                    .fontWeight(this.selectedTopicIds.includes(topic.id) ? FontWeight.Medium : FontWeight.Normal)
                    .backgroundColor(this.selectedTopicIds.includes(topic.id) ? topic.color || '#4A90D9' : '#F5F5F5')
                    .borderRadius(16)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .width('100%').textAlign(TextAlign.Center)
                    .onClick(() => {
                      if (this.selectedTopicIds.includes(topic.id)) {
                        this.selectedTopicIds = this.selectedTopicIds.filter(id => id !== topic.id);
                      } else if (this.selectedTopicIds.length < 5) {
                        this.selectedTopicIds = [...this.selectedTopicIds, topic.id];
                      }
                    })
                }
              }, (topic: TopicModel) => topic.id)
            }
            .columnsTemplate('1fr 1fr 1fr 1fr')
            .columnsGap(8)
            .rowsGap(8)
            .width('100%')
          }
          .width('100%')
          .backgroundColor(Color.White).borderRadius(12)
          .padding(16).margin({ top: 10 })

          // 发布提示
          Text('发布规范：请文明提问，避免发布违规内容。优质问题会获得更多推荐。')
            .fontSize(12).fontColor('#BBB').lineHeight(18)
            .width('100%').padding(16)
        }
        .width('100%').padding({ left: 16, right: 16, top: 8 })
      }
      .width('100%').layoutWeight(1).backgroundColor('#F5F6FA')
      .scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor('#F5F6FA')
  }

  private canPublish(): boolean {
    return this.title.trim().length >= 5 && this.content.trim().length >= 10 &&
      this.selectedTopicIds.length > 0 && !this.isPosting;
  }

  private async handlePublish(): Promise<void> {
    if (!this.canPublish()) {
      if (this.title.trim().length < 5) {
        promptAction.showToast({ message: '标题至少需要5个字', duration: 2000 });
      } else if (this.content.trim().length < 10) {
        promptAction.showToast({ message: '内容至少需要10个字', duration: 2000 });
      } else if (this.selectedTopicIds.length === 0) {
        promptAction.showToast({ message: '请至少选择一个话题', duration: 2000 });
      }
      return;
    }

    this.isPosting = true;
    try {
      await postQuestion(this.title.trim(), this.content.trim(), this.selectedTopicIds, this.currentUserId);
      this.showSuccess = true;
      this.resetForm();
      // 触发首页和我的页面刷新
      const homeTrigger: number = AppStorage.get<number>('homeRefreshTrigger') || 0;
      AppStorage.setOrCreate('homeRefreshTrigger', homeTrigger + 1);
      const profileTrigger: number = AppStorage.get<number>('profileRefreshTrigger') || 0;
      AppStorage.setOrCreate('profileRefreshTrigger', profileTrigger + 1);
      // 切换到首页 Tab
      AppStorage.setOrCreate('switchToTab', 0);
      promptAction.showToast({ message: '发布成功！', duration: 2000 });
    } catch (e) {
      promptAction.showToast({ message: '发布失败，请重试', duration: 2000 });
    } finally {
      this.isPosting = false;
    }
  }

  private resetForm(): void {
    this.title = '';
    this.content = '';
    this.selectedTopicIds = [];
    this.titleCharCount = 0;
    this.contentCharCount = 0;
    this.showSuccess = false;
  }

  private getTopicName(topicId: string): string {
    const topic = this.allTopics.find(t => t.id === topicId);
    return topic ? topic.name : topicId;
  }
}
