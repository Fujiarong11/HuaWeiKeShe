/**
 * 用户 ViewModel
 * 注册/登录走 Spring Boot 后端 HTTP API
 * 问题/回答仍从本地 DB 加载（后端暂未支持）
 */
import { UserModel } from '../model/UserModel';
import { QuestionModel, QuestionStatus } from '../model/QuestionModel';
import { AnswerModel } from '../model/AnswerModel';
import { BasicDataSource } from '../common/datasource/BasicDataSource';
import { AuthService } from '../services/AuthService';
import * as UserApi from '../api/UserApi';
import * as QuestionApi from '../api/QuestionApi';
import type { UserResponse } from '../api/UserApi';
import { router } from '@kit.ArkUI';
import {
  getUserById,
  getStore
} from '../mock/MockData';

@Observed
export class UserViewModel {
  private static instance: UserViewModel;

  currentUser: UserModel | null = null;
  isLoading: boolean = false;
  isLoggedIn: boolean = false;
  private authService: AuthService = AuthService.getInstance();

  // 他人主页数据
  viewingUser: UserModel | null = null;
  userQuestions: BasicDataSource<QuestionModel> = new BasicDataSource();
  userAnswers: BasicDataSource<AnswerModel> = new BasicDataSource();

  // 用户列表（关注/粉丝）
  userListDataSource: BasicDataSource<UserModel> = new BasicDataSource();

  static getInstance(): UserViewModel {
    if (!UserViewModel.instance) {
      UserViewModel.instance = new UserViewModel();
    }
    return UserViewModel.instance;
  }

  private constructor() {}

