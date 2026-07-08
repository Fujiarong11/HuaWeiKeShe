/**
 * 认证服务层
 * 对接腾讯云 CloudBase 云函数 scfnodejshelloworld
 *
 * 云函数接口（你的实际云函数）：
 *   userRegister  - 注册: { action: "userRegister", data: { id, username, password, ... } }
 *   getUser       - 查用户: { action: "getUser", data: { id } }
 *
 * ⚠️ 注意：当前云函数没有服务端密码验证，登录时通过 getUser 查询后本地比对。
 *    建议后续在云函数中添加 login action 做服务端密码校验 + token 签发。
 */
import { preferences } from '@kit.ArkData';
import { UserModel, LoginResult, RegisterResult } from '../model/UserModel';
import * as UserApi from '../api/UserApi';

const PREF_NAME = 'auth_preferences';
const KEY_USER_ID = 'auth_user_id';
const KEY_USER_INFO = 'auth_user_info';

const PASSWORD_MIN = 6;
const PASSWORD_MAX = 20;
const USERNAME_MIN = 2;
const USERNAME_MAX = 20;
const PHONE_REGEX = /^1[3-9]\d{9}$/;
const USERNAME_REGEX = /^[a-zA-Z0-9_一-龥]+$/;

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
      // 先检查手机号是否已注册
      const check = await UserApi.getUser(phone.trim());
      if (check.code === 0 && check.data) {
        return { success: false, error: '该手机号已被注册' };
      }

      // 注册（id 用手机号，方便 login 时查询）
      const userData = {
        id: phone.trim(),
        username: username.trim(),
        phone: phone.trim(),
        password: password,                    // ⚠️ 明文存密码，生产环境需改为哈希
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
        createdAt: new Date().toISOString()
      };

      const res = await UserApi.userRegister(userData);

      if (res.code === 0) {
        const user = this.buildUserModel(userData);
        await this.saveSession(user);
        AppStorage.setOrCreate('currentUser', user);
        AppStorage.setOrCreate('currentUserId', user.id);
        return { success: true, user };
      } else {
        return { success: false, error: (res.msg || '注册失败') as string };
      }
    } catch (e) {
      return { success: false, error: '网络连接失败，请检查网络后重试' };
    }
  }

  // ========== 登录 ==========

  async login(phone: string, password: string): Promise<LoginResult> {
    const err = this.validatePhone(phone) || this.validatePassword(password);
    if (err) return { success: false, error: err };

    try {
      // 通过手机号（即 id）查询用户
      const res = await UserApi.getUser(phone.trim());

      if (res.code === 0 && res.data) {
        const userData = res.data as Record<string, Object>;

        // ⚠️ 本地比对密码（生产环境应由云函数做服务端验证）
        const storedPassword = userData.password as string || '';
        if (storedPassword !== password) {
          return { success: false, error: '手机号或密码错误' };
        }

        const user = this.buildUserModel(userData);
        await this.saveSession(user);
        AppStorage.setOrCreate('currentUser', user);
        AppStorage.setOrCreate('currentUserId', user.id);
        return { success: true, user, token: `token_${Date.now()}` };
      } else {
        return { success: false, error: '手机号或密码错误' };
      }
    } catch (e) {
      return { success: false, error: '网络连接失败，请检查网络后重试' };
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
      const savedId = pref.getSync(KEY_USER_ID, '') as string;
      const savedInfo = pref.getSync(KEY_USER_INFO, '') as string;

      if (savedId && savedInfo) {
        const data = JSON.parse(savedInfo) as Record<string, string>;
        const user = this.buildUserModel(data);
        AppStorage.setOrCreate('currentUser', user);
        AppStorage.setOrCreate('currentUserId', user.id);
        return user;
      }
    } catch (e) { /* ignore */ }
    return null;
  }

  // ========== 内部工具 ==========

  private async saveSession(user: UserModel): Promise<void> {
    try {
      const pref = await preferences.getPreferences(getContext(), PREF_NAME);
      await pref.put(KEY_USER_ID, user.id);
      await pref.put(KEY_USER_INFO, JSON.stringify({
        id: user.id, name: user.name, avatar: user.avatar,
        bio: user.bio, college: user.college, major: user.major,
        grade: user.grade, reputation: String(user.reputation),
        acceptedCount: String(user.acceptedCount),
        totalAnswers: String(user.totalAnswers),
        totalQuestions: String(user.totalQuestions),
        followerCount: String(user.followerCount),
        followingCount: String(user.followingCount),
        createdAt: user.createdAt
      }));
      await pref.flush();
    } catch (e) { /* ignore */ }
  }

  private buildUserModel(data: Record<string, Object>): UserModel {
    const u = new UserModel();
    u.id = (data.id || data.phone || '') as string;
    u.name = (data.username || data.name || '') as string;
    u.avatar = (data.avatar || '') as string;
    u.bio = (data.bio || '') as string;
    u.college = (data.college || '') as string;
    u.major = (data.major || '') as string;
    u.grade = (data.grade || '') as string;
    u.reputation = (data.reputation || 0) as number;
    u.acceptedCount = (data.acceptedCount || 0) as number;
    u.totalAnswers = (data.totalAnswers || 0) as number;
    u.totalQuestions = (data.totalQuestions || 0) as number;
    u.followerCount = (data.followerCount || 0) as number;
    u.followingCount = (data.followingCount || 0) as number;
    u.createdAt = (data.createdAt || '') as string;
    return u;
  }
}
