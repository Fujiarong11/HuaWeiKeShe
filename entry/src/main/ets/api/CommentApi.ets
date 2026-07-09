/**
 * 评论 API — 对接 Spring Boot 后端
 *
 * POST /api/comment/create   { targetId, targetType, content, authorId, authorName, authorAvatar, replyToId } → ApiResult<CommentResponse>
 * GET  /api/comment/list/{targetId}                                                                            → ApiResult<CommentResponse[]>
 */
import { http } from '@kit.NetworkKit';
import { ApiConfig } from './ApiConfig';

// ========== 类型定义 ==========

export interface CommentResponse {
  id: string;
  targetId: string;
  targetType: string;
  content: string;
  authorId: string;
  authorName: string;
  authorAvatar: string;
  replyToId: string;
  likeCount: number;
  createdAt: string;
}

interface ApiResult {
  code: number;
  msg?: string;
  data?: object;
}

interface CreateCommentBody {
  targetId: string;
  targetType: string;
  content: string;
  authorId: string;
  authorName: string;
  authorAvatar: string;
  replyToId: string | null;
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

// ========== API 函数 ==========

/** 创建评论 */
export async function createComment(
  targetId: string, targetType: string, content: string,
  authorId: string, authorName: string, authorAvatar: string,
  replyToId?: string
): Promise<ApiResult> {
  const body: CreateCommentBody = {
    targetId: targetId,
    targetType: targetType,
    content: content,
    authorId: authorId,
    authorName: authorName,
    authorAvatar: authorAvatar,
    replyToId: replyToId || null
  };
  return httpPost('/api/comment/create', body);
}

/** 获取目标的评论列表 */
export async function getCommentsByTargetId(targetId: string): Promise<ApiResult> {
  return httpGet('/api/comment/list/' + targetId);
}
