/**
 * 互动 API — 点赞/收藏/采纳
 *
 * POST /api/interaction/like/question     { userId, targetId }  → ApiResult<void>
 * POST /api/interaction/unlike/question   { userId, targetId }  → ApiResult<void>
 * GET  /api/interaction/isLiked/question?userId=&questionId=    → ApiResult<boolean>
 * POST /api/interaction/like/answer       { userId, targetId }  → ApiResult<void>
 * POST /api/interaction/unlike/answer     { userId, targetId }  → ApiResult<void>
 * GET  /api/interaction/isLiked/answer?userId=&answerId=        → ApiResult<boolean>
 * POST /api/interaction/favorite          { userId, targetId }  → ApiResult<void>
 * POST /api/interaction/unfavorite        { userId, targetId }  → ApiResult<void>
 * GET  /api/interaction/isFavorited?userId=&questionId=         → ApiResult<boolean>
 * GET  /api/interaction/favorites/{userId}                       → ApiResult<QuestionResponse[]>
 * POST /api/interaction/accept            { answerId, userId }  → ApiResult<void>
 */
import { http } from '@kit.NetworkKit';
import { ApiConfig } from './ApiConfig';

// ========== 通用接口 ==========

export interface ApiResult {
  code: number;
  msg?: string;
  data?: object;
}

interface LikeBody {
  userId: string;
  targetId: string;
}

interface AcceptBody {
  answerId: string;
  userId: string;
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

// ========== 问题点赞/取消 ==========

export async function likeQuestion(userId: string, questionId: string): Promise<ApiResult> {
  const body: LikeBody = { userId: userId, targetId: questionId };
  return httpPost('/api/interaction/like/question', body);
}

export async function unlikeQuestion(userId: string, questionId: string): Promise<ApiResult> {
  const body: LikeBody = { userId: userId, targetId: questionId };
  return httpPost('/api/interaction/unlike/question', body);
}

export async function isQuestionLiked(userId: string, questionId: string): Promise<ApiResult> {
  return httpGet('/api/interaction/isLiked/question?userId=' + userId + '&questionId=' + questionId);
}

// ========== 回答点赞/取消 ==========

export async function likeAnswer(userId: string, answerId: string): Promise<ApiResult> {
  const body: LikeBody = { userId: userId, targetId: answerId };
  return httpPost('/api/interaction/like/answer', body);
}

export async function unlikeAnswer(userId: string, answerId: string): Promise<ApiResult> {
  const body: LikeBody = { userId: userId, targetId: answerId };
  return httpPost('/api/interaction/unlike/answer', body);
}

export async function isAnswerLiked(userId: string, answerId: string): Promise<ApiResult> {
  return httpGet('/api/interaction/isLiked/answer?userId=' + userId + '&answerId=' + answerId);
}

// ========== 收藏/取消收藏 ==========

export async function favoriteQuestion(userId: string, questionId: string): Promise<ApiResult> {
  const body: LikeBody = { userId: userId, targetId: questionId };
  return httpPost('/api/interaction/favorite', body);
}

export async function unfavoriteQuestion(userId: string, questionId: string): Promise<ApiResult> {
  const body: LikeBody = { userId: userId, targetId: questionId };
  return httpPost('/api/interaction/unfavorite', body);
}

export async function isQuestionFavorited(userId: string, questionId: string): Promise<ApiResult> {
  return httpGet('/api/interaction/isFavorited?userId=' + userId + '&questionId=' + questionId);
}

/** 获取用户的收藏列表 */
export async function getUserFavorites(userId: string): Promise<ApiResult> {
  return httpGet('/api/interaction/favorites/' + userId);
}

// ========== 采纳回答 ==========

export async function acceptAnswer(answerId: string, userId: string): Promise<ApiResult> {
  const body: AcceptBody = { answerId: answerId, userId: userId };
  return httpPost('/api/interaction/accept', body);
}
