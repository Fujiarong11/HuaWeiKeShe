/**
 * 用户 API — 对接 Spring Boot 后端
 *
 * POST /api/user/register  { phone, username, password } → ApiResult<UserResponse>
 * POST /api/user/login     { phone, password }             → ApiResult<UserResponse>
 * GET  /api/user/getUser?phone=xxx                         → ApiResult<UserResponse>
 */
import { http } from '@kit.NetworkKit';
import { ApiConfig } from './ApiConfig';

// ========== 请求体接口 ==========

interface RegisterBody {
  phone: string;
  username: string;
  password: string;
}

interface LoginBody {
  phone: string;
  password: string;
}

interface HttpHeader {
  'Content-Type': string;
}

// ========== 通用接口 ==========

export interface ApiResult {
  code: number;
  msg?: string;
  data?: object;
}

/** 后端返回的用户数据 */
export interface UserResponse {
  id: number;
  phone: string;
  username: string;
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

// ========== HTTP 工具 ==========

function buildHeader(): HttpHeader {
  const h: HttpHeader = { 'Content-Type': 'application/json' };
  return h;
}

function buildApiError(msg: string): ApiResult {
  const r: ApiResult = { code: -1, msg: msg };
  return r;
}

async function httpPost(path: string, body: object): Promise<ApiResult> {
  const req = http.createHttp();
  const url: string = ApiConfig.BASE_URL + path;
  const header: HttpHeader = buildHeader();
  try {
    const resp = await req.request(url, {
      method: http.RequestMethod.POST,
      header: header,
      extraData: JSON.stringify(body),
      connectTimeout: 10000,
      readTimeout: 10000
    });
    return JSON.parse(resp.result as string) as ApiResult;
  } catch (_e) {
    return buildApiError('网络连接失败，请确认后端已启动');
  } finally {
    req.destroy();
  }
}

async function httpGet(path: string): Promise<ApiResult> {
  const req = http.createHttp();
  const url: string = ApiConfig.BASE_URL + path;
  try {
    const resp = await req.request(url, {
      method: http.RequestMethod.GET,
      connectTimeout: 10000,
      readTimeout: 10000
    });
    return JSON.parse(resp.result as string) as ApiResult;
  } catch (_e) {
    return buildApiError('网络连接失败，请确认后端已启动');
  } finally {
    req.destroy();
  }
}

// ========== 用户 API ==========

/** 注册 */
export async function userRegister(phone: string, username: string, password: string): Promise<ApiResult> {
  const body: RegisterBody = { phone: phone, username: username, password: password };
  return httpPost('/api/user/register', body);
}

/** 登录 */
export async function userLogin(phone: string, password: string): Promise<ApiResult> {
  const body: LoginBody = { phone: phone, password: password };
  return httpPost('/api/user/login', body);
}

interface FollowBody {
  followerId: number;
  followedId: number;
}

/** 按手机号查用户 */
export async function getUser(phone: string): Promise<ApiResult> {
  return httpGet('/api/user/getUser?phone=' + encodeURIComponent(phone));
}

/** 按ID查用户 */
export async function getUserById(id: string): Promise<ApiResult> {
  return httpGet('/api/user/getById?id=' + id);
}

/** 关注用户 */
export async function followUser(followerId: string, followedId: string): Promise<ApiResult> {
  const body: FollowBody = { followerId: parseInt(followerId), followedId: parseInt(followedId) };
  return httpPost('/api/user/follow', body);
}

/** 取关用户 */
export async function unfollowUser(followerId: string, followedId: string): Promise<ApiResult> {
  const body: FollowBody = { followerId: parseInt(followerId), followedId: parseInt(followedId) };
  return httpPost('/api/user/unfollow', body);
}

/** 检查是否已关注 */
export async function isFollowing(followerId: string, followedId: string): Promise<ApiResult> {
  return httpGet('/api/user/isFollowing?followerId=' + followerId + '&followedId=' + followedId);
}

/** 获取关注列表 */
export async function getFollowingList(userId: string): Promise<ApiResult> {
  return httpGet('/api/user/' + userId + '/following');
}

/** 获取粉丝列表 */
export async function getFollowerList(userId: string): Promise<ApiResult> {
  return httpGet('/api/user/' + userId + '/followers');
}
