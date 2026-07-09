/**
 * 本地数据库 API
 * 使用 HarmonyOS RelationalStore 替代 CloudBase 云函数
 *
 * 当前已实现本地版本：
 *   userRegister    - 注册用户（写入本地数据库）
 *   getUser         - 查询用户（按手机号查本地数据库）
 *
 * 其余 API（发帖、回答、评论等）仍为占位，后续可接入后端。
 */
import { DatabaseHelper } from '../data/DatabaseHelper';
import type { UserRow, QuestionRow, AnswerRow } from '../data/DatabaseHelper';

/**
 * API 通用返回结构（与旧 CloudBase 接口兼容）
 */
interface ApiResult {
  code: number;
  msg?: string;
  data?: object;
}

// ============================================================
// 用户相关 API（已接本地数据库）
// ============================================================

/**
 * 注册新用户
 */
export async function userRegister(userData: object): Promise<ApiResult> {
  try {
    const row: UserRow = userData as UserRow;
    const rowId: number = await DatabaseHelper.insertUser(row);
    if (rowId >= 0) {
      return { code: 0 };
    }
    return { code: -1, msg: '注册失败，请稍后重试' };
  } catch (err) {
    return { code: -1, msg: '该手机号已被注册' };
  }
}

/**
 * 根据手机号（即 id）查询用户
 */
export async function getUser(userId: string): Promise<ApiResult> {
  try {
    const row: UserRow | null = await DatabaseHelper.queryUserByPhone(userId);
    if (row) {
      return { code: 0, data: row as object };
    }
    return { code: -1, msg: '用户不存在' };
  } catch (err) {
    return { code: -1, msg: '查询失败' };
  }
}

// ============================================================
// 话题相关 API
// ============================================================

export async function addTopic(topicData: object): Promise<ApiResult> {
  // 话题由 MockData 预设管理，暂不支持动态添加
  return { code: -1, msg: '暂不支持动态添加话题' };
}

export async function getAllTopic(): Promise<ApiResult> {
  // 话题通过 MockData.getAllTopics() 获取
  return { code: 0, msg: '请从 MockData 获取话题' };
}

// ============================================================
// 提问相关 API
// ============================================================

export async function publishQuestion(questionData: object): Promise<ApiResult> {
  try {
    const row: QuestionRow = questionData as QuestionRow;
    const rowId: number = await DatabaseHelper.insertQuestion(row);
    if (rowId >= 0) {
      const resultData: Record<string, string> = { 'id': row.id };
      return { code: 0, msg: '发布成功', data: resultData as object };
    }
    return { code: -1, msg: '发布失败' };
  } catch (err) {
    return { code: -1, msg: '发布失败' };
  }
}

export async function getQuestionList(filter: object, skip: number, limit: number): Promise<ApiResult> {
  try {
    const allQuestions: QuestionRow[] = await DatabaseHelper.queryAllQuestions();
    const paged: QuestionRow[] = allQuestions.slice(skip, skip + limit);
    return { code: 0, data: paged as object };
  } catch (err) {
    return { code: -1, msg: '查询失败' };
  }
}

// ============================================================
// 回答相关 API
// ============================================================

export async function publishAnswer(answerData: object): Promise<ApiResult> {
  try {
    const row: AnswerRow = answerData as AnswerRow;
    const rowId: number = await DatabaseHelper.insertAnswer(row);
    if (rowId >= 0) {
      const resultData: Record<string, string> = { 'id': row.id };
      return { code: 0, msg: '发布成功', data: resultData as object };
    }
    return { code: -1, msg: '发布失败' };
  } catch (err) {
    return { code: -1, msg: '发布失败' };
  }
}

export async function getAnswerByQid(questionId: string): Promise<ApiResult> {
  try {
    const answers: AnswerRow[] = await DatabaseHelper.queryAnswersByQuestionId(questionId);
    return { code: 0, data: answers as object };
  } catch (err) {
    return { code: -1, msg: '查询失败' };
  }
}

// ============================================================
// 评论相关 API
// ============================================================

export async function publishComment(commentData: object): Promise<ApiResult> {
  // 评论暂由 MockData 内存管理
  return { code: 0, msg: '评论已发布' };
}

export async function getCommentByTid(targetId: string): Promise<ApiResult> {
  // 评论暂由 MockData 内存管理
  return { code: 0, msg: '请从 MockData 获取评论' };
}
