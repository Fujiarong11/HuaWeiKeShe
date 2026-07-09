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
import { DatabaseHelper, QuestionRow, AnswerRow } from '../data/DatabaseHelper';
import * as UserApi from '../api/UserApi';
import type { ApiResult, UserResponse } from '../api/UserApi';
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
   * 加载用户主页（他人或自己）
   */
  async loadUserProfile(userId: string): Promise<void> {
    this.isLoading = true;
    try {
      const user: UserModel | undefined = await getUserById(userId);
      if (user) {
        this.viewingUser = user;
        // 从 DB 加载该用户的提问和回答
        const dbQuestions: QuestionRow[] = await DatabaseHelper.queryQuestionsByAuthor(userId);
        const dbAnswers: AnswerRow[] = await DatabaseHelper.queryAnswersByAuthor(userId);

        const questions: QuestionModel[] = [];
        for (const row of dbQuestions) {
          const q: QuestionModel = new QuestionModel();
          q.id = row.id;
          q.title = row.title;
          q.content = row.content;
          q.author = user;
          try {
            const parsed: Object = JSON.parse(row.topicIds) as Object;
            q.topicIds = parsed as string[];
          } catch (_e) {
            q.topicIds = [];
          }
          q.status = row.status === 'RESOLVED' ? QuestionStatus.RESOLVED : QuestionStatus.OPEN;
          q.viewCount = row.viewCount;
          q.likeCount = row.likeCount;
          q.followerCount = row.followerCount;
          q.answerCount = row.answerCount;
          q.createdAt = row.createdAt;
          q.updatedAt = row.updatedAt;
          questions.push(q);
        }

        const answers: AnswerModel[] = [];
        for (const row of dbAnswers) {
          const a: AnswerModel = new AnswerModel();
          a.id = row.id;
          a.questionId = row.questionId;
          a.content = row.content;
          a.author = user;
          a.isAccepted = row.isAccepted === 1;
          a.likeCount = row.likeCount;
          a.commentCount = row.commentCount;
          a.createdAt = row.createdAt;
          answers.push(a);
        }

        this.userQuestions.reloadData(questions);
        this.userAnswers.reloadData(answers);
      }
    } catch (e) {
      // 加载失败
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 关注/取关用户（走后端）
   */
  async toggleFollow(targetUserId: string): Promise<void> {
    if (!this.currentUser) { return; }
    // 先检查当前状态
    const checkRes: ApiResult = await UserApi.isFollowing(this.currentUser.id, targetUserId);
    const isFollowed: boolean = checkRes.code === 0 && String(checkRes.data) === 'true';

    if (isFollowed) {
      await UserApi.unfollowUser(this.currentUser.id, targetUserId);
    } else {
      await UserApi.followUser(this.currentUser.id, targetUserId);
    }

    // 刷新当前用户和查看用户的计数
    await this.refreshUserCounts();
  }

  /**
   * 加载关注/粉丝列表（走后端）
   */
  async loadFollowList(type: 'followers' | 'following', userId: string): Promise<void> {
    const res: ApiResult = type === 'following'
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
   * 刷新用户关注计数
   */
  private async refreshUserCounts(): Promise<void> {
    if (!this.currentUser) { return; }
    // 从后端刷新当前用户数据
    const res: ApiResult = await UserApi.getUserById(this.currentUser.id);
    if (res.code === 0 && res.data) {
      const resp: UserResponse = res.data as UserResponse;
      this.currentUser.followerCount = resp.followerCount || 0;
      this.currentUser.followingCount = resp.followingCount || 0;
      AppStorage.setOrCreate('currentUser', this.currentUser);
      getStore().syncUserFromModel(this.currentUser);
    }
    // 刷新查看中的用户
    if (this.viewingUser) {
      const vRes: ApiResult = await UserApi.getUserById(this.viewingUser.id);
      if (vRes.code === 0 && vRes.data) {
        const vResp: UserResponse = vRes.data as UserResponse;
        this.viewingUser.followerCount = vResp.followerCount || 0;
        this.viewingUser.followingCount = vResp.followingCount || 0;
        getStore().syncUserFromModel(this.viewingUser);
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
