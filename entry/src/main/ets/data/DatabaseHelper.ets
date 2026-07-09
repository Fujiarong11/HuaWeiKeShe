/**
 * 本地关系型数据库助手
 * 使用 HarmonyOS RelationalStore 存储用户、问题、回答
 */
import { relationalStore } from '@kit.ArkData';

/** 数据库配置 */
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'CampusQA.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

/** 建表 — 用户 */
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

/** 建表 — 问题 */
const SQL_CREATE_QUESTIONS: string = `
  CREATE TABLE IF NOT EXISTS questions (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT DEFAULT '',
    authorId TEXT NOT NULL,
    authorName TEXT DEFAULT '',
    authorAvatar TEXT DEFAULT '',
    topicIds TEXT DEFAULT '[]',
    status TEXT DEFAULT 'OPEN',
    viewCount INTEGER DEFAULT 0,
    likeCount INTEGER DEFAULT 0,
    followerCount INTEGER DEFAULT 0,
    answerCount INTEGER DEFAULT 0,
    createdAt TEXT DEFAULT '',
    updatedAt TEXT DEFAULT ''
  )
`;

/** 建表 — 回答 */
const SQL_CREATE_ANSWERS: string = `
  CREATE TABLE IF NOT EXISTS answers (
    id TEXT PRIMARY KEY,
    questionId TEXT NOT NULL,
    content TEXT NOT NULL,
    authorId TEXT NOT NULL,
    authorName TEXT DEFAULT '',
    authorAvatar TEXT DEFAULT '',
    isAccepted INTEGER DEFAULT 0,
    likeCount INTEGER DEFAULT 0,
    commentCount INTEGER DEFAULT 0,
    createdAt TEXT DEFAULT ''
  )
`;

// ============================================================
// 类型定义
// ============================================================

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

