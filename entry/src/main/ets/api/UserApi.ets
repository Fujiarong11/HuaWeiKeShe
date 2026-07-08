/**
 * 腾讯云 CloudBase 用户 API
 * 通过 HTTP 调用云函数完成登录和注册
 */
import { http } from '@kit.NetworkKit';
import { CLOUDBASE_CONFIG } from '../tcb/CloudBaseConfig';

/**
 * 云函数返回结构
 */
interface CloudFunctionResult {
  success: boolean;
  message?: string;
  error?: string;
  userId?: string;
  token?: string;
  user?: Record<string, Object>;
  data?: Record<string, Object>;
}

/**
 * 调用云函数的底层方法
 */
async function callFunction(type: string, params: Record<string, string>): Promise<CloudFunctionResult> {
  const httpRequest = http.createHttp();

  try {
    const requestBody = JSON.stringify({
      type: type,
      ...params
    });

    const response = await httpRequest.request(
      CLOUDBASE_CONFIG.httpEndpoint,
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: requestBody,
        connectTimeout: 15000,
        readTimeout: 15000
      }
    );

    if (response.responseCode === 200) {
      const result = JSON.parse(response.result as string) as CloudFunctionResult;
      return result;
    } else {
      return {
        success: false,
        error: `服务器错误 (${response.responseCode})`
      };
    }
  } catch (err) {
    return {
      success: false,
      error: '网络连接失败，请检查网络后重试'
    };
  } finally {
    httpRequest.destroy();
  }
}

/**
 * 用户登录
 * @param phone 手机号
 * @param password 密码
 */
export async function login(phone: string, password: string): Promise<CloudFunctionResult> {
  return callFunction('login', { phone, password });
}

/**
 * 用户注册
 * @param username 用户名
 * @param phone 手机号
 * @param password 密码
 */
export async function register(username: string, phone: string, password: string): Promise<CloudFunctionResult> {
  return callFunction('register', { username, phone, password });
}
