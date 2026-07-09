/**
 * 关注/粉丝列表页面
 * 根据 mode 参数显示"我关注的用户"或"关注我的用户"
 */
import { UserModel } from '../model/UserModel';
import {
  getFollowingUsers,
  getFollowerUsers,
  toggleFollowUser,
  isFollowingUser,
  getStore
} from '../mock/MockData';
import { router } from '@kit.ArkUI';

@Entry
@Component
export struct FollowListPage {
  @State mode: string = 'following'; // 'following' | 'followers'
  @State userId: string = '';
  @StorageLink('currentUserId') currentUserId: string = '';
  @State users: UserModel[] = [];
  @State isLoading: boolean = true;
  @State title: string = '';
  @State followingMap: Map<string, boolean> = new Map();

  async aboutToAppear(): Promise<void> {
    // 从路由参数获取 mode 和 userId
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.mode = (params['mode'] as string) || 'following';
      this.userId = (params['userId'] as string) || '';
    }

    if (this.mode === 'following') {
      this.title = '我关注的';
    } else {
      this.title = '我的粉丝';
    }

    await this.loadUsers();
  }

  async loadUsers(): Promise<void> {
    this.isLoading = true;
    try {
      if (this.mode === 'following') {
        this.users = await getFollowingUsers(this.userId);
      } else {
        this.users = await getFollowerUsers(this.userId);
      }
      // 检查每个用户的关注状态
      if (this.currentUserId) {
        for (const u of this.users) {
          if (u.id !== this.currentUserId) {
            const following: boolean = await isFollowingUser(this.currentUserId, u.id);
            this.followingMap.set(u.id, following);
          }
        }
      }
    } catch (e) {
      this.users = [];
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor('#333')
          .onClick(() => { router.back(); })
        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text(`${this.users.length}人`)
          .fontSize(13)
          .fontColor('#999')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(Color.White)

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(36).height(36)
          Text('加载中...').fontSize(14).fontColor('#999').margin({ top: 12 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.users.length === 0) {
        Column() {
          Text(this.mode === 'following' ? '😶' : '🥺')
            .fontSize(48)
          Text(this.mode === 'following' ? '还没有关注任何用户' : '还没有粉丝')
            .fontSize(14)
            .fontColor('#999')
            .margin({ top: 12 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.users, (user: UserModel) => {
            ListItem() {
              this.UserCard(user)
            }
          }, (user: UserModel) => user.id)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F5F6FA')
        .padding({ top: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder
  UserCard(user: UserModel) {
    Row() {
      // 头像（双击进入主页）
      Text(user.name.charAt(0))
        .fontSize(22)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .width(50)
        .height(50)
        .borderRadius(25)
        .backgroundColor(this.getAvatarColor(user.name))
        .textAlign(TextAlign.Center)
        .gesture(
          TapGesture({ count: 2 })
            .onAction(() => {
              AppStorage.setOrCreate('targetUserId', user.id);
              router.pushUrl({
                url: 'pages/user/UserProfilePage',
                params: { userId: user.id }
              });
            })
        )

      // 用户信息
      Column() {
        Row() {
          Text(user.name)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .maxLines(1)

          if (user.reputation > 500) {
            Text('达人')
              .fontSize(9)
              .fontColor('#FF9500')
              .backgroundColor('#FFF3E0')
              .borderRadius(4)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .margin({ left: 6 })
          }
        }

        Text(user.bio || '这个人很懒，什么都没写...')
          .fontSize(12)
          .fontColor('#999')
          .maxLines(1)
          .margin({ top: 3 })

        Text(`${user.college} · ${user.major}`)
          .fontSize(11)
          .fontColor('#BBB')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)

      // 关注/取关按钮（不显示自己的按钮）
      if (user.id !== this.currentUserId) {
        Button(this.followingMap.get(user.id) ? '已关注' : '+ 关注')
          .fontSize(12)
          .fontColor(this.followingMap.get(user.id) ? '#999' : '#4A90D9')
          .backgroundColor(this.followingMap.get(user.id) ? '#F5F5F5' : Color.White)
          .borderRadius(14)
          .height(28)
          .padding({ left: 12, right: 12 })
          .border({
            width: 1,
            color: this.followingMap.get(user.id) ? '#DDD' : '#4A90D9',
            style: BorderStyle.Solid
          })
          .onClick(async () => {
            await toggleFollowUser(user.id, this.currentUserId);
            const isNowFollowing = !this.followingMap.get(user.id);
            this.followingMap.set(user.id, isNowFollowing);
            // 刷新 currentUser 以同步关注数到"我的"页
            const store = getStore();
            const refreshed = store.users.find(u => u.id === this.currentUserId);
            if (refreshed) {
              AppStorage.setOrCreate('currentUser', refreshed);
            }
          })
      } else {
        Text('›')
          .fontSize(22)
          .fontColor('#CCC')
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .margin({ bottom: 1 })
    .onClick(() => {
      // 单击跳转到用户主页
      AppStorage.setOrCreate('targetUserId', user.id);
      router.pushUrl({
        url: 'pages/user/UserProfilePage',
        params: { userId: user.id }
      });
    })
  }

  private getAvatarColor(name: string): string {
    const colors = ['#4A90D9', '#E8634A', '#5CB85C', '#F0AD4E', '#9B59B6',
      '#1ABC9C', '#E91E63', '#FF9800', '#3F51B5', '#FF5722'];
    if (!name) { return colors[0]; }
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = name.charCodeAt(i) + ((hash << 5) - hash);
    }
    return colors[Math.abs(hash) % colors.length];
  }
}
