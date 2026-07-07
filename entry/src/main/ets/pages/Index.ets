/**
 * 主入口页面 - Tab 导航容器
 * 包含首页、话题广场、发布、通知、个人中心五个 Tab
 */
import { HomePage } from './HomePage';
import { TopicSquarePage } from './TopicSquarePage';
import { PostQuestionPage } from './PostQuestionPage';
import { NotificationPage } from './NotificationPage';
import { ProfilePage } from './ProfilePage';
import { UserViewModel } from '../viewmodel/UserViewModel';
import { getUnreadNotificationCount } from '../mock/MockData';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @StorageLink('currentUser') currentUser: object | null = null;
  @StorageLink('currentUserId') currentUserId: string = '';
  @StorageLink('switchToTab') switchToTab: number = -1;
  @State unreadCount: number = 0;
  @State isLoggedIn: boolean = false;
  private userVM: UserViewModel = UserViewModel.getInstance();

  async aboutToAppear(): Promise<void> {
    // 自动登录
    if (!this.currentUserId) {
      const user = await this.userVM.login();
      if (user) {
        this.isLoggedIn = true;
      }
    } else {
      this.isLoggedIn = true;
    }

    // 加载未读通知数
    if (this.currentUserId) {
      this.unreadCount = await getUnreadNotificationCount(this.currentUserId);
    }
  }

  onPageShow(): void {
    // 响应切Tab请求
    if (this.switchToTab >= 0) {
      this.currentIndex = this.switchToTab;
      AppStorage.setOrCreate('switchToTab', -1);
    }
    // 每次显示页面时刷新未读通知数
    if (this.currentUserId) {
      getUnreadNotificationCount(this.currentUserId).then((count: number) => {
        this.unreadCount = count;
      });
    }
  }

  build() {
    if (!this.isLoggedIn) {
      // 未登录时显示登录页（简化处理：自动登录，几乎不会经过这里）
      Column() {
        LoadingProgress()
          .width(36)
          .height(36)
        Text('正在登录...')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 12 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else {
      Tabs({ index: this.currentIndex, barPosition: BarPosition.End }) {
        TabContent() {
          HomePage()
        }
        .tabBar(this.TabBarItem('首页', '🏠', 0))

        TabContent() {
          TopicSquarePage()
        }
        .tabBar(this.TabBarItem('话题', '🏷️', 1))

        TabContent() {
          PostQuestionPage()
        }
        .tabBar(this.TabBarItem('', '➕', 2))

        TabContent() {
          NotificationPage()
        }
        .tabBar(this.TabBarItem('消息', '🔔', 3, this.unreadCount))

        TabContent() {
          ProfilePage()
        }
        .tabBar(this.TabBarItem('我的', '👤', 4))
      }
      .barHeight(56)
      .barBackgroundColor('#FFFFFF')
      .animationDuration(200)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  TabBarItem(label: string, icon: string, index: number, badgeCount?: number) {
    Column() {
      if (index === 2) {
        // 中间发布按钮特殊样式
        Text(icon)
          .fontSize(24)
          .width(44)
          .height(44)
          .borderRadius(22)
          .backgroundColor('#4A90D9')
          .textAlign(TextAlign.Center)
          .fontColor(Color.White)
      } else {
        Text(icon)
          .fontSize(20)

        if (label) {
          Text(label)
            .fontSize(10)
            .margin({ top: 2 })
            .fontColor(this.currentIndex === index ? '#4A90D9' : '#999')
        }

        // 红点角标
        if (badgeCount && badgeCount > 0) {
          Text(`${badgeCount > 99 ? '99+' : badgeCount}`)
            .fontSize(9)
            .fontColor(Color.White)
            .backgroundColor('#FF4757')
            .borderRadius(8)
            .width(16)
            .height(16)
            .textAlign(TextAlign.Center)
            .position({ x: 18, y: -4 })
        }
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ bottom: 4 })
  }
}
