/**
 * 回答 API — 对接 Spring Boot 后端
 *
 * POST /api/answer/create          { questionId, authorId, authorName, authorAvatar, content } → ApiResult<AnswerResponse>
 * GET  /api/answer/list/{questionId}                                                → ApiResult<AnswerResponse[]>
 * DELETE /api/answer/{id}?userId=                                                    → ApiResult<void>
 */
import { http } from '@kit.NetworkKit';
import { ApiConfig } from './ApiConfig';

// ========== 类型定义 ==========

export interface AnswerResponse {
  id: string;
  questionId: string;
  authorId: string;
  authorName: string;
  authorAvatar: string;
  content: string;
  likeCount: number;
  commentCount: number;
  isAccepted: number;
  createdAt: string;
}

interface ApiResult {
  code: number;
  msg?: string;
  data?: object;
}

interface CreateAnswerBody {
  questionId: string;
  authorId: string;
  authorName: string;
  authorAvatar: string;
  content: string;
}

// ========== HTTP 工具 ==========

function buildApiError(msg: string): ApiResult {
  return { code: -1, msg: msg };
}

async function httpPost(path: string, body: object): Promise<ApiResult> {
  const req = http.createHttp();
  const url = ApiConfig.BASE_URL + path;
  try {
    const resp = await req.request(url, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
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

async function httpDelete(path: string): Promise<ApiResult> {
  const req = http.createHttp();
  const url = ApiConfig.BASE_URL + path;
  try {
    const resp = await req.request(url, {
      method: http.RequestMethod.DELETE,
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

/** 创建回答 */
export async function createAnswer(
  questionId: string, content: string,
  authorId: string, authorName: string, authorAvatar: string
): Promise<ApiResult> {
  const body: CreateAnswerBody = {
    questionId: questionId,
    authorId: authorId,
    authorName: authorName,
    authorAvatar: authorAvatar,
    content: content
  };
  return httpPost('/api/answer/create', body);
}

/** 获取问题的回答列表 */
export async function getAnswersByQuestionId(questionId: string): Promise<ApiResult> {
  return httpGet('/api/answer/list/' + questionId);
}

/** 删除回答 */
export async function deleteAnswer(answerId: string, userId: string): Promise<ApiResult> {
  return httpDelete('/api/answer/' + answerId + '?userId=' + userId);
}
