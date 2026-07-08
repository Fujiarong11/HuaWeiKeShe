/**
 * 腾讯云 CloudBase 云函数 API
 * 云函数: scfnodejshelloworld
 * 接口格式: { action: string, data: object }
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
import { http } from '@kit.NetworkKit';
import { CLOUDBASE_CONFIG } from '../tcb/CloudBaseConfig';

/**
 * 云函数通用返回结构
 */
interface CloudFunctionResult {
  code: number;
  msg?: string;
  data?: object;
}

/**
 * 调用云函数底层方法
 * 通过 HTTP POST 调用 CloudBase 云函数
 */
async function callFunction(action: string, data: object): Promise<CloudFunctionResult> {
  const httpRequest = http.createHttp();

  try {
    const requestBody = JSON.stringify({ action, data });

    const response = await httpRequest.request(
      CLOUDBASE_CONFIG.httpEndpoint,
      {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: requestBody,
        connectTimeout: 15000,
        readTimeout: 15000
      }
    );

    if (response.responseCode === 200) {
      const result = JSON.parse(response.result as string) as CloudFunctionResult;
      return result;
    } else {
      return { code: -1, msg: `服务器错误(${response.responseCode})` };
    }
  } catch (err) {
    return { code: -1, msg: '网络连接失败，请检查网络后重试' };
  } finally {
    httpRequest.destroy();
  }
}

// ============================================================
// 用户相关 API
// ============================================================

/**
 * 注册用户
 * 云函数 action: userRegister
 */
export async function userRegister(userData: object): Promise<CloudFunctionResult> {
  return callFunction('userRegister', userData);
}

/**
 * 查询用户
 * 云函数 action: getUser，按 id 查询
 */
export async function getUser(userId: string): Promise<CloudFunctionResult> {
  return callFunction('getUser', { id: userId });
}

// ============================================================
// 话题相关 API
// ============================================================

/**
 * 创建话题
 */
export async function addTopic(topicData: object): Promise<CloudFunctionResult> {
  return callFunction('addTopic', topicData);
}

/**
 * 获取所有话题
 */
export async function getAllTopic(): Promise<CloudFunctionResult> {
  return callFunction('getAllTopic', {});
}

// ============================================================
// 提问相关 API
// ============================================================

/**
 * 发布提问
 */
export async function publishQuestion(questionData: object): Promise<CloudFunctionResult> {
  return callFunction('publishQuestion', questionData);
}

/**
 * 获取问题列表
 */
export async function getQuestionList(filter: object, skip: number, limit: number): Promise<CloudFunctionResult> {
  return callFunction('getQuestionList', { filter, skip, limit });
}

// ============================================================
// 回答相关 API
// ============================================================

/**
 * 发布回答
 */
export async function publishAnswer(answerData: object): Promise<CloudFunctionResult> {
  return callFunction('publishAnswer', answerData);
}

/**
 * 按问题ID查询回答
 */
export async function getAnswerByQid(questionId: string): Promise<CloudFunctionResult> {
  return callFunction('getAnswerByQid', { qid: questionId });
}

// ============================================================
// 评论相关 API
// ============================================================

/**
 * 发布评论
 */
export async function publishComment(commentData: object): Promise<CloudFunctionResult> {
  return callFunction('publishComment', commentData);
}

/**
 * 按目标ID查询评论
 */
export async function getCommentByTid(targetId: string): Promise<CloudFunctionResult> {
  return callFunction('getCommentByTid', { tid: targetId });
}
