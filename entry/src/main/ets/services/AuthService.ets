/**
 * 认证服务层
 * 使用本地数据库做注册登录
 */
import { preferences } from '@kit.ArkData';
import { UserModel, LoginResult, RegisterResult } from '../model/UserModel';
import * as UserApi from '../api/UserApi';
import type { ApiResult } from '../api/UserApi';
import type { UserRow } from '../data/DatabaseHelper';

const PREF_NAME = 'auth_preferences';
const KEY_USER_ID = 'auth_user_id';
const KEY_USER_INFO = 'auth_user_info';

const PASSWORD_MIN = 6;
const PASSWORD_MAX = 20;
const USERNAME_MIN = 2;
const USERNAME_MAX = 20;
const PHONE_REGEX = /^1[3-9]\d{9}$/;
const USERNAME_REGEX = /^[a-zA-Z0-9_一-龥]+$/;

/**
 * 会话持久化数据结构
 */
interface SessionData {
  id: string;
  name: string;
  avatar: string;
  bio: string;
  college: string;
  major: string;
  grade: string;
  reputation: string;
  acceptedCount: string;
  totalAnswers: string;
  totalQuestions: string;
  followerCount: string;
  followingCount: string;
  createdAt: string;
}

@Observed
export class AuthService {
  private static instance: AuthService;

