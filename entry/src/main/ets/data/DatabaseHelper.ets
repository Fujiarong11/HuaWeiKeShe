/**
 * 本地关系型数据库助手
 * 使用 HarmonyOS RelationalStore 替代 CloudBase SDK
 */
import { relationalStore } from '@kit.ArkData';

/** 数据库配置 */
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'CampusQA.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

/** 建表 SQL */
const SQL_CREATE_USERS: string = `
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    phone TEXT NOT NULL UNIQUE,
    username TEXT NOT NULL,
    password TEXT NOT NULL,
    name TEXT DEFAULT '',
    avatar TEXT DEFAULT '',
    bio TEXT DEFAULT '',
    college TEXT DEFAULT '',
    major TEXT DEFAULT '',
    grade TEXT DEFAULT '',
    reputation INTEGER DEFAULT 0,
    acceptedCount INTEGER DEFAULT 0,
    totalAnswers INTEGER DEFAULT 0,
    totalQuestions INTEGER DEFAULT 0,
    followerCount INTEGER DEFAULT 0,
    followingCount INTEGER DEFAULT 0,
    createdAt TEXT DEFAULT ''
  )
`;

/**
 * 用户数据行类型（与 UserModel 字段对应）
 */
export interface UserRow {
  id: string;
  phone: string;
  username: string;
  password: string;
  name: string;
  avatar: string;
  bio: string;
  college: string;
  major: string;
  grade: string;
  reputation: number;
  acceptedCount: number;
  totalAnswers: number;
  totalQuestions: number;
  followerCount: number;
  followingCount: number;
  createdAt: string;
}

/**
 * 数据库操作结果
 */
export interface DbResult {
  code: number;
  msg?: string;
  data?: UserRow;
}

export class DatabaseHelper {
  private static store: relationalStore.RdbStore | null = null;
  private static initialized: boolean = false;

  /**
   * 初始化数据库（应在 EntryAbility 中调用一次）
   */
  static async init(context: Context): Promise<void> {
    if (DatabaseHelper.initialized) {
      return;
    }
    try {
      DatabaseHelper.store = await relationalStore.getRdbStore(context, STORE_CONFIG);
      await DatabaseHelper.store.executeSql(SQL_CREATE_USERS);
      DatabaseHelper.initialized = true;
    } catch (err) {
      console.error('DatabaseHelper init failed:', JSON.stringify(err));
    }
  }

  /**
   * 插入用户
   */
  static async insertUser(user: UserRow): Promise<number> {
    if (!DatabaseHelper.store) {
      return -1;
    }
    const bucket: relationalStore.ValuesBucket = {
      id: user.id,
      phone: user.phone,
      username: user.username,
      password: user.password,
      name: user.name,
      avatar: user.avatar,
      bio: user.bio,
      college: user.college,
      major: user.major,
      grade: user.grade,
      reputation: user.reputation,
      acceptedCount: user.acceptedCount,
      totalAnswers: user.totalAnswers,
      totalQuestions: user.totalQuestions,
      followerCount: user.followerCount,
      followingCount: user.followingCount,
      createdAt: user.createdAt
    };
    const rowId: number = await DatabaseHelper.store.insert('users', bucket);
    return rowId;
  }

  /**
   * 根据手机号查询用户
   */
  static async queryUserByPhone(phone: string): Promise<UserRow | null> {
    if (!DatabaseHelper.store) {
      return null;
    }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('users');
    predicates.equalTo('phone', phone);
    const resultSet: relationalStore.ResultSet = await DatabaseHelper.store.query(predicates);

    if (resultSet.goToFirstRow()) {
      const row: UserRow = {
        id: resultSet.getString(resultSet.getColumnIndex('id')),
        phone: resultSet.getString(resultSet.getColumnIndex('phone')),
        username: resultSet.getString(resultSet.getColumnIndex('username')),
        password: resultSet.getString(resultSet.getColumnIndex('password')),
        name: resultSet.getString(resultSet.getColumnIndex('name')),
        avatar: resultSet.getString(resultSet.getColumnIndex('avatar')),
        bio: resultSet.getString(resultSet.getColumnIndex('bio')),
        college: resultSet.getString(resultSet.getColumnIndex('college')),
        major: resultSet.getString(resultSet.getColumnIndex('major')),
        grade: resultSet.getString(resultSet.getColumnIndex('grade')),
        reputation: resultSet.getLong(resultSet.getColumnIndex('reputation')),
        acceptedCount: resultSet.getLong(resultSet.getColumnIndex('acceptedCount')),
        totalAnswers: resultSet.getLong(resultSet.getColumnIndex('totalAnswers')),
        totalQuestions: resultSet.getLong(resultSet.getColumnIndex('totalQuestions')),
        followerCount: resultSet.getLong(resultSet.getColumnIndex('followerCount')),
        followingCount: resultSet.getLong(resultSet.getColumnIndex('followingCount')),
        createdAt: resultSet.getString(resultSet.getColumnIndex('createdAt'))
      };
      resultSet.close();
      return row;
    }
    resultSet.close();
    return null;
  }

  /**
   * 根据手机号删除用户
   */
  static async deleteUserByPhone(phone: string): Promise<number> {
    if (!DatabaseHelper.store) {
      return -1;
    }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('users');
    predicates.equalTo('phone', phone);
    const rows: number = await DatabaseHelper.store.delete(predicates);
    return rows;
  }
}
