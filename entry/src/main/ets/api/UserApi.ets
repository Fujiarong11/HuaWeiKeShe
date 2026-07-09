/**
 * 腾讯云 CloudBase 云函数 API
 * 通过 @cloudbase/app SDK 调用
 *
 * 你的云函数支持以下 action：
 *   userRegister    - 注册用户
 *   getUser         - 查询用户
 *   addTopic        - 创建话题
 *   getAllTopic     - 获取所有话题
 *   publishQuestion - 发布提问
 *   getQuestionList - 获取问题列表
 *   publishAnswer   - 发布回答
 *   getAnswerByQid  - 按问题ID查回答
 *   publishComment  - 发布评论
 *   getCommentByTid - 按目标ID查评论
 */
import { tcb } from '../tcb/CloudConfig';

/**
 * 云函数通用返回结构
 */
interface CloudFunctionResult {
  code: number;
  msg?: string;
  data?: object;
}

/**
 * 云函数调用参数类型定义
 */
interface IdParams {
  id: string;
}

interface QidParams {
  qid: string;
}

interface TidParams {
  tid: string;
}

interface QuestionListParams {
  filter: object;
  skip: number;
  limit: number;
}

/**
 * 调用云函数底层方法
 */
async function callFunction(action: string, data: object): Promise<CloudFunctionResult> {
  try {
    const res = await tcb.callFunction({
      name: 'scfnodejshelloworld',
      data: {
        action: action,
        data: data
      }
    });
    return res.result as CloudFunctionResult;
  } catch (err) {
    return { code: -1, msg: '网络连接失败，请检查网络后重试' };
  }
}

// ============================================================
// 用户相关 API
// ============================================================

export async function userRegister(userData: object): Promise<CloudFunctionResult> {
  return callFunction('userRegister', userData);
}

export async function getUser(userId: string): Promise<CloudFunctionResult> {
  const params: IdParams = { id: userId };
  return callFunction('getUser', params);
}

// ============================================================
// 话题相关 API
// ============================================================

export async function addTopic(topicData: object): Promise<CloudFunctionResult> {
  return callFunction('addTopic', topicData);
}

export async function getAllTopic(): Promise<CloudFunctionResult> {
  const params: Record<string, Object> = {};
  return callFunction('getAllTopic', params);
}

// ============================================================
// 提问相关 API
// ============================================================

export async function publishQuestion(questionData: object): Promise<CloudFunctionResult> {
  return callFunction('publishQuestion', questionData);
}

export async function getQuestionList(filter: object, skip: number, limit: number): Promise<CloudFunctionResult> {
  const params: QuestionListParams = { filter, skip, limit };
  return callFunction('getQuestionList', params);
}

// ============================================================
// 回答相关 API
// ============================================================

export async function publishAnswer(answerData: object): Promise<CloudFunctionResult> {
  return callFunction('publishAnswer', answerData);
}

export async function getAnswerByQid(questionId: string): Promise<CloudFunctionResult> {
  const params: QidParams = { qid: questionId };
  return callFunction('getAnswerByQid', params);
}

// ============================================================
// 评论相关 API
// ============================================================

export async function publishComment(commentData: object): Promise<CloudFunctionResult> {
  return callFunction('publishComment', commentData);
}

export async function getCommentByTid(targetId: string): Promise<CloudFunctionResult> {
  const params: TidParams = { tid: targetId };
  return callFunction('getCommentByTid', params);
}
