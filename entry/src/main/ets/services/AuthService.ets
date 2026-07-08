/**
 * 认证服务层
 * 封装用户注册和登录逻辑，支持云函数调用和本地 Mock 降级
 *
 * 云函数模式：调用 AGC 云函数完成注册/登录
 * Mock 模式：云函数不可用时自动降级为本地模拟认证（方便开发调试）
 */
import { preferences } from '@kit.ArkData';
import { UserModel, LoginResult, RegisterResult } from '../model/UserModel';
import { getStore } from '../mock/MockData';

const PREF_NAME = 'auth_preferences';
const KEY_TOKEN = 'auth_token';
const KEY_USERNAME = 'auth_username';

/**
 * 输入校验规则
 */
const USERNAME_MIN = 2;
const USERNAME_MAX = 20;
const PASSWORD_MIN = 6;
const PASSWORD_MAX = 20;
const USERNAME_REGEX = /^[a-zA-Z0-9_一-龥]+$/;

@Observed
export class AuthService {
  private static instance: AuthService;
  private token: string = '';
  private useMock: boolean = true; // 默认 Mock 模式，部署后切换为 false

  static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService();
    }
    return AuthService.instance;
  }

  private constructor() {}

  /**
   * 校验用户名格式
   */
  validateUsername(username: string): string | null {
    if (!username || username.trim().length === 0) {
      return '用户名不能为空';
    }
    const trimmed = username.trim();
    if (trimmed.length < USERNAME_MIN) {
      return `用户名至少需要${USERNAME_MIN}个字符`;
    }
    if (trimmed.length > USERNAME_MAX) {
      return `用户名不能超过${USERNAME_MAX}个字符`;
    }
    if (!USERNAME_REGEX.test(trimmed)) {
      return '用户名只能包含中文、英文、数字和下划线';
    }
    return null; // 校验通过
  }

  /**
   * 校验密码格式
   */
  validatePassword(password: string): string | null {
    if (!password || password.length === 0) {
      return '密码不能为空';
    }
    if (password.length < PASSWORD_MIN) {
      return `密码至少需要${PASSWORD_MIN}个字符`;
    }
    if (password.length > PASSWORD_MAX) {
      return `密码不能超过${PASSWORD_MAX}个字符`;
    }
    return null; // 校验通过
  }

  /**
   * 用户注册
   */
  async register(username: string, password: string): Promise<RegisterResult> {
    // 客户端校验
    const userError = this.validateUsername(username);
    if (userError) {
      return { success: false, error: userError };
    }
    const passError = this.validatePassword(password);
    if (passError) {
      return { success: false, error: passError };
    }

    if (this.useMock) {
      return this.mockRegister(username.trim(), password);
    }

    return this.cloudRegister(username.trim(), password);
  }

  /**
   * 用户登录
   */
  async login(username: string, password: string): Promise<LoginResult> {
    // 客户端校验
    const userError = this.validateUsername(username);
    if (userError) {
      return { success: false, error: userError };
    }
    const passError = this.validatePassword(password);
    if (passError) {
      return { success: false, error: passError };
    }

    if (this.useMock) {
      return this.mockLogin(username.trim(), password);
    }

    return this.cloudLogin(username.trim(), password);
  }

  /**
   * 登出 - 清除本地登录状态
   */
  async logout(): Promise<void> {
    this.token = '';
    try {
      const pref = await preferences.getPreferences(getContext(), PREF_NAME);
      await pref.delete(KEY_TOKEN);
      await pref.delete(KEY_USERNAME);
      await pref.flush();
    } catch (e) {
      // 清除失败不影响登出流程
    }
    AppStorage.setOrCreate('currentUser', null);
    AppStorage.setOrCreate('currentUserId', '');
  }

  /**
   * 获取当前 token
   */
  getToken(): string {
    return this.token;
  }

  /**
   * 尝试从本地恢复登录状态
   */
  async tryRestoreSession(): Promise<UserModel | null> {
    try {
      const pref = await preferences.getPreferences(getContext(), PREF_NAME);
      const savedToken = pref.getSync(KEY_TOKEN, '') as string;
      const savedUsername = pref.getSync(KEY_USERNAME, '') as string;

      if (savedToken && savedUsername) {
        // 在 Mock 模式下，从本地数据恢复用户
        if (this.useMock) {
          const store = getStore();
          const user = store.users.find(u => u.name === savedUsername);
          if (user) {
            this.token = savedToken;
            AppStorage.setOrCreate('currentUser', user);
            AppStorage.setOrCreate('currentUserId', user.id);
            return user;
          }
        }
        // TODO: 云函数模式下调用 verifyToken 验证 token 有效性
      }
    } catch (e) {
      // 恢复失败，需要重新登录
    }
    return null;
  }

  /**
   * 保存登录状态到本地
   */
  private async saveSession(user: UserModel, token: string): Promise<void> {
    this.token = token;
    try {
      const pref = await preferences.getPreferences(getContext(), PREF_NAME);
      await pref.put(KEY_TOKEN, token);
      await pref.put(KEY_USERNAME, user.name);
      await pref.flush();
    } catch (e) {
      // 保存失败不影响登录流程
    }
  }

  // ============================================================
  // Mock 模式 - 本地模拟认证
  // ============================================================

  /**
   * Mock 注册 - 在本地 MockData 中创建新用户
   */
  private async mockRegister(username: string, password: string): Promise<RegisterResult> {
    // 模拟网络延迟
    await this.delay(500);

    const store = getStore();

    // 检查用户名是否已存在
    const existingUser = store.users.find(
      u => u.name === username || (u as UserModel & { username?: string }).username === username
    );
    if (existingUser) {
      return { success: false, error: '该用户名已被注册' };
    }

    // 创建新用户
    const newUser = new UserModel();
    newUser.id = `u_mock_${Date.now()}`;
    newUser.name = username;
    newUser.avatar = '';
    newUser.bio = '新用户，暂无简介';
    newUser.college = '';
    newUser.major = '';
    newUser.grade = '';
    newUser.reputation = 0;
    newUser.acceptedCount = 0;
    newUser.totalAnswers = 0;
    newUser.totalQuestions = 0;
    newUser.followerCount = 0;
    newUser.followingCount = 0;
    newUser.createdAt = new Date().toISOString();

    // 添加到 Mock 数据中
    store.users.push(newUser);

    // 生成 Mock token
    const token = `mock_token_${newUser.id}_${Date.now()}`;

    // 保存登录状态
    await this.saveSession(newUser, token);

    // 同步到 AppStorage
    AppStorage.setOrCreate('currentUser', newUser);
    AppStorage.setOrCreate('currentUserId', newUser.id);

    return { success: true, user: newUser };
  }

  /**
   * Mock 登录 - 从本地 MockData 中查找用户
   */
  private async mockLogin(username: string, password: string): Promise<LoginResult> {
    // 模拟网络延迟
    await this.delay(500);

    const store = getStore();

    // 通过 name 字段查找用户（Mock 模式下密码不做验证，任意密码均可登录）
    const user = store.users.find(
      u => u.name === username || (u as UserModel & { username?: string }).username === username
    );

    if (!user) {
      return { success: false, error: '用户名或密码错误' };
    }

    // 生成 Mock token
    const token = `mock_token_${user.id}_${Date.now()}`;

    // 保存登录状态
    await this.saveSession(user, token);

    // 同步到 AppStorage
    AppStorage.setOrCreate('currentUser', user);
    AppStorage.setOrCreate('currentUserId', user.id);

    return { success: true, user: user, token: token };
  }

  // ============================================================
  // 云函数模式 - 调用 AGC 云函数
  // ============================================================

  /**
   * 调用云函数注册
   * TODO: 部署 AGC 后启用
   */
  private async cloudRegister(username: string, password: string): Promise<RegisterResult> {
    try {
      // TODO: 替换为真实的 AGC 云函数调用
      // import agconnect from '@hw-agconnect/cloud';
      // const result = await agconnect.cloud().callFunction({
      //   name: 'user-auth',
      //   version: '$latest',
      //   data: { action: 'register', username, password }
      // });
      // if (result.success) {
      //   const user = this.mapCloudUserToModel(result.user);
      //   await this.saveSession(user, result.token);
      //   AppStorage.setOrCreate('currentUser', user);
      //   AppStorage.setOrCreate('currentUserId', user.id);
      //   return { success: true, user };
      // }
      // return { success: false, error: result.error || '注册失败' };

      // 暂时降级为 Mock
      return this.mockRegister(username, password);
    } catch (e) {
      return { success: false, error: '网络连接失败，请检查网络后重试' };
    }
  }

  /**
   * 调用云函数登录
   * TODO: 部署 AGC 后启用
   */
  private async cloudLogin(username: string, password: string): Promise<LoginResult> {
    try {
      // TODO: 替换为真实的 AGC 云函数调用
      // import agconnect from '@hw-agconnect/cloud';
      // const result = await agconnect.cloud().callFunction({
      //   name: 'user-auth',
      //   version: '$latest',
      //   data: { action: 'login', username, password }
      // });
      // if (result.success) {
      //   const user = this.mapCloudUserToModel(result.user);
      //   await this.saveSession(user, result.token);
      //   AppStorage.setOrCreate('currentUser', user);
      //   AppStorage.setOrCreate('currentUserId', user.id);
      //   return { success: true, user, token: result.token };
      // }
      // return { success: false, error: result.error || '登录失败' };

      // 暂时降级为 Mock
      return this.mockLogin(username, password);
    } catch (e) {
      return { success: false, error: '网络连接失败，请检查网络后重试' };
    }
  }

  /**
   * 将云函数返回的用户数据映射为 UserModel
   */
  private mapCloudUserToModel(cloudUser: Record<string, Object>): UserModel {
    const user = new UserModel();
    user.id = cloudUser.id as string || '';
    user.name = cloudUser.name as string || '';
    user.avatar = cloudUser.avatar as string || '';
    user.bio = cloudUser.bio as string || '';
    user.college = cloudUser.college as string || '';
    user.major = cloudUser.major as string || '';
    user.grade = cloudUser.grade as string || '';
    user.reputation = cloudUser.reputation as number || 0;
    user.acceptedCount = cloudUser.acceptedCount as number || 0;
    user.totalAnswers = cloudUser.totalAnswers as number || 0;
    user.totalQuestions = cloudUser.totalQuestions as number || 0;
    user.followerCount = cloudUser.followerCount as number || 0;
    user.followingCount = cloudUser.followingCount as number || 0;
    user.createdAt = cloudUser.createdAt as string || '';
    return user;
  }

  /**
   * 模拟网络延迟
   */
  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: Function) => {
      setTimeout(() => { resolve(); }, ms);
    });
  }
}
