/**
 * 认证服务层
 * 对接 Spring Boot 后端 HTTP API，BCrypt 密码校验在服务端完成
 */
import { preferences } from '@kit.ArkData';
import { UserModel, LoginResult, RegisterResult } from '../model/UserModel';
import * as UserApi from '../api/UserApi';
import type { UserResponse } from '../api/UserApi';

const PREF_NAME = 'auth_preferences';
const KEY_USER_ID = 'auth_user_id';
const KEY_USER_INFO = 'auth_user_info';

const PASSWORD_MIN = 6;
const PASSWORD_MAX = 20;
const USERNAME_MIN = 2;
const USERNAME_MAX = 20;
const PHONE_REGEX = /^1[3-9]\d{9}$/;
const USERNAME_REGEX = /^[a-zA-Z0-9_一-龥]+$/;

/** 会话持久化数据 */
interface SessionData {
  id: string;
  phone: string;
  name: string;
  avatar: string;
  bio: string;
  college: string;
  major: string;
  grade: string;
  reputation: number;
  acceptedCount: number;
  totalAnswers: number;
  totalQuestions: number;
  followerCount: number;
  followingCount: number;
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
    if (!phone || phone.trim().length === 0) { return '手机号不能为空'; }
    if (!PHONE_REGEX.test(phone.trim())) { return '请输入正确的手机号'; }
    return null;
  }

  validateUsername(username: string): string | null {
    if (!username || username.trim().length === 0) { return '用户名不能为空'; }
    const t = username.trim();
    if (t.length < USERNAME_MIN) { return `用户名至少${USERNAME_MIN}个字符`; }
    if (t.length > USERNAME_MAX) { return `用户名不能超过${USERNAME_MAX}个字符`; }
    if (!USERNAME_REGEX.test(t)) { return '用户名只能包含中文、英文、数字和下划线'; }
    return null;
  }

  validatePassword(password: string): string | null {
    if (!password || password.length === 0) { return '密码不能为空'; }
    if (password.length < PASSWORD_MIN) { return `密码至少${PASSWORD_MIN}个字符`; }
    if (password.length > PASSWORD_MAX) { return `密码不能超过${PASSWORD_MAX}个字符`; }
    return null;
  }

  // ========== 注册 ==========

  async register(username: string, phone: string, password: string): Promise<RegisterResult> {
    const err = this.validateUsername(username) || this.validatePhone(phone) || this.validatePassword(password);
    if (err) { return { success: false, error: err }; }

    try {
      const res = await UserApi.userRegister(phone.trim(), username.trim(), password);

      if (res.code === 0 && res.data) {
        const resp: UserResponse = res.data as UserResponse;
        const user: UserModel = this.buildUserFromResponse(resp);
        await this.saveSession(user);
        this.writeToAppStorage(user);
        return { success: true, user };
      } else {
        return { success: false, error: (res.msg || '注册失败') as string };
      }
    } catch (_e) {
      return { success: false, error: '注册失败，请稍后重试' };
    }
  }

  // ========== 登录 ==========

  async login(phone: string, password: string): Promise<LoginResult> {
    const err = this.validatePhone(phone) || this.validatePassword(password);
    if (err) { return { success: false, error: err }; }

    try {
      const res = await UserApi.userLogin(phone.trim(), password);

      if (res.code === 0 && res.data) {
        const resp: UserResponse = res.data as UserResponse;
        const user: UserModel = this.buildUserFromResponse(resp);
        await this.saveSession(user);
        this.writeToAppStorage(user);
        return { success: true, user, token: `token_${Date.now()}` };
      } else {
        return { success: false, error: (res.msg || '手机号或密码错误') as string };
      }
    } catch (_e) {
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
    } catch (_e) { /* ignore */ }
    AppStorage.setOrCreate('currentUser', null);
    AppStorage.setOrCreate('currentUserId', '');
  }

  // ========== 会话恢复（本地 preferences）==========

  async tryRestoreSession(): Promise<UserModel | null> {
    try {
      const pref = await preferences.getPreferences(getContext(), PREF_NAME);
      const savedId: string = pref.getSync(KEY_USER_ID, '') as string;
      const savedInfo: string = pref.getSync(KEY_USER_INFO, '') as string;

      if (savedId && savedInfo) {
        const data: SessionData = JSON.parse(savedInfo) as SessionData;
        const user: UserModel = this.buildUserFromSession(data);
        this.writeToAppStorage(user);
        return user;
      }
    } catch (_e) { /* ignore */ }
    return null;
  }

  // ========== 内部工具 ==========

  /** 从后端 UserResponse 构建 UserModel */
  private buildUserFromResponse(resp: UserResponse): UserModel {
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
    return u;
  }

  /** 从本地 SessionData 恢复 UserModel */
  private buildUserFromSession(data: SessionData): UserModel {
    const u: UserModel = new UserModel();
    u.id = data.id;
    u.phone = data.phone || '';
    u.name = data.name;
    u.avatar = data.avatar;
    u.bio = data.bio;
    u.college = data.college;
    u.major = data.major;
    u.grade = data.grade;
    u.reputation = data.reputation;
    u.acceptedCount = data.acceptedCount;
    u.totalAnswers = data.totalAnswers;
    u.totalQuestions = data.totalQuestions;
    u.followerCount = data.followerCount;
    u.followingCount = data.followingCount;
    u.createdAt = data.createdAt;
    return u;
  }

  private async saveSession(user: UserModel): Promise<void> {
    try {
      const pref = await preferences.getPreferences(getContext(), PREF_NAME);
      await pref.put(KEY_USER_ID, user.id);
      const session: SessionData = {
        id: user.id,
        phone: user.phone,
        name: user.name,
        avatar: user.avatar,
        bio: user.bio,
        college: user.college,
        major: user.major,
        grade: user.grade,
        reputation: user.reputation,
        acceptedCount: user.acceptedCount,
        totalAnswers: user.totalAnswers,
        totalQuestions: user.totalQuestions,
        followerCount: user.followerCount,
        followingCount: user.followingCount,
        createdAt: user.createdAt
      };
      await pref.put(KEY_USER_INFO, JSON.stringify(session));
      await pref.flush();
    } catch (_e) { /* ignore */ }
  }

  private writeToAppStorage(user: UserModel): void {
    AppStorage.setOrCreate('currentUser', user);
    AppStorage.setOrCreate('currentUserId', user.id);
  }
}
