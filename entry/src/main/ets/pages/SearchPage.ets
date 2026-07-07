/**
 * 全文搜索页面
 */
import { QuestionModel } from '../model/QuestionModel';
import { TopicModel } from '../model/TopicModel';
import { UserModel } from '../model/UserModel';
import { QuestionCard } from '../components/QuestionCard';
import { SearchBar } from '../components/SearchBar';
import { EmptyPlaceholder } from '../components/EmptyPlaceholder';
import { searchAll } from '../mock/MockData';
import { router } from '@kit.ArkUI';

@Entry
@Component
export struct SearchPage {
  @StorageLink('searchKeyword') searchKeyword: string = '';
  @State questions: QuestionModel[] = [];
  @State topics: TopicModel[] = [];
  @State users: UserModel[] = [];
  @State activeTab: number = 0;
  @State hasSearched: boolean = false;
  @State dataVersion: number = 0;
  @State searchHistory: string[] = ['高等数学', '考研', '实习', '编程', '食堂'];

  async aboutToAppear(): Promise<void> {
    // 如果从话题页或其他页面传入关键词，自动搜索
    if (this.searchKeyword) {
      await this.performSearch(this.searchKeyword);
    }
  }

  async performSearch(keyword: string): Promise<void> {
    if (!keyword.trim()) { return; }
    this.hasSearched = true;
    const results = await searchAll(keyword);
    this.questions = results.questions;
    this.topics = results.topics;
    this.users = results.users;
    this.dataVersion++;
    if (!this.searchHistory.includes(keyword)) {
      const newHistory: string[] = [keyword];
      for (const h of this.searchHistory) {
        if (newHistory.length < 10) { newHistory.push(h); }
      }
      this.searchHistory = newHistory;
    }
  }

  build() {
    Column() {
      SearchBar({
        showBack: true,
        placeholder: '搜索问题、话题、用户...',
        onChange: (value: string) => {
          this.searchKeyword = value;
        },
        onSubmit: (value: string) => {
          this.performSearch(value);
        },
        onBack: () => {
          router.back();
        }
      })

      if (!this.hasSearched) {
        Column() {
          Row() {
            Text('搜索历史').fontSize(15).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
            Blank()
            Text('清空').fontSize(13).fontColor('#999')
              .onClick(() => { this.searchHistory = []; })
          }.width('100%').padding({ left: 16, right: 16, top: 16 })

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.searchHistory, (keyword: string) => {
              Text(keyword)
                .fontSize(13).fontColor('#666')
                .backgroundColor('#F0F0F0').borderRadius(14)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .margin({ right: 8, bottom: 8 })
                .onClick(() => {
                  this.searchKeyword = keyword;
                  this.performSearch(keyword);
                })
            })
          }.padding({ left: 16, right: 16, top: 12 })
        }.width('100%')
      } else {
        Row() {
          this.ResultTab('综合', 0)
          this.ResultTab('问题', 1)
          this.ResultTab('话题', 2)
          this.ResultTab('用户', 3)
        }
        .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })

        Scroll() {
          Column() {
            if (this.activeTab === 0 || this.activeTab === 1) {
              if (this.questions.length === 0 && this.activeTab === 1) {
                EmptyPlaceholder({ icon: '🔍', title: '没有找到相关问题' })
              } else {
                ForEach(this.questions.slice(0, this.activeTab === 0 ? 10 : 100), (q: QuestionModel) => {
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
            }

            if (this.activeTab === 0 || this.activeTab === 2) {
              if (this.topics.length === 0 && this.activeTab === 2) {
                EmptyPlaceholder({ icon: '🏷️', title: '没有找到相关话题' })
              } else {
                ForEach(this.topics.slice(0, this.activeTab === 0 ? 6 : 100), (t: TopicModel) => {
                  Row() {
                    Text(t.icon).fontSize(24).margin({ right: 10 })
                    Column() {
                      Text(t.name).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1A1A1A')
                      Text(`${t.questionCount} 个问题 · ${t.followerCount} 关注`)
                        .fontSize(12).fontColor('#999')
                    }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                    Text(t.isFollowed ? '已关注' : '关注')
                      .fontSize(13).fontColor(t.isFollowed ? '#999' : '#4A90D9')
                  }
                  .width('100%').padding(12).backgroundColor(Color.White).borderRadius(10)
                  .margin({ left: 16, right: 16, top: 4, bottom: 4 })
                  .onClick(() => {
                    AppStorage.setOrCreate('searchKeyword', t.name);
                    this.performSearch(t.name);
                  })
                }, (t: TopicModel) => t.id)
              }
            }

            if (this.activeTab === 0 || this.activeTab === 3) {
              if (this.users.length === 0 && this.activeTab === 3) {
                EmptyPlaceholder({ icon: '👥', title: '没有找到相关用户' })
              } else {
                ForEach(this.users.slice(0, this.activeTab === 0 ? 5 : 100), (u: UserModel) => {
                  Row() {
                    Text(u.name.charAt(0))
                      .fontSize(20).fontColor(Color.White).fontWeight(FontWeight.Bold)
                      .width(44).height(44).borderRadius(22)
                      .backgroundColor('#4A90D9').textAlign(TextAlign.Center)
                    Column() {
                      Text(u.name).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1A1A1A')
                      Text(`${u.college} · ${u.major}`).fontSize(12).fontColor('#999')
                    }
                    .alignItems(HorizontalAlign.Start).margin({ left: 10 }).layoutWeight(1)
                    Text(`Lv.${Math.floor(u.reputation / 100) + 1}`).fontSize(12).fontColor('#FF9500')
                  }
                  .width('100%').padding(12).backgroundColor(Color.White).borderRadius(10)
                  .margin({ left: 16, right: 16, top: 4, bottom: 4 })
                  .onClick(() => {
                    AppStorage.setOrCreate('targetUserId', u.id);
                    router.pushUrl({ url: 'pages/UserProfilePage' });
                  })
                }, (u: UserModel) => u.id)
              }
            }
          }.width('100%')
        }.width('100%').layoutWeight(1).scrollBar(BarState.Off)
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F6FA')
  }

  @Builder
  ResultTab(label: string, index: number) {
    Text(label)
      .fontSize(14)
      .fontWeight(this.activeTab === index ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.activeTab === index ? '#4A90D9' : '#666')
      .padding({ bottom: 6 })
      .border({ width: this.activeTab === index ? { bottom: 2 } : { bottom: 0 }, color: '#4A90D9' })
      .margin({ right: 20 })
      .onClick(() => { this.activeTab = index; })
  }
}
