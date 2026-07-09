/**
 * 用户本地数据库 API
 * 使用 HarmonyOS RelationalStore 做注册登录
 */
import { DatabaseHelper } from '../data/DatabaseHelper';
import type { UserRow } from '../data/DatabaseHelper';

export interface ApiResult {
  code: number;
  msg?: string;
  data?: object;
}

/**
 * 注册新用户（写入本地数据库）
 */
export async function userRegister(userData: UserRow): Promise<ApiResult> {
  try {
    const rowId: number = await DatabaseHelper.insertUser(userData);
    if (rowId >= 0) {
      return { code: 0 };
    }
    return { code: -1, msg: '注册失败，请稍后重试' };
  } catch (err) {
    return { code: -1, msg: '该手机号已被注册' };
  }
}

/**
 * 根据手机号查询用户
 */
export async function getUser(phone: string): Promise<ApiResult> {
  try {
    const row: UserRow | null = await DatabaseHelper.queryUserByPhone(phone);
    if (row) {
      return { code: 0, data: row as object };
    }
    return { code: -1, msg: '用户不存在' };
  } catch (err) {
    return { code: -1, msg: '查询失败' };
  }
}
