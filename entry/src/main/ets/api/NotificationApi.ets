/**
 * 通知 API — 对接 Spring Boot 后端
 *
 * GET /api/notification/list/{userId}        → ApiResult<NotificationResponse[]>
 * PUT /api/notification/{id}/read             → ApiResult<void>
 * GET /api/notification/unread-count/{userId} → ApiResult<number>
 */
import { http } from '@kit.NetworkKit';
import { ApiConfig } from './ApiConfig';

// ========== 类型定义 ==========

export interface NotificationResponse {
  id: string;
  userId: string;
  type: string;
  title: string;
  content: string;
  fromUserId: string;
  fromUserName: string;
  fromUserAvatar: string;
  targetQuestionId: string;
  targetAnswerId: string;
  isRead: number;
  createdAt: string;
}

interface ApiResult {
  code: number;
  msg?: string;
  data?: object;
}

/** 未读数量专用返回类型，data 为 number */
interface CountResult {
  code: number;
  msg?: string;
  data?: number;
}

// ========== HTTP 工具 ==========

function buildApiError(msg: string): ApiResult {
  return { code: -1, msg: msg };
}

async function httpGet(path: string): Promise<ApiResult> {
  const req = http.createHttp();
  const url = ApiConfig.BASE_URL + path;
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

async function httpPut(path: string): Promise<ApiResult> {
  const req = http.createHttp();
  const url = ApiConfig.BASE_URL + path;
  try {
    const resp = await req.request(url, {
      method: http.RequestMethod.PUT,
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

// ========== API 函数 ==========

/** 获取通知列表 */
export async function getNotifications(userId: string): Promise<ApiResult> {
  return httpGet('/api/notification/list/' + userId);
}

/** 标记通知已读 */
export async function markRead(notificationId: string): Promise<ApiResult> {
  return httpPut('/api/notification/' + notificationId + '/read');
}

/** 获取未读通知数 */
export async function getUnreadCount(userId: string): Promise<CountResult> {
  const req = http.createHttp();
  const url = ApiConfig.BASE_URL + '/api/notification/unread-count/' + userId;
  try {
    const resp = await req.request(url, {
      method: http.RequestMethod.GET,
      connectTimeout: 10000,
      readTimeout: 10000
    });
    const result: CountResult = JSON.parse(resp.result as string) as CountResult;
    return result;
  } catch (_e) {
    return { code: -1, msg: '网络连接失败，请确认后端已启动' };
  } finally {
    req.destroy();
  }
}