  /**
   * 用户登录 - 通过 AuthService 完成认证（手机号 + 密码）
   */
  async login(phone: string, password: string): Promise<UserModel | null> {
    this.isLoading = true;
    try {
      const result = await this.authService.login(phone, password);
      if (result.success && result.user) {
        this.currentUser = result.user;
        this.isLoggedIn = true;
        // 同步到 AppStorage
        AppStorage.setOrCreate('currentUser', result.user);
        AppStorage.setOrCreate('currentUserId', result.user.id);
        // 同步用户到内存 store
        this.syncUserToStore(result.user);
        return result.user;
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 用户注册 - 通过 AuthService 完成注册并自动登录（用户名 + 手机号 + 密码）
   */
  async register(username: string, phone: string, password: string): Promise<UserModel | null> {
    this.isLoading = true;
    try {
      const result = await this.authService.register(username, phone, password);
      if (result.success && result.user) {
        this.currentUser = result.user;
        this.isLoggedIn = true;
        // 同步到 AppStorage
        AppStorage.setOrCreate('currentUser', result.user);
        AppStorage.setOrCreate('currentUserId', result.user.id);
        // 同步用户到内存 store
        this.syncUserToStore(result.user);
        return result.user;
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 尝试从本地恢复登录状态
   */
  async tryRestoreSession(): Promise<boolean> {
    try {
      const user = await this.authService.tryRestoreSession();
      if (user) {
        this.currentUser = user;
        this.isLoggedIn = true;
        AppStorage.setOrCreate('currentUser', user);
        AppStorage.setOrCreate('currentUserId', user.id);
        return true;
      }
    } catch (e) {
      // 恢复失败
    }
    return false;
  }

  /**
   * 登出
   */
  async logout(): Promise<void> {
    await this.authService.logout();
    this.currentUser = null;
    this.isLoggedIn = false;
    AppStorage.setOrCreate('currentUser', null);
    AppStorage.setOrCreate('currentUserId', '');
    // 跳转到登录页并清空页面栈
    router.clear();
    router.replaceUrl({ url: 'pages/login-register/LoginPage' });
  }

  /**
   * 加载用户主页（走后端 API，不依赖本地内存 store）
   */
  async loadUserProfile(userId: string): Promise<void> {
    this.isLoading = true;
    this.viewingUser = null;
    try {
      // 纯后端请求
      if (/^\d+$/.test(userId)) {
        const res = await UserApi.getUserById(userId);
        if (res.code === 0 && res.data) {
          const resp: UserResponse = res.data as UserResponse;
          const user: UserModel = new UserModel();
          user.id = String(resp.id);
          user.phone = resp.phone || '';
          user.name = resp.username || resp.name || '';
          user.avatar = resp.avatar || '';
          user.bio = resp.bio || '';
          user.college = resp.college || '';
          user.major = resp.major || '';
          user.grade = resp.grade || '';
          user.reputation = resp.reputation || 0;
          user.acceptedCount = resp.acceptedCount || 0;
          user.totalAnswers = resp.totalAnswers || 0;
          user.totalQuestions = resp.totalQuestions || 0;
          user.followerCount = resp.followerCount || 0;
          user.followingCount = resp.followingCount || 0;
          user.createdAt = resp.createdAt || '';
          this.viewingUser = user;

          // 从后端加载该用户的问题列表
          const qRes = await QuestionApi.getUserQuestions(userId);
          if (qRes.code === 0 && qRes.data) {
            const list: object[] = qRes.data as object[];
            const questions: QuestionModel[] = [];
            for (const item of list) {
              const r = item as Record<string, Object>;
              const q: QuestionModel = new QuestionModel();
              q.id = String(r['id'] || '');
              q.title = String(r['title'] || '');
              q.content = String(r['content'] || '');
              q.author = user;
              q.topicIds = (r['topicIds'] as string[]) || [];
              q.status = String(r['status']) === 'RESOLVED' ? QuestionStatus.RESOLVED : QuestionStatus.OPEN;
              q.viewCount = Number(r['viewCount']) || 0;
              q.likeCount = Number(r['likeCount']) || 0;
              q.followerCount = Number(r['followerCount']) || 0;
              q.answerCount = Number(r['answerCount']) || 0;
              q.createdAt = String(r['createdAt'] || '');
              q.updatedAt = String(r['updatedAt'] || '');
              questions.push(q);
            }
            this.userQuestions.reloadData(questions);
          }
          this.userAnswers.reloadData([]);
          return;
        }
      }
      // 种子用户 fallback（走本地内存）
      const storeUser: UserModel | undefined = await getUserById(userId);
      if (storeUser) {
        this.viewingUser = storeUser;
        this.userQuestions.reloadData([]);
        this.userAnswers.reloadData([]);
      }
    } catch (e) {
      console.error('loadUserProfile failed: ' + e);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 确保 currentUser 不为空（优先用自身，fallback 到 AppStorage）
   */
  private ensureCurrentUser(): UserModel | null {
    if (this.currentUser) { return this.currentUser; }
    const fromApp = AppStorage.get<UserModel>('currentUser');
    if (fromApp) {
      this.currentUser = fromApp;
      return fromApp;
    }
    return null;
  }

  /**
   * 关注/取关用户 — 纯后端操作，不碰本地内存 store
   */
  async toggleFollow(targetUserId: string): Promise<boolean> {
    const user = this.ensureCurrentUser();
    if (!user) {
      console.error('[toggleFollow] currentUser is null, cannot follow');
      return false;
    }
    const currentUserId = user.id;

    // 从后端查询当前关注状态
    const checkRes = await UserApi.isFollowing(currentUserId, targetUserId);
    const isFollowed: boolean = checkRes.code === 0 && String(checkRes.data) === 'true';

    // 调用后端 API
    const apiRes = isFollowed
      ? await UserApi.unfollowUser(currentUserId, targetUserId)
      : await UserApi.followUser(currentUserId, targetUserId);

    if (apiRes.code !== 0) {
      console.error('[toggleFollow] 后端返回失败: ' + (apiRes.msg || '未知错误'));
      return false;
    }

    // 从后端刷新计数到 AppStorage（不碰本地 store）
    await this.refreshUserCounts();
    return true;
  }

  /**
   * 加载关注/粉丝列表（走后端）
   */
  async loadFollowList(type: 'followers' | 'following', userId: string): Promise<void> {
    const res = type === 'following'
      ? await UserApi.getFollowingList(userId)
      : await UserApi.getFollowerList(userId);

    if (res.code === 0 && res.data) {
      const list: object[] = res.data as object[];
      const users: UserModel[] = [];
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
        users.push(u);
        // 同步到内存 store
        getStore().syncUserFromModel(u);
      }
      this.userListDataSource.reloadData(users);
    }
  }

  /**
   * 刷新用户关注计数（从后端拉最新数据，创建新对象触发 UI 刷新）
   */
  private async refreshUserCounts(): Promise<void> {
    if (!this.currentUser) { return; }
    // 从后端刷新当前用户数据
    const res = await UserApi.getUserById(this.currentUser.id);
    if (res.code === 0 && res.data) {
      const resp: UserResponse = res.data as UserResponse;
      // 创建新对象引用，触发 @StorageLink 变更检测
      const updated: UserModel = new UserModel();
      updated.id = this.currentUser.id;
      updated.phone = this.currentUser.phone;
      updated.name = this.currentUser.name;
      updated.avatar = this.currentUser.avatar;
      updated.bio = this.currentUser.bio;
      updated.college = this.currentUser.college;
      updated.major = this.currentUser.major;
      updated.grade = this.currentUser.grade;
      updated.reputation = this.currentUser.reputation;
      updated.acceptedCount = this.currentUser.acceptedCount;
      updated.totalAnswers = this.currentUser.totalAnswers;
      updated.totalQuestions = this.currentUser.totalQuestions;
      // 从后端取最新的计数
      updated.followerCount = resp.followerCount || 0;
      updated.followingCount = resp.followingCount || 0;
      updated.createdAt = this.currentUser.createdAt;
      this.currentUser = updated;
      AppStorage.setOrCreate('currentUser', updated);
    }
    // 刷新查看中的用户
    if (this.viewingUser) {
      const vRes = await UserApi.getUserById(this.viewingUser.id);
      if (vRes.code === 0 && vRes.data) {
        const vResp: UserResponse = vRes.data as UserResponse;
        this.viewingUser.followerCount = vResp.followerCount || 0;
        this.viewingUser.followingCount = vResp.followingCount || 0;
      }
    }
  }

  /**
   * 更新当前用户信息
   */
  updateCurrentUser(fields: UserModel): void {
    if (!this.currentUser) { return; }
    this.currentUser.name = fields.name || this.currentUser.name;
    this.currentUser.bio = fields.bio || this.currentUser.bio;
    this.currentUser.avatar = fields.avatar || this.currentUser.avatar;
    this.currentUser.college = fields.college || this.currentUser.college;
    this.currentUser.major = fields.major || this.currentUser.major;
    AppStorage.setOrCreate('currentUser', this.currentUser);
  }

  /**
   * 将用户同步到内存 store，确保后续发帖/回答能找到 author
   */
  private syncUserToStore(user: UserModel): void {
    getStore().syncUserFromModel(user);
  }
}
