/**
 * 用户 ViewModel
 * 处理用户登录、个人主页、关注粉丝等逻辑
 */
import { UserModel } from '../model/UserModel';
import { QuestionModel } from '../model/QuestionModel';
import { AnswerModel } from '../model/AnswerModel';
import { BasicDataSource } from '../common/datasource/BasicDataSource';
import {
  getCurrentUser,
  getUserById,
  toggleFollowUser,
  getStore
} from '../mock/MockData';

@Observed
export class UserViewModel {
  private static instance: UserViewModel;

  currentUser: UserModel | null = null;
  isLoading: boolean = false;
  isLoggedIn: boolean = false;

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
   * 模拟登录 - 直接使用默认用户
   */
  async login(): Promise<UserModel | null> {
    this.isLoading = true;
    try {
      const user = await getCurrentUser();
      this.currentUser = user;
      this.isLoggedIn = true;
      // 同步到 AppStorage
      AppStorage.setOrCreate('currentUser', user);
      AppStorage.setOrCreate('currentUserId', user.id);
      return user;
    } catch (e) {
      return null;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 登出
   */
  logout(): void {
    this.currentUser = null;
    this.isLoggedIn = false;
    AppStorage.setOrCreate('currentUser', null);
    AppStorage.setOrCreate('currentUserId', '');
  }

  /**
   * 加载用户主页
   */
  async loadUserProfile(userId: string): Promise<void> {
    this.isLoading = true;
    try {
      const user = await getUserById(userId);
      if (user) {
        this.viewingUser = user;
        // 加载该用户的问题和回答
        const store = getStore();
        const questions = store.questions.filter(q => q.author.id === userId);
        const answers = store.answers.filter(a => a.author.id === userId);
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
   * 关注/取关用户
   */
  async toggleFollow(targetUserId: string): Promise<void> {
    if (!this.currentUser) { return; }
    const updated = await toggleFollowUser(targetUserId, this.currentUser.id);
    if (updated) {
      this.viewingUser = updated;
    }
  }

  /**
   * 加载关注/粉丝列表
   */
  async loadFollowList(type: 'followers' | 'following', userId: string): Promise<void> {
    const store = getStore();
    // 简化处理：随机返回一些用户
    const users = store.users.filter(u => u.id !== userId).slice(0, 15);
    this.userListDataSource.reloadData(users);
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
}
