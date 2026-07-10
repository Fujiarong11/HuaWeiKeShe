/**
 * 关注/粉丝列表页面
 * 根据 mode 参数显示"我关注的用户"或"关注我的用户"
 * 数据走后端 API，本地内存仅作降级兜底
 */
import { UserModel } from '../../model/UserModel';
import * as UserApi from '../../api/UserApi';
import type { UserResponse } from '../../api/UserApi';
import { UserViewModel } from '../../viewmodel/UserViewModel';
import {
  getFollowingUsers,
  getFollowerUsers,
  toggleFollowUser,
  isFollowingUser
} from '../../store/DataStore';
import { router } from '@kit.ArkUI';

@Entry
@Component
export struct FollowListPage {
  @State mode: string = 'following'; // 'following' | 'followers'
  @State userId: string = '';
  @StorageLink('currentUserId') currentUserId: string = '';
  @StorageLink('currentUser') currentUser: UserModel | null = null;
  @State users: UserModel[] = [];
  @State isLoading: boolean = true;
  @State title: string = '';
  @State followingMap: Map<string, boolean> = new Map();
  private userVM: UserViewModel = UserViewModel.getInstance();

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
      // 优先走后端 API
      const isSeedUser = this.userId.startsWith('u_seed_') || this.userId.startsWith('seed_');
      const useBackend = /^\d+$/.test(this.userId) && !isSeedUser;

      if (useBackend) {
        const res = this.mode === 'following'
          ? await UserApi.getFollowingList(this.userId)
          : await UserApi.getFollowerList(this.userId);

        if (res.code === 0 && res.data) {
          const list: object[] = res.data as object[];
          const userList: UserModel[] = [];
          for (const item of list) {
            const resp: UserResponse = item as UserResponse;
            const u: UserModel = new UserModel();
            u.id = String(resp.id);
            u.phone = resp.phone || '';
            u.name = resp.username || resp.name || '';
            u.avatar = resp.avatar || '';
            u.bio = resp.bio || '';
            u.college = resp.college || '';
            u.major = resp.major || '';
            u.grade = resp.grade || '';
            u.reputation = resp.reputation || 0;
            u.acceptedCount = resp.acceptedCount || 0;
            u.totalAnswers = resp.totalAnswers || 0;
            u.totalQuestions = resp.totalQuestions || 0;
            u.followerCount = resp.followerCount || 0;
            u.followingCount = resp.followingCount || 0;
            u.createdAt = resp.createdAt || '';
            userList.push(u);
          }
          this.users = userList;
          console.info(`[FollowListPage] 后端返回 ${userList.length} 个用户, mode=${this.mode}`);

          // 检查每个用户的关注状态（粉丝列表需要检查是否互相关注）
          if (this.currentUserId) {
            for (const u of this.users) {
              if (u.id !== this.currentUserId) {
                // 关注列表里的都是已关注的；粉丝列表需要查是否已互关
                if (this.mode === 'following') {
                  this.followingMap.set(u.id, true);
                } else {
                  const followRes = await UserApi.isFollowing(this.currentUserId, u.id);
                  const isFollowed: boolean = followRes.code === 0 && String(followRes.data) === 'true';
                  this.followingMap.set(u.id, isFollowed);
                }
              }
            }
          }
        } else {
          // 后端返回异常，打印日志并降级到本地内存
          console.error(`[FollowListPage] 后端API异常: code=${res.code}, msg=${res.msg}, userId=${this.userId}, mode=${this.mode}`);
          await this.loadFromLocalMemory();
        }
      } else {
        // 种子用户，走本地内存
        console.info(`[FollowListPage] 种子用户走本地内存: userId=${this.userId}, isSeedUser=${isSeedUser}`);
        await this.loadFromLocalMemory();
      }
    } catch (e) {
      console.error(`[FollowListPage] 网络异常: ${e}, userId=${this.userId}, mode=${this.mode}`);
      await this.loadFromLocalMemory();
    } finally {
      this.isLoading = false;
    }
  }

  private async loadFromLocalMemory(): Promise<void> {
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
    } catch (_e) {
      this.users = [];
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
                url: 'pages/user/tarenzhuye',
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
            const wasFollowing = this.followingMap.get(user.id) ?? false;
            // 纯后端操作
            const isRealUser = /^\d+$/.test(user.id) && /^\d+$/.test(this.currentUserId);
            if (isRealUser) {
              const ok: boolean = await this.userVM.toggleFollow(user.id);
              if (ok) {
                this.followingMap.set(user.id, !wasFollowing);
              }
            } else {
              // 种子用户走本地内存
              await toggleFollowUser(user.id, this.currentUserId);
              this.followingMap.set(user.id, !wasFollowing);
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
        url: 'pages/user/tarenzhuye',
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
