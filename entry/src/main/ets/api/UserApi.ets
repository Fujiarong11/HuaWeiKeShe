/**
 * 后端 HTTP API
 * 用 HTTP 请求替代本地 RelationalStore，对接 Spring Boot 后端
 *
 * 后端接口：
 *   POST /api/user/register   — 注册
 *   POST /api/user/login       — 登录
 *   GET  /api/user/getUser     — 查用户
 *
 *  其余 API（发帖、回答、评论等）仍为占位，后续接入。
 */
import { http } from '@kit.NetworkKit';
import { ApiConfig } from './ApiConfig';

/**
 * API 通用返回结构（与后端 ApiResult 对应）
 */
export interface ApiResult {
  code: number;
  msg?: string;
  data?: object;
}

// ============================================================
// 用户相关 API（已接后端 HTTP）
// ============================================================

/**
 * 注册新用户
 * POST /api/user/register
 */
export async function userRegister(userData: object): Promise<ApiResult> {
  try {
    const request = http.createHttp();
    const response = await request.request(
      `${ApiConfig.BASE_URL}/api/user/register`,
      {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify(userData),
        connectTimeout: 10000,
        readTimeout: 10000
      }
    );
    request.destroy();
    return parseResponse(response);
  } catch (err) {
    return { code: -1, msg: '网络连接失败，请检查网络后重试' };
  }
}

/**
 * 手机号+密码登录
 * POST /api/user/login
 */
export async function userLogin(phone: string, password: string): Promise<ApiResult> {
  try {
    const request = http.createHttp();
    const response = await request.request(
      `${ApiConfig.BASE_URL}/api/user/login`,
      {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify({ phone, password }),
        connectTimeout: 10000,
        readTimeout: 10000
      }
    );
    request.destroy();
    return parseResponse(response);
  } catch (err) {
    return { code: -1, msg: '网络连接失败，请检查网络后重试' };
  }
}

/**
 * 根据手机号查询用户
 * GET /api/user/getUser?phone=xxx
 */
export async function getUser(phone: string): Promise<ApiResult> {
  try {
    const request = http.createHttp();
    const response = await request.request(
      `${ApiConfig.BASE_URL}/api/user/getUser?phone=${encodeURIComponent(phone)}`,
      {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 10000
      }
    );
    request.destroy();
    return parseResponse(response);
  } catch (err) {
    return { code: -1, msg: '网络连接失败，请检查网络后重试' };
  }
}

// ============================================================
// 以下 API 为占位（后续接入后端）
// ============================================================

export async function addTopic(topicData: object): Promise<ApiResult> {
  return { code: -1, msg: '暂未接入后端' };
}

export async function getAllTopic(): Promise<ApiResult> {
  return { code: -1, msg: '暂未接入后端' };
}

export async function publishQuestion(questionData: object): Promise<ApiResult> {
  return { code: -1, msg: '暂未接入后端' };
}

export async function getQuestionList(filter: object, skip: number, limit: number): Promise<ApiResult> {
  return { code: -1, msg: '暂未接入后端' };
}

export async function publishAnswer(answerData: object): Promise<ApiResult> {
  return { code: -1, msg: '暂未接入后端' };
}

export async function getAnswerByQid(questionId: string): Promise<ApiResult> {
  return { code: -1, msg: '暂未接入后端' };
}

export async function publishComment(commentData: object): Promise<ApiResult> {
  return { code: -1, msg: '暂未接入后端' };
}

export async function getCommentByTid(targetId: string): Promise<ApiResult> {
  return { code: -1, msg: '暂未接入后端' };
}

// ============================================================
// 工具函数
// ============================================================

function parseResponse(response: http.HttpResponse): ApiResult {
  // http.ResponseCode.OK = 200
  if (response.responseCode === 200) {
    try {
      const body = JSON.parse(response.result as string) as ApiResult;
      return body;
    } catch (e) {
      return { code: -1, msg: '服务器响应格式异常' };
    }
  }
  return { code: -1, msg: `服务器错误 (${response.responseCode})` };
}
