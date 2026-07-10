/**
 * 主入口页面 - Tab 导航容器
 * 包含首页、话题广场、发布、通知、个人中心五个 Tab
 */
import { HomePage } from './shouye';
import { TopicSquarePage } from '../discover/huatiguangchang';
import { PostQuestionPage } from '../question/tiwen';
import { NotificationPage } from '../discover/tongzhi';
import { ProfilePage } from '../user/gerenzhongxin';
import { UserViewModel } from '../../viewmodel/UserViewModel';
import { UserModel } from '../../model/UserModel';
import { getStore } from '../../store/DataStore';
import * as NotificationApi from '../../api/NotificationApi';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @StorageLink('currentUser') currentUser: object | null = null;
  @StorageLink('currentUserId') currentUserId: string = '';
  @StorageLink('switchToTab') switchToTab: number = -1;
  @State unreadCount: number = 0;
  @State isLoggedIn: boolean = false;
  @State isCheckingAuth: boolean = true;  // 启动时检查登录状态
  private userVM: UserViewModel = UserViewModel.getInstance();

  async aboutToAppear(): Promise<void> {
    // 1. 先尝试从本地恢复登录状态
    const restored: boolean = await this.userVM.tryRestoreSession();

    if (restored && this.currentUserId) {
      // 恢复成功，直接进入首页
      this.isLoggedIn = true;
      this.isCheckingAuth = false;

      // 2. 同步当前用户到内存 store（先于加载问题，确保问题能找到author）
      const store = getStore();
      if (this.currentUser) {
        store.syncUserFromModel(this.currentUser as UserModel);
      }

      // 3. 从后端加载问题数据到内存 store
      await store.loadFromDb();

      // 加载未读通知数（后端 API）
      const countRes = await NotificationApi.getUnreadCount(this.currentUserId);
      if (countRes.code === 0 && countRes.data !== undefined) {
        this.unreadCount = countRes.data;
      }
    } else {
      // 2. 未登录，跳转到登录页
      this.isCheckingAuth = false;
      router.replaceUrl({ url: 'pages/login-register/denglu' });
    }
  }

  onPageShow(): void {
    // 响应切Tab请求
    if (this.switchToTab >= 0) {
      this.currentIndex = this.switchToTab;
      AppStorage.setOrCreate('switchToTab', -1);
    }
    // 每次显示页面时刷新未读通知数（后端 API）
    if (this.currentUserId) {
      NotificationApi.getUnreadCount(this.currentUserId).then((res) => {
        if (res.code === 0 && res.data !== undefined) {
          this.unreadCount = res.data;
        }
      });
    }
  }

  build() {
    if (this.isCheckingAuth) {
      // 启动时检查登录状态
      Column() {
        LoadingProgress()
          .width(36)
          .height(36)
        Text('正在加载...')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 12 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else if (!this.isLoggedIn) {
      // 未登录 - 跳转中（通常不会经过这里，已在 aboutToAppear 中跳转）
      Column() {
        LoadingProgress()
          .width(36)
          .height(36)
        Text('正在跳转登录...')
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
        // 切换到"我的"页面时触发刷新
        if (index === 4) {
          const currentTrigger: number = AppStorage.get<number>('profileRefreshTrigger') || 0;
          AppStorage.setOrCreate('profileRefreshTrigger', currentTrigger + 1);
        }
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