export interface QuestionRow {
  id: string;
  title: string;
  content: string;
  authorId: string;
  authorName: string;
  authorAvatar: string;
  topicIds: string;
  status: string;
  viewCount: number;
  likeCount: number;
  followerCount: number;
  answerCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface AnswerRow {
  id: string;
  questionId: string;
  content: string;
  authorId: string;
  authorName: string;
  authorAvatar: string;
  isAccepted: number;
  likeCount: number;
  commentCount: number;
  createdAt: string;
}

export interface DbResult {
  code: number;
  msg?: string;
  data?: UserRow;
}

// ============================================================
// DatabaseHelper 类
// ============================================================

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
      await DatabaseHelper.store.executeSql(SQL_CREATE_QUESTIONS);
      await DatabaseHelper.store.executeSql(SQL_CREATE_ANSWERS);
      DatabaseHelper.initialized = true;
    } catch (err) {
      console.error('DatabaseHelper init failed:', JSON.stringify(err));
    }
  }

  // ========== 用户操作 ==========

  static async insertUser(user: UserRow): Promise<number> {
    if (!DatabaseHelper.store) { return -1; }
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

  static async queryUserByPhone(phone: string): Promise<UserRow | null> {
    if (!DatabaseHelper.store) { return null; }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('users');
    predicates.equalTo('phone', phone);
    const resultSet: relationalStore.ResultSet = await DatabaseHelper.store.query(predicates);
    const row: UserRow | null = DatabaseHelper.readFirstUser(resultSet);
    resultSet.close();
    return row;
  }

  static async queryUserById(id: string): Promise<UserRow | null> {
    if (!DatabaseHelper.store) { return null; }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('users');
    predicates.equalTo('id', id);
    const resultSet: relationalStore.ResultSet = await DatabaseHelper.store.query(predicates);
    const row: UserRow | null = DatabaseHelper.readFirstUser(resultSet);
    resultSet.close();
    return row;
  }

  static async updateUser(user: UserRow): Promise<number> {
    if (!DatabaseHelper.store) { return -1; }
    const bucket: relationalStore.ValuesBucket = {
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
    };
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('users');
    predicates.equalTo('id', user.id);
    const rows: number = await DatabaseHelper.store.update(bucket, predicates);
    return rows;
  }

  static async deleteUserByPhone(phone: string): Promise<number> {
    if (!DatabaseHelper.store) { return -1; }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('users');
    predicates.equalTo('phone', phone);
    const rows: number = await DatabaseHelper.store.delete(predicates);
    return rows;
  }

  // ========== 问题操作 ==========

  static async insertQuestion(q: QuestionRow): Promise<number> {
    if (!DatabaseHelper.store) { return -1; }
    const bucket: relationalStore.ValuesBucket = {
      id: q.id,
      title: q.title,
      content: q.content,
      authorId: q.authorId,
      authorName: q.authorName,
      authorAvatar: q.authorAvatar,
      topicIds: q.topicIds,
      status: q.status,
      viewCount: q.viewCount,
      likeCount: q.likeCount,
      followerCount: q.followerCount,
      answerCount: q.answerCount,
      createdAt: q.createdAt,
      updatedAt: q.updatedAt
    };
    const rowId: number = await DatabaseHelper.store.insert('questions', bucket);
    return rowId;
  }

  static async queryAllQuestions(): Promise<QuestionRow[]> {
    if (!DatabaseHelper.store) { return []; }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('questions');
    predicates.orderByDesc('createdAt');
    const resultSet: relationalStore.ResultSet = await DatabaseHelper.store.query(predicates);
    const rows: QuestionRow[] = DatabaseHelper.readAllQuestions(resultSet);
    resultSet.close();
    return rows;
  }

  static async queryQuestionsByAuthor(authorId: string): Promise<QuestionRow[]> {
    if (!DatabaseHelper.store) { return []; }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('questions');
    predicates.equalTo('authorId', authorId);
    predicates.orderByDesc('createdAt');
    const resultSet: relationalStore.ResultSet = await DatabaseHelper.store.query(predicates);
    const rows: QuestionRow[] = DatabaseHelper.readAllQuestions(resultSet);
    resultSet.close();
    return rows;
  }

  static async queryQuestionById(id: string): Promise<QuestionRow | null> {
    if (!DatabaseHelper.store) { return null; }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('questions');
    predicates.equalTo('id', id);
    const resultSet: relationalStore.ResultSet = await DatabaseHelper.store.query(predicates);
    const row: QuestionRow | null = DatabaseHelper.readFirstQuestion(resultSet);
    resultSet.close();
    return row;
  }

  static async updateQuestion(q: QuestionRow): Promise<number> {
    if (!DatabaseHelper.store) { return -1; }
    const bucket: relationalStore.ValuesBucket = {
      status: q.status,
      viewCount: q.viewCount,
      likeCount: q.likeCount,
      followerCount: q.followerCount,
      answerCount: q.answerCount,
      updatedAt: q.updatedAt
    };
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('questions');
    predicates.equalTo('id', q.id);
    const rows: number = await DatabaseHelper.store.update(bucket, predicates);
    return rows;
  }

  static async deleteQuestion(id: string): Promise<number> {
    if (!DatabaseHelper.store) { return -1; }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('questions');
    predicates.equalTo('id', id);
    const rows: number = await DatabaseHelper.store.delete(predicates);
    return rows;
  }

  // ========== 回答操作 ==========

  static async insertAnswer(a: AnswerRow): Promise<number> {
    if (!DatabaseHelper.store) { return -1; }
    const bucket: relationalStore.ValuesBucket = {
      id: a.id,
      questionId: a.questionId,
      content: a.content,
      authorId: a.authorId,
      authorName: a.authorName,
      authorAvatar: a.authorAvatar,
      isAccepted: a.isAccepted,
      likeCount: a.likeCount,
      commentCount: a.commentCount,
      createdAt: a.createdAt
    };
    const rowId: number = await DatabaseHelper.store.insert('answers', bucket);
    return rowId;
  }

  static async queryAnswersByQuestionId(questionId: string): Promise<AnswerRow[]> {
    if (!DatabaseHelper.store) { return []; }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('answers');
    predicates.equalTo('questionId', questionId);
    predicates.orderByAsc('createdAt');
    const resultSet: relationalStore.ResultSet = await DatabaseHelper.store.query(predicates);
    const rows: AnswerRow[] = DatabaseHelper.readAllAnswers(resultSet);
    resultSet.close();
    return rows;
  }

  static async queryAnswersByAuthor(authorId: string): Promise<AnswerRow[]> {
    if (!DatabaseHelper.store) { return []; }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('answers');
    predicates.equalTo('authorId', authorId);
    predicates.orderByDesc('createdAt');
    const resultSet: relationalStore.ResultSet = await DatabaseHelper.store.query(predicates);
    const rows: AnswerRow[] = DatabaseHelper.readAllAnswers(resultSet);
    resultSet.close();
    return rows;
  }

  static async updateAnswer(a: AnswerRow): Promise<number> {
    if (!DatabaseHelper.store) { return -1; }
    const bucket: relationalStore.ValuesBucket = {
      isAccepted: a.isAccepted,
      likeCount: a.likeCount,
      commentCount: a.commentCount
    };
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('answers');
    predicates.equalTo('id', a.id);
    const rows: number = await DatabaseHelper.store.update(bucket, predicates);
    return rows;
  }

  // ========== ResultSet 读取辅助方法 ==========

  private static readFirstUser(resultSet: relationalStore.ResultSet): UserRow | null {
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
      return row;
    }
    return null;
  }

  private static readFirstQuestion(resultSet: relationalStore.ResultSet): QuestionRow | null {
    if (resultSet.goToFirstRow()) {
      return DatabaseHelper.buildQuestionRow(resultSet);
    }
    return null;
  }

  private static readAllQuestions(resultSet: relationalStore.ResultSet): QuestionRow[] {
    const rows: QuestionRow[] = [];
    while (resultSet.goToNextRow()) {
      rows.push(DatabaseHelper.buildQuestionRow(resultSet));
    }
    return rows;
  }

  private static buildQuestionRow(resultSet: relationalStore.ResultSet): QuestionRow {
    return {
      id: resultSet.getString(resultSet.getColumnIndex('id')),
      title: resultSet.getString(resultSet.getColumnIndex('title')),
      content: resultSet.getString(resultSet.getColumnIndex('content')),
      authorId: resultSet.getString(resultSet.getColumnIndex('authorId')),
      authorName: resultSet.getString(resultSet.getColumnIndex('authorName')),
      authorAvatar: resultSet.getString(resultSet.getColumnIndex('authorAvatar')),
      topicIds: resultSet.getString(resultSet.getColumnIndex('topicIds')),
      status: resultSet.getString(resultSet.getColumnIndex('status')),
      viewCount: resultSet.getLong(resultSet.getColumnIndex('viewCount')),
      likeCount: resultSet.getLong(resultSet.getColumnIndex('likeCount')),
      followerCount: resultSet.getLong(resultSet.getColumnIndex('followerCount')),
      answerCount: resultSet.getLong(resultSet.getColumnIndex('answerCount')),
      createdAt: resultSet.getString(resultSet.getColumnIndex('createdAt')),
      updatedAt: resultSet.getString(resultSet.getColumnIndex('updatedAt'))
    };
  }

  private static readAllAnswers(resultSet: relationalStore.ResultSet): AnswerRow[] {
    const rows: AnswerRow[] = [];
    while (resultSet.goToNextRow()) {
      rows.push(DatabaseHelper.buildAnswerRow(resultSet));
    }
    return rows;
  }

  private static buildAnswerRow(resultSet: relationalStore.ResultSet): AnswerRow {
    return {
      id: resultSet.getString(resultSet.getColumnIndex('id')),
      questionId: resultSet.getString(resultSet.getColumnIndex('questionId')),
      content: resultSet.getString(resultSet.getColumnIndex('content')),
      authorId: resultSet.getString(resultSet.getColumnIndex('authorId')),
      authorName: resultSet.getString(resultSet.getColumnIndex('authorName')),
      authorAvatar: resultSet.getString(resultSet.getColumnIndex('authorAvatar')),
      isAccepted: resultSet.getLong(resultSet.getColumnIndex('isAccepted')),
      likeCount: resultSet.getLong(resultSet.getColumnIndex('likeCount')),
      commentCount: resultSet.getLong(resultSet.getColumnIndex('commentCount')),
      createdAt: resultSet.getString(resultSet.getColumnIndex('createdAt'))
    };
  }
}
