/**
 * 问题 API — 对接 Spring Boot 后端
 */
import { http } from '@kit.NetworkKit';
import { ApiConfig } from './ApiConfig';
import type { ApiResult } from './UserApi';

// ========== 请求/响应接口 ==========

interface CreateBody {
  title: string;
  content: string;
  authorId: string;
  authorName: string;
  authorAvatar: string;
  topicIds: string[];
}

interface HttpHeader {
  'Content-Type': string;
}

export interface QuestionResponse {
  id: number;
  title: string;
  content: string;
  authorId: number;
  authorName: string;
  authorAvatar: string;
  topicIds: string[];
  status: string;
  viewCount: number;
  likeCount: number;
  followerCount: number;
  answerCount: number;
  createdAt: string;
  updatedAt: string;
}

// ========== HTTP 工具 ==========

function buildHeader(): HttpHeader {
  const h: HttpHeader = { 'Content-Type': 'application/json' };
  return h;
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
    return { code: -1, msg: '网络连接失败' };
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
    return { code: -1, msg: '网络连接失败' };
  } finally {
    req.destroy();
  }
}

async function httpDelete(path: string): Promise<ApiResult> {
  const req = http.createHttp();
  const url: string = ApiConfig.BASE_URL + path;
  try {
    const resp = await req.request(url, {
      method: http.RequestMethod.DELETE,
      connectTimeout: 10000,
      readTimeout: 10000
    });
    return JSON.parse(resp.result as string) as ApiResult;
  } catch (_e) {
    return { code: -1, msg: '网络连接失败' };
  } finally {
    req.destroy();
  }
}

// ========== 问题 API ==========

/** 发布问题 */
export async function createQuestion(title: string, content: string, topicIds: string[],
  authorId: string, authorName: string, authorAvatar: string): Promise<ApiResult> {
  const body: CreateBody = {
    title: title,
    content: content,
    authorId: authorId,
    authorName: authorName,
    authorAvatar: authorAvatar,
    topicIds: topicIds
  };
  return httpPost('/api/question/create', body);
}

/** 获取问题列表 */
export async function getQuestionList(page: number = 1, size: number = 50): Promise<ApiResult> {
  return httpGet('/api/question/list?page=' + page + '&size=' + size);
}

/** 获取单个问题 */
export async function getQuestionById(id: string): Promise<ApiResult> {
  return httpGet('/api/question/' + id);
}

/** 获取用户的问题 */
export async function getUserQuestions(userId: string): Promise<ApiResult> {
  return httpGet('/api/question/user/' + userId);
}

/** 删除问题 */
export async function deleteQuestion(id: string, userId: string): Promise<ApiResult> {
  return httpDelete('/api/question/' + id + '?userId=' + userId);
}

/** 获取热门问题（按热度排序） */
export async function getHotQuestions(page: number = 1, size: number = 20): Promise<ApiResult> {
  return httpGet('/api/question/hot?page=' + page + '&size=' + size);
}

/** 获取推荐问题（按用户关注话题推荐） */
export async function getRecommendedQuestions(userId: string, page: number = 1, size: number = 20): Promise<ApiResult> {
  return httpGet('/api/question/recommend?userId=' + userId + '&page=' + page + '&size=' + size);
}