  static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService();
    }
    return AuthService.instance;
  }

  private constructor() {}

  // ========== 输入校验 ==========

  validatePhone(phone: string): string | null {
    if (!phone || phone.trim().length === 0) return '手机号不能为空';
    if (!PHONE_REGEX.test(phone.trim())) return '请输入正确的手机号';
    return null;
  }

  validateUsername(username: string): string | null {
    if (!username || username.trim().length === 0) return '用户名不能为空';
    const t = username.trim();
    if (t.length < USERNAME_MIN) return `用户名至少${USERNAME_MIN}个字符`;
    if (t.length > USERNAME_MAX) return `用户名不能超过${USERNAME_MAX}个字符`;
    if (!USERNAME_REGEX.test(t)) return '用户名只能包含中文、英文、数字和下划线';
    return null;
  }

  validatePassword(password: string): string | null {
    if (!password || password.length === 0) return '密码不能为空';
    if (password.length < PASSWORD_MIN) return `密码至少${PASSWORD_MIN}个字符`;
    if (password.length > PASSWORD_MAX) return `密码不能超过${PASSWORD_MAX}个字符`;
    return null;
  }

  // ========== 注册 ==========

  async register(username: string, phone: string, password: string): Promise<RegisterResult> {
    const err = this.validateUsername(username) || this.validatePhone(phone) || this.validatePassword(password);
    if (err) return { success: false, error: err };

    try {
      // 检查手机号是否已注册
      const check: ApiResult = await UserApi.getUser(phone.trim());
      if (check.code === 0 && check.data) {
        return { success: false, error: '该手机号已被注册' };
      }

      // 写入本地数据库
      const userRow: UserRow = {
        id: phone.trim(),
        phone: phone.trim(),
        username: username.trim(),
        password: password,
        name: username.trim(),
        avatar: '',
        bio: '',
        college: '',
        major: '',
        grade: '',
        reputation: 0,
        acceptedCount: 0,
        totalAnswers: 0,
        totalQuestions: 0,
        followerCount: 0,
        followingCount: 0,
        followedTopicIds: '[]',
        createdAt: new Date().toISOString()
      };
      const res: ApiResult = await UserApi.userRegister(userRow);

      if (res.code === 0) {
        const user: UserModel = this.buildUserModel(userRow);
        await this.saveSession(user);
        AppStorage.setOrCreate('currentUser', user);
        AppStorage.setOrCreate('currentUserId', user.id);
        return { success: true, user };
      } else {
        return { success: false, error: (res.msg || '注册失败') as string };
      }
    } catch (e) {
      return { success: false, error: '注册失败，请稍后重试' };
    }
  }

  // ========== 登录 ==========

  async login(phone: string, password: string): Promise<LoginResult> {
    const err = this.validatePhone(phone) || this.validatePassword(password);
    if (err) return { success: false, error: err };

    try {
      // 从本地数据库查用户
      const res: ApiResult = await UserApi.getUser(phone.trim());

      if (res.code === 0 && res.data) {
        const row: UserRow = res.data as UserRow;
        // 本地明文密码比对
        if (row.password !== password) {
          return { success: false, error: '手机号或密码错误' };
        }
        const user: UserModel = this.buildUserModel(row);
        await this.saveSession(user);
        AppStorage.setOrCreate('currentUser', user);
        AppStorage.setOrCreate('currentUserId', user.id);
        return { success: true, user, token: `token_${Date.now()}` };
      } else {
        return { success: false, error: '手机号或密码错误' };
      }
    } catch (e) {
      return { success: false, error: '登录失败，请稍后重试' };
    }
  }

  // ========== 登出 ==========

  async logout(): Promise<void> {
    try {
      const pref = await preferences.getPreferences(getContext(), PREF_NAME);
      await pref.delete(KEY_USER_ID);
      await pref.delete(KEY_USER_INFO);
      await pref.flush();
    } catch (e) { /* ignore */ }
    AppStorage.setOrCreate('currentUser', null);
    AppStorage.setOrCreate('currentUserId', '');
  }

  // ========== 会话恢复 ==========

  async tryRestoreSession(): Promise<UserModel | null> {
    try {
      const pref = await preferences.getPreferences(getContext(), PREF_NAME);
      const savedId: string = pref.getSync(KEY_USER_ID, '') as string;
      const savedInfo: string = pref.getSync(KEY_USER_INFO, '') as string;

      if (savedId && savedInfo) {
        const data: SessionData = JSON.parse(savedInfo) as SessionData;
        const user: UserModel = this.buildUserFromSession(data);
        AppStorage.setOrCreate('currentUser', user);
        AppStorage.setOrCreate('currentUserId', user.id);
        return user;
      }
    } catch (e) { /* ignore */ }
    return null;
  }

  // ========== 内部工具 ==========

  private buildUserModel(row: UserRow): UserModel {
    const u: UserModel = new UserModel();
    u.id = row.id;
    u.name = row.username || row.name;
    u.avatar = row.avatar;
    u.bio = row.bio;
    u.college = row.college;
    u.major = row.major;
    u.grade = row.grade;
    u.reputation = row.reputation;
    u.acceptedCount = row.acceptedCount;
    u.totalAnswers = row.totalAnswers;
    u.totalQuestions = row.totalQuestions;
    u.followerCount = row.followerCount;
    u.followingCount = row.followingCount;
    u.createdAt = row.createdAt;
    return u;
  }

  private buildUserFromSession(data: SessionData): UserModel {
    const u: UserModel = new UserModel();
    u.id = data.id;
    u.name = data.name;
    u.avatar = data.avatar;
    u.bio = data.bio;
    u.college = data.college;
    u.major = data.major;
    u.grade = data.grade;
    u.reputation = parseInt(data.reputation) || 0;
    u.acceptedCount = parseInt(data.acceptedCount) || 0;
    u.totalAnswers = parseInt(data.totalAnswers) || 0;
    u.totalQuestions = parseInt(data.totalQuestions) || 0;
    u.followerCount = parseInt(data.followerCount) || 0;
    u.followingCount = parseInt(data.followingCount) || 0;
    u.createdAt = data.createdAt;
    return u;
  }

  private async saveSession(user: UserModel): Promise<void> {
    try {
      const pref = await preferences.getPreferences(getContext(), PREF_NAME);
      await pref.put(KEY_USER_ID, user.id);
      const sessionData: SessionData = {
        id: user.id, name: user.name, avatar: user.avatar,
        bio: user.bio, college: user.college, major: user.major,
        grade: user.grade, reputation: String(user.reputation),
        acceptedCount: String(user.acceptedCount),
        totalAnswers: String(user.totalAnswers),
        totalQuestions: String(user.totalQuestions),
        followerCount: String(user.followerCount),
        followingCount: String(user.followingCount),
        createdAt: user.createdAt
      };
      await pref.put(KEY_USER_INFO, JSON.stringify(sessionData));
      await pref.flush();
    } catch (e) { /* ignore */ }
  }
}
