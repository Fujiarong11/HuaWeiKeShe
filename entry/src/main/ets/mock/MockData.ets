/**
 * 集中式数据层
 * 内存 store + DatabaseHelper 持久化（问题、回答存 DB，话题为系统预设）
 *
 * App 启动时从 DB 恢复数据到内存 store，运行时操作同步写 DB。
 * 注：此文件不再包含假数据种子，所有内容由真实用户产生。
 */
import { UserModel } from '../model/UserModel';
import { QuestionModel, QuestionStatus } from '../model/QuestionModel';
import { AnswerModel } from '../model/AnswerModel';
import { CommentModel, CommentTargetType } from '../model/CommentModel';
import { TopicModel } from '../model/TopicModel';
import { DatabaseHelper, QuestionRow, AnswerRow, UserRow } from '../data/DatabaseHelper';

// ============ 通知模型（内联定义）============

@Observed
export class NotificationItem {
  id: string = '';
  type: string = '';
  title: string = '';
  content: string = '';
  fromUserId: string = '';
  fromUserName: string = '';
  fromUserAvatar: string = '';
  targetQuestionId: string = '';
  targetAnswerId: string = '';
  isRead: boolean = false;
  createdAt: string = '';
}

// ============ 邀请模型 ============

@Observed
export class InviteRecord {
  id: string = '';
  questionId: string = '';
  fromUserId: string = '';
  toUserId: string = '';
  createdAt: string = '';
}

// ============ 数据仓库 ============

class MockDataStore {
  private static instance: MockDataStore;

  users: UserModel[] = [];
  questions: QuestionModel[] = [];
  answers: AnswerModel[] = [];
  comments: CommentModel[] = [];
  topics: TopicModel[] = [];
  notifications: NotificationItem[] = [];
  invites: InviteRecord[] = [];

  private nextUserId = 1;
  private nextQuestionId = 1;
  private nextAnswerId = 1;
  private nextCommentId = 1;
  private nextNotificationId = 1;
  private nextInviteId = 1;
  private nextTopicId = 6000; // 话题从 6000+ 开始，系统 20 个占用 6001-6020

  private dbLoaded: boolean = false;

  static getInstance(): MockDataStore {
    if (!MockDataStore.instance) {
      MockDataStore.instance = new MockDataStore();
      MockDataStore.instance.initSeedData();
    }
    return MockDataStore.instance;
  }

  genUserId(): string { return `u_${this.nextUserId++}`; }
  genQuestionId(): string { return `q_${this.nextQuestionId++}`; }
  genAnswerId(): string { return `a_${this.nextAnswerId++}`; }
  genCommentId(): string { return `c_${this.nextCommentId++}`; }
  genNotificationId(): string { return `n_${this.nextNotificationId++}`; }
  genInviteId(): string { return `inv_${this.nextInviteId++}`; }
  genTopicId(): string { return `t_${this.nextTopicId++}`; }

  private rand(min: number, max: number): number {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }

  private initSeedData(): void {
    // 只初始化系统话题预设数据，不再初始化假用户/假帖子
    this.seedTopics();
  }

  /**
   * 从 DB 加载问题和回答到内存 store（App 启动后调用一次）
   */
  async loadFromDb(): Promise<void> {
    if (this.dbLoaded) { return; }
    try {
      const dbQuestions: QuestionRow[] = await DatabaseHelper.queryAllQuestions();
      for (const row of dbQuestions) {
        const q: QuestionModel = this.rowToQuestionModel(row);
        this.questions.push(q);
      }

      // 恢复问题 ID 计数器
      if (dbQuestions.length > 0) {
        const maxQId: number = Math.max(...dbQuestions.map(r => {
          const parts: string[] = r.id.split('_');
          return parseInt(parts.length > 1 ? parts[1] : '0');
        }));
        this.nextQuestionId = maxQId + 1;
      }

      // 加载所有回答
      for (const q of this.questions) {
        const dbAnswers: AnswerRow[] = await DatabaseHelper.queryAnswersByQuestionId(q.id);
        for (const row of dbAnswers) {
          const a: AnswerModel = this.rowToAnswerModel(row);
          this.answers.push(a);
          q.answerCount++;
        }
      }

      if (this.answers.length > 0) {
        const maxAId: number = Math.max(...this.answers.map(a => {
          const parts: string[] = a.id.split('_');
          return parseInt(parts.length > 1 ? parts[1] : '0');
        }));
        this.nextAnswerId = maxAId + 1;
      }

      this.dbLoaded = true;
    } catch (err) {
      console.error('MockDataStore.loadFromDb failed:', JSON.stringify(err));
    }
  }

  /**
   * 从 DB 加载当前用户数据到内存 store（登录后调用）
   * 确保用户数据在内存 store 中存在，以便后续操作能找到 author
   */
  syncUserFromDb(userRow: UserRow): UserModel {
    // 解析关注话题 ID 列表
    let followedIds: string[] = [];
    try {
      const parsed: Object = JSON.parse(userRow.followedTopicIds) as Object;
      followedIds = parsed as string[];
    } catch (_e) {
      followedIds = [];
    }

    const existing: UserModel | undefined = this.users.find(u => u.id === userRow.id);
    if (existing) {
      existing.name = userRow.name || userRow.username;
      existing.avatar = userRow.avatar;
      existing.bio = userRow.bio;
      existing.college = userRow.college;
      existing.major = userRow.major;
      existing.grade = userRow.grade;
      existing.reputation = userRow.reputation;
      existing.acceptedCount = userRow.acceptedCount;
      existing.totalAnswers = userRow.totalAnswers;
      existing.totalQuestions = userRow.totalQuestions;
      existing.followerCount = userRow.followerCount;
      existing.followingCount = userRow.followingCount;
      existing.followedTopicIds = followedIds;
      this.restoreTopicFollowState(followedIds);
      return existing;
    }
    const u: UserModel = new UserModel();
    u.id = userRow.id;
    u.name = userRow.username || userRow.name;
    u.avatar = userRow.avatar;
    u.bio = userRow.bio;
    u.college = userRow.college;
    u.major = userRow.major;
    u.grade = userRow.grade;
    u.reputation = userRow.reputation;
    u.acceptedCount = userRow.acceptedCount;
    u.totalAnswers = userRow.totalAnswers;
    u.totalQuestions = userRow.totalQuestions;
    u.followerCount = userRow.followerCount;
    u.followingCount = userRow.followingCount;
    u.createdAt = userRow.createdAt;
    u.followedTopicIds = followedIds;
    this.users.push(u);
    this.restoreTopicFollowState(followedIds);
    return u;
  }

  /**
   * 根据用户已关注的话题 ID 列表，恢复 topics 中的 isFollowed 状态
   */
  private restoreTopicFollowState(followedIds: string[]): void {
    for (const tid of followedIds) {
      const topic: TopicModel | undefined = this.topics.find(t => t.id === tid);
      if (topic) {
        topic.isFollowed = true;
      }
    }
  }

  // ========== Row → Model 转换 ==========

  private rowToQuestionModel(row: QuestionRow): QuestionModel {
    const q: QuestionModel = new QuestionModel();
    q.id = row.id;
    q.title = row.title;
    q.content = row.content;
    // 懒加载 author：如果内存 store 有对应的用户就用，否则创建一个占位 UserModel
    const author: UserModel | undefined = this.users.find(u => u.id === row.authorId);
    if (author) {
      q.author = author;
    } else {
      const placeholder: UserModel = new UserModel();
      placeholder.id = row.authorId;
      placeholder.name = row.authorName;
      placeholder.avatar = row.authorAvatar;
      q.author = placeholder;
    }
    try {
      const parsed: Object = JSON.parse(row.topicIds) as Object;
      q.topicIds = parsed as string[];
    } catch (_e) {
      q.topicIds = [];
    }
    q.status = row.status === 'RESOLVED' ? QuestionStatus.RESOLVED : QuestionStatus.OPEN;
    q.viewCount = row.viewCount;
    q.likeCount = row.likeCount;
    q.followerCount = row.followerCount;
    q.answerCount = row.answerCount;
    q.createdAt = row.createdAt;
    q.updatedAt = row.updatedAt;
    return q;
  }

  private rowToAnswerModel(row: AnswerRow): AnswerModel {
    const a: AnswerModel = new AnswerModel();
    a.id = row.id;
    a.questionId = row.questionId;
    a.content = row.content;
    const author: UserModel | undefined = this.users.find(u => u.id === row.authorId);
    if (author) {
      a.author = author;
    } else {
      const placeholder: UserModel = new UserModel();
      placeholder.id = row.authorId;
      placeholder.name = row.authorName;
      placeholder.avatar = row.authorAvatar;
      a.author = placeholder;
    }
    a.isAccepted = row.isAccepted === 1;
    a.likeCount = row.likeCount;
    a.commentCount = row.commentCount;
    a.createdAt = row.createdAt;
    return a;
  }

  private questionToRow(q: QuestionModel): QuestionRow {
    const row: QuestionRow = {
      id: q.id,
      title: q.title,
      content: q.content,
      authorId: q.author.id,
      authorName: q.author.name,
      authorAvatar: q.author.avatar,
      topicIds: JSON.stringify(q.topicIds),
      status: q.status === QuestionStatus.RESOLVED ? 'RESOLVED' : 'OPEN',
      viewCount: q.viewCount,
      likeCount: q.likeCount,
      followerCount: q.followerCount,
      answerCount: q.answerCount,
      createdAt: q.createdAt,
      updatedAt: q.updatedAt
    };
    return row;
  }

  private answerToRow(a: AnswerModel): AnswerRow {
    const row: AnswerRow = {
      id: a.id,
      questionId: a.questionId,
      content: a.content,
      authorId: a.author.id,
      authorName: a.author.name,
      authorAvatar: a.author.avatar,
      isAccepted: a.isAccepted ? 1 : 0,
      likeCount: a.likeCount,
      commentCount: a.commentCount,
      createdAt: a.createdAt
    };
    return row;
  }

  // ========== 话题种子数据（系统预设，保留）==========

  private seedTopics(): void {
    this.topics = [];
    this.topics.push(this.createTopic('高等数学', '微积分、线性代数、概率论', '📐', '#4A90D9'));
    this.topics.push(this.createTopic('大学英语', '四六级、雅思托福、口语练习', '🇬🇧', '#E8634A'));
    this.topics.push(this.createTopic('程序设计', 'C/C++/Java/Python 编程答疑', '💻', '#5CB85C'));
    this.topics.push(this.createTopic('考研交流', '考研经验、资料分享、院校选择', '📚', '#F0AD4E'));
    this.topics.push(this.createTopic('就业实习', '简历修改、面试技巧、实习内推', '💼', '#9B59B6'));
    this.topics.push(this.createTopic('校园生活', '食堂美食、宿舍指南、校园活动', '🏫', '#1ABC9C'));
    this.topics.push(this.createTopic('恋爱情感', '情感咨询、恋爱技巧', '💕', '#E91E63'));
    this.topics.push(this.createTopic('新生专区', '报到指南、选课攻略、社团介绍', '🎓', '#FF9800'));
    this.topics.push(this.createTopic('考试资料', '期末考试、考证资料分享', '📝', '#607D8B'));
    this.topics.push(this.createTopic('科研学术', '论文写作、实验方法、学术会议', '🔬', '#3F51B5'));
    this.topics.push(this.createTopic('留学申请', '海外院校、语言考试、文书准备', '✈️', '#00BCD4'));
    this.topics.push(this.createTopic('技术开发', '前端后端、移动开发、AI 讨论', '⚡', '#FF5722'));
    this.topics.push(this.createTopic('二手交易', '教材转让、电子产品、生活用品', '🔄', '#795548'));
    this.topics.push(this.createTopic('社团活动', '社团纳新、活动通知、才艺展示', '🎉', '#8BC34A'));
    this.topics.push(this.createTopic('心理健康', '压力疏导、心理咨询、成长互助', '🧠', '#9C27B0'));
    this.topics.push(this.createTopic('体育运动', '健身打卡、球类约战、运动会', '⚽', '#F44336'));
    this.topics.push(this.createTopic('设计创意', '平面设计、UI/UX、摄影后期', '🎨', '#FF6F00'));
    this.topics.push(this.createTopic('考证攻略', '教资、会计、计算机等级考试', '📋', '#009688'));
    this.topics.push(this.createTopic('兼职信息', '校内勤工俭学、校外兼职', '💰', '#CDDC39'));
    this.topics.push(this.createTopic('毕业论文', '选题、开题、答辩经验分享', '📖', '#673AB7'));
  }

  private createTopic(name: string, description: string, icon: string, color: string): TopicModel {
    const t: TopicModel = new TopicModel();
    t.id = this.genTopicId();
    t.name = name;
    t.description = description;
    t.icon = icon;
    t.color = color;
    t.followerCount = this.rand(50, 550);
    t.questionCount = 0;
    return t;
  }
}

// ============ 辅助类型 ============

class ScoredQuestion {
  question: QuestionModel = new QuestionModel();
  score: number = 0;
}

// ============ 公开 API ============

export function getStore(): MockDataStore {
  return MockDataStore.getInstance();
}

function delay(ms: number = 300): Promise<void> {
  return new Promise<void>((resolve: Function) => {
    setTimeout(() => { resolve(); }, ms + Math.random() * 200);
  });
}

// ========== 问题相关 API ==========

export async function getQuestions(page: number = 1, pageSize: number = 20): Promise<QuestionModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const start: number = (page - 1) * pageSize;
  return store.questions.slice(start, start + pageSize);
}

export async function getQuestionById(id: string): Promise<QuestionModel | undefined> {
  await delay();
  const store: MockDataStore = getStore();
  const result: QuestionModel | undefined = store.questions.find(q => q.id === id);
  if (result) {
    result.viewCount++;
  }
  return result;
}

export async function getRecommendedQuestions(userId: string, page: number = 1, pageSize: number = 20): Promise<QuestionModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  // 简单排序：按创建时间倒序（最新），无用户画像时退化为最新列表
  const sorted: QuestionModel[] = [];
  for (const q of store.questions) {
    sorted.push(q);
  }
  sorted.sort((a: QuestionModel, b: QuestionModel) =>
    new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
  );
  const start: number = (page - 1) * pageSize;
  return sorted.slice(start, start + pageSize);
}

export async function getHotQuestions(limit: number = 10): Promise<QuestionModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const sorted: QuestionModel[] = [];
  for (const q of store.questions) {
    sorted.push(q);
  }
  sorted.sort((a: QuestionModel, b: QuestionModel) =>
    (b.likeCount * 1 + b.answerCount * 3 + b.viewCount * 0.5) -
    (a.likeCount * 1 + a.answerCount * 3 + a.viewCount * 0.5)
  );
  return sorted.slice(0, limit);
}

export async function getQuestionsByTopic(topicId: string, page: number = 1, pageSize: number = 20): Promise<QuestionModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const filtered: QuestionModel[] = [];
  for (const q of store.questions) {
    if (q.topicIds.includes(topicId)) {
      filtered.push(q);
    }
  }
  const start: number = (page - 1) * pageSize;
  return filtered.slice(start, start + pageSize);
}

export async function searchQuestions(keyword: string): Promise<QuestionModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const kw: string = keyword.toLowerCase();
  const result: QuestionModel[] = [];
  for (const q of store.questions) {
    if (q.title.toLowerCase().includes(kw) || q.content.toLowerCase().includes(kw)) {
      result.push(q);
    }
  }
  return result;
}

export async function searchAll(keyword: string): Promise<SearchAllResult> {
  await delay();
  const store: MockDataStore = getStore();
  const kw: string = keyword.toLowerCase();
  const questions: QuestionModel[] = [];
  const topics: TopicModel[] = [];
  const users: UserModel[] = [];
  for (const q of store.questions) {
    if (q.title.toLowerCase().includes(kw) || q.content.toLowerCase().includes(kw)) {
      questions.push(q);
    }
  }
  for (const t of store.topics) {
    if (t.name.toLowerCase().includes(kw) || t.description.toLowerCase().includes(kw)) {
      topics.push(t);
    }
  }
  for (const u of store.users) {
    if (u.name.toLowerCase().includes(kw) || u.college.toLowerCase().includes(kw) || u.bio.toLowerCase().includes(kw)) {
      users.push(u);
    }
  }
  const result: SearchAllResult = new SearchAllResult();
  result.questions = questions;
  result.topics = topics;
  result.users = users;
  return result;
}

export class SearchAllResult {
  questions: QuestionModel[] = [];
  topics: TopicModel[] = [];
  users: UserModel[] = [];
}

export async function postQuestion(title: string, content: string, topicIds: string[], authorId: string): Promise<QuestionModel> {
  await delay();
  const store: MockDataStore = getStore();
  const author: UserModel | undefined = store.users.find(u => u.id === authorId);
  const question: QuestionModel = new QuestionModel();
  question.id = store.genQuestionId();
  question.title = title;
  question.content = content;
  question.author = author ? author : new UserModel();
  question.topicIds = topicIds;
  question.status = QuestionStatus.OPEN;
  question.createdAt = new Date().toISOString();
  question.updatedAt = question.createdAt;
  store.questions.unshift(question);

  // 同步写入 DB
  const questionRow: QuestionRow = {
    id: question.id,
    title: question.title,
    content: question.content,
    authorId: question.author.id,
    authorName: question.author.name,
    authorAvatar: question.author.avatar,
    topicIds: JSON.stringify(question.topicIds),
    status: 'OPEN',
    viewCount: question.viewCount,
    likeCount: question.likeCount,
    followerCount: question.followerCount,
    answerCount: question.answerCount,
    createdAt: question.createdAt,
    updatedAt: question.updatedAt
  };
  DatabaseHelper.insertQuestion(questionRow);

  // 更新话题的问题数量
  for (const tid of topicIds) {
    const topic: TopicModel | undefined = store.topics.find(t => t.id === tid);
    if (topic) {
      topic.questionCount++;
    }
  }

  // 更新用户提问数
  if (author) {
    author.totalQuestions++;
    DatabaseHelper.updateUser({
      id: author.id,
      phone: author.id,
      username: author.name,
      password: '',
      name: author.name,
      avatar: author.avatar,
      bio: author.bio,
      college: author.college,
      major: author.major,
      grade: author.grade,
      reputation: author.reputation,
      acceptedCount: author.acceptedCount,
      totalAnswers: author.totalAnswers,
      totalQuestions: author.totalQuestions,
      followerCount: author.followerCount,
      followingCount: author.followingCount,
      followedTopicIds: JSON.stringify(author.followedTopicIds),
      createdAt: author.createdAt
    });
  }

  return question;
}

export async function toggleQuestionLike(questionId: string): Promise<QuestionModel | undefined> {
  await delay(100);
  const store: MockDataStore = getStore();
  const q: QuestionModel | undefined = store.questions.find(q => q.id === questionId);
  if (q) {
    q.isLiked = !q.isLiked;
    q.likeCount += q.isLiked ? 1 : -1;
  }
  return q;
}

export async function toggleQuestionCollect(questionId: string): Promise<QuestionModel | undefined> {
  await delay(100);
  const store: MockDataStore = getStore();
  const q: QuestionModel | undefined = store.questions.find(q => q.id === questionId);
  if (q) {
    q.isCollected = !q.isCollected;
    q.followerCount += q.isCollected ? 1 : -1;
  }
  return q;
}

// ========== 删除操作 ==========

export async function deleteQuestion(questionId: string): Promise<boolean> {
  await delay(100);
  const store: MockDataStore = getStore();
  const qIdx: number = store.questions.findIndex(q => q.id === questionId);
  if (qIdx < 0) { return false; }
  const question: QuestionModel = store.questions[qIdx];

  // 1. 从内存删除关联回答
  const remaining: AnswerModel[] = [];
  for (const a of store.answers) {
    if (a.questionId !== questionId) {
      remaining.push(a);
    }
  }
  store.answers = remaining;

  // 2. 从内存删除问题
  const newQuestions: QuestionModel[] = [];
  for (let i = 0; i < store.questions.length; i++) {
    if (i !== qIdx) { newQuestions.push(store.questions[i]); }
  }
  store.questions = newQuestions;

  // 3. 更新作者的总提问数
  const author: UserModel | undefined = store.users.find(u => u.id === question.author.id);
  if (author && author.totalQuestions > 0) {
    author.totalQuestions--;
  }

  // 4. 更新话题的问题数
  for (const tid of question.topicIds) {
    const topic: TopicModel | undefined = store.topics.find(t => t.id === tid);
    if (topic && topic.questionCount > 0) {
      topic.questionCount--;
    }
  }

  // 5. 持久化：删除 DB 中的回答和问题
  await DatabaseHelper.deleteAnswersByQuestionId(questionId);
  await DatabaseHelper.deleteQuestion(questionId);

  // 6. 更新作者数据到 DB
  if (author) {
    DatabaseHelper.updateUser({
      id: author.id,
      phone: author.id,
      username: author.name,
      password: '',
      name: author.name,
      avatar: author.avatar,
      bio: author.bio,
      college: author.college,
      major: author.major,
      grade: author.grade,
      reputation: author.reputation,
      acceptedCount: author.acceptedCount,
      totalAnswers: author.totalAnswers,
      totalQuestions: author.totalQuestions,
      followerCount: author.followerCount,
      followingCount: author.followingCount,
      followedTopicIds: JSON.stringify(author.followedTopicIds),
      createdAt: author.createdAt
    });
  }

  return true;
}

export async function deleteAnswer(answerId: string): Promise<boolean> {
  await delay(100);
  const store: MockDataStore = getStore();
  const aIdx: number = store.answers.findIndex(a => a.id === answerId);
  if (aIdx < 0) { return false; }
  const answer: AnswerModel = store.answers[aIdx];

  // 1. 从内存删除回答
  const remaining: AnswerModel[] = [];
  for (let i = 0; i < store.answers.length; i++) {
    if (i !== aIdx) { remaining.push(store.answers[i]); }
  }
  store.answers = remaining;

  // 2. 更新问题的回答数
  const question: QuestionModel | undefined = store.questions.find(q => q.id === answer.questionId);
  if (question && question.answerCount > 0) {
    question.answerCount--;
  }

  // 3. 更新作者的总回答数
  const author: UserModel | undefined = store.users.find(u => u.id === answer.author.id);
  if (author && author.totalAnswers > 0) {
    author.totalAnswers--;
  }

  // 4. 持久化
  await DatabaseHelper.deleteAnswer(answerId);
  if (question) {
    DatabaseHelper.updateQuestion({
      id: question.id,
      title: question.title,
      content: question.content,
      authorId: question.author.id,
      authorName: question.author.name,
      authorAvatar: question.author.avatar,
      topicIds: JSON.stringify(question.topicIds),
      status: question.status === QuestionStatus.RESOLVED ? 'RESOLVED' : 'OPEN',
      viewCount: question.viewCount,
      likeCount: question.likeCount,
      followerCount: question.followerCount,
      answerCount: question.answerCount,
      createdAt: question.createdAt,
      updatedAt: question.updatedAt
    });
  }
  if (author) {
    DatabaseHelper.updateUser({
      id: author.id,
      phone: author.id,
      username: author.name,
      password: '',
      name: author.name,
      avatar: author.avatar,
      bio: author.bio,
      college: author.college,
      major: author.major,
      grade: author.grade,
      reputation: author.reputation,
      acceptedCount: author.acceptedCount,
      totalAnswers: author.totalAnswers,
      totalQuestions: author.totalQuestions,
      followerCount: author.followerCount,
      followingCount: author.followingCount,
      followedTopicIds: JSON.stringify(author.followedTopicIds),
      createdAt: author.createdAt
    });
  }

  return true;
}

// ========== 回答相关 API ==========

export async function getAnswersByQuestionId(questionId: string): Promise<AnswerModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const filtered: AnswerModel[] = [];
  for (const a of store.answers) {
    if (a.questionId === questionId) {
      filtered.push(a);
    }
  }
  filtered.sort((a: AnswerModel, b: AnswerModel) => {
    if (a.isAccepted !== b.isAccepted) { return a.isAccepted ? -1 : 1; }
    return b.likeCount - a.likeCount;
  });
  return filtered;
}

export async function postAnswer(questionId: string, content: string, authorId: string): Promise<AnswerModel> {
  await delay();
  const store: MockDataStore = getStore();
  const author: UserModel | undefined = store.users.find(u => u.id === authorId);
  const answer: AnswerModel = new AnswerModel();
  answer.id = store.genAnswerId();
  answer.questionId = questionId;
  answer.content = content;
  answer.author = author ? author : new UserModel();
  answer.createdAt = new Date().toISOString();

  if (author) {
    author.totalAnswers += 1;
    author.reputation += 2;
  }

  store.answers.push(answer);

  const question: QuestionModel | undefined = store.questions.find(q => q.id === questionId);
  if (question) {
    question.answerCount++;
  }

  // 同步写入 DB
  const answerRow: AnswerRow = {
    id: answer.id,
    questionId: answer.questionId,
    content: answer.content,
    authorId: answer.author.id,
    authorName: answer.author.name,
    authorAvatar: answer.author.avatar,
    isAccepted: answer.isAccepted ? 1 : 0,
    likeCount: answer.likeCount,
    commentCount: answer.commentCount,
    createdAt: answer.createdAt
  };
  DatabaseHelper.insertAnswer(answerRow);

  // 更新用户数据
  if (author) {
    DatabaseHelper.updateUser({
      id: author.id,
      phone: author.id,
      username: author.name,
      password: '',
      name: author.name,
      avatar: author.avatar,
      bio: author.bio,
      college: author.college,
      major: author.major,
      grade: author.grade,
      reputation: author.reputation,
      acceptedCount: author.acceptedCount,
      totalAnswers: author.totalAnswers,
      totalQuestions: author.totalQuestions,
      followerCount: author.followerCount,
      followingCount: author.followingCount,
      followedTopicIds: JSON.stringify(author.followedTopicIds),
      createdAt: author.createdAt
    });
  }

  // 通知问题作者
  if (question && author && question.author.id !== authorId) {
    const noti: NotificationItem = new NotificationItem();
    noti.id = store.genNotificationId();
    noti.type = 'answer';
    noti.title = '新回答';
    noti.content = `${author.name}回答了你的问题"${question.title.substring(0, 20)}..."`;
    noti.fromUserId = authorId;
    noti.fromUserName = author.name;
    noti.fromUserAvatar = author.avatar;
    noti.targetQuestionId = questionId;
    noti.targetAnswerId = answer.id;
    noti.isRead = false;
    noti.createdAt = new Date().toISOString();
    store.notifications.unshift(noti);
  }

  return answer;
}

export async function acceptAnswer(answerId: string): Promise<AnswerModel | undefined> {
  await delay();
  const store: MockDataStore = getStore();
  const answer: AnswerModel | undefined = store.answers.find(a => a.id === answerId);
  if (answer) {
    answer.isAccepted = true;
    const question: QuestionModel | undefined = store.questions.find(q => q.id === answer.questionId);
    if (question) {
      question.status = QuestionStatus.RESOLVED;
    }
    const author: UserModel | undefined = store.users.find(u => u.id === answer.author.id);
    if (author) {
      author.reputation += 25;
      author.acceptedCount += 1;
      // 同步用户数据到 DB
      DatabaseHelper.updateUser({
        id: author.id,
        phone: author.id,
        username: author.name,
        password: '',
        name: author.name,
        avatar: author.avatar,
        bio: author.bio,
        college: author.college,
        major: author.major,
        grade: author.grade,
        reputation: author.reputation,
        acceptedCount: author.acceptedCount,
        totalAnswers: author.totalAnswers,
        totalQuestions: author.totalQuestions,
        followerCount: author.followerCount,
        followingCount: author.followingCount,
        followedTopicIds: JSON.stringify(author.followedTopicIds),
        createdAt: author.createdAt
      });
    }
  }
  return answer;
}

export async function toggleAnswerLike(answerId: string): Promise<AnswerModel | undefined> {
  await delay(100);
  const store: MockDataStore = getStore();
  const a: AnswerModel | undefined = store.answers.find(a => a.id === answerId);
  if (a) {
    a.isLiked = !a.isLiked;
    a.likeCount += a.isLiked ? 1 : -1;
  }
  return a;
}

// ========== 评论相关 API ==========

export async function getCommentsByTargetId(targetId: string): Promise<CommentModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const filtered: CommentModel[] = [];
  for (const c of store.comments) {
    if (c.targetId === targetId) {
      filtered.push(c);
    }
  }
  filtered.sort((a: CommentModel, b: CommentModel) =>
    new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
  );
  return filtered;
}

export async function postComment(targetId: string, targetType: CommentTargetType, content: string, authorId: string): Promise<CommentModel> {
  await delay();
  const store: MockDataStore = getStore();
  const author: UserModel | undefined = store.users.find(u => u.id === authorId);
  const comment: CommentModel = new CommentModel();
  comment.id = store.genCommentId();
  comment.targetId = targetId;
  comment.targetType = targetType;
  comment.content = content;
  comment.author = author ? author : new UserModel();
  comment.createdAt = new Date().toISOString();
  store.comments.push(comment);

  if (targetType === CommentTargetType.ANSWER) {
    const answer: AnswerModel | undefined = store.answers.find(a => a.id === targetId);
    if (answer) {
      answer.commentCount++;
    }
  }

  return comment;
}

// ========== 话题相关 API ==========

export async function getAllTopics(): Promise<TopicModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const result: TopicModel[] = [];
  for (const t of store.topics) {
    result.push(t);
  }
  return result;
}

export async function getFollowedTopics(userId: string): Promise<TopicModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const user: UserModel | undefined = store.users.find(u => u.id === userId);
  if (!user) {
    return [];
  }
  const result: TopicModel[] = [];
  for (const t of store.topics) {
    if (user.followedTopicIds.includes(t.id)) {
      result.push(t);
    }
  }
  return result;
}

export async function toggleTopicFollow(topicId: string, userId: string): Promise<TopicModel | undefined> {
  await delay(100);
  const store: MockDataStore = getStore();
  const topic: TopicModel | undefined = store.topics.find(t => t.id === topicId);
  const user: UserModel | undefined = store.users.find(u => u.id === userId);
  if (topic && user) {
    topic.isFollowed = !topic.isFollowed;
    topic.followerCount += topic.isFollowed ? 1 : -1;
    if (topic.isFollowed) {
      if (!user.followedTopicIds.includes(topicId)) {
        const newIds: string[] = [];
        for (const id of user.followedTopicIds) { newIds.push(id); }
        newIds.push(topicId);
        user.followedTopicIds = newIds;
      }
    } else {
      const newIds: string[] = [];
      for (const id of user.followedTopicIds) {
        if (id !== topicId) { newIds.push(id); }
      }
      user.followedTopicIds = newIds;
    }
    // 持久化到数据库
    DatabaseHelper.updateUserFollowedTopics(userId, JSON.stringify(user.followedTopicIds));
  }
  return topic;
}

// ========== 用户相关 API ==========

export async function getUserById(id: string): Promise<UserModel | undefined> {
  await delay();
  const store: MockDataStore = getStore();
  const found: UserModel | undefined = store.users.find(u => u.id === id);
  if (found) {
    return found;
  }
  // 内存中没有，尝试从 DB 查
  const dbUser: UserRow | null = await DatabaseHelper.queryUserById(id);
  if (dbUser) {
    return store.syncUserFromDb(dbUser);
  }
  return undefined;
}

/** @deprecated 不再硬编码返回假用户，改用 AppStorage 中的当前用户 */
export async function getCurrentUser(): Promise<UserModel> {
  await delay();
  // 返回 AppStorage 中的当前用户，如果没有则返回空 UserModel
  const currentUser: UserModel | undefined = AppStorage.get<UserModel>('currentUser');
  if (currentUser) {
    return currentUser;
  }
  return new UserModel();
}

export async function toggleFollowUser(targetUserId: string, currentUserId: string): Promise<UserModel | undefined> {
  await delay(100);
  const store: MockDataStore = getStore();
  const target: UserModel | undefined = store.users.find(u => u.id === targetUserId);
  const current: UserModel | undefined = store.users.find(u => u.id === currentUserId);
  if (target && current) {
    const isFollowing: boolean = current.followedUserIds.includes(targetUserId);
    if (isFollowing) {
      // 取消关注
      const newFollowed: string[] = [];
      for (const id of current.followedUserIds) {
        if (id !== targetUserId) { newFollowed.push(id); }
      }
      current.followedUserIds = newFollowed;
      current.followingCount = newFollowed.length;

      const newFollowers: string[] = [];
      for (const id of target.followerUserIds) {
        if (id !== currentUserId) { newFollowers.push(id); }
      }
      target.followerUserIds = newFollowers;
      target.followerCount = newFollowers.length;
    } else {
      // 关注
      const newFollowed: string[] = [];
      for (const id of current.followedUserIds) { newFollowed.push(id); }
      newFollowed.push(targetUserId);
      current.followedUserIds = newFollowed;
      current.followingCount = newFollowed.length;

      const newFollowers: string[] = [];
      for (const id of target.followerUserIds) { newFollowers.push(id); }
      newFollowers.push(currentUserId);
      target.followerUserIds = newFollowers;
      target.followerCount = newFollowers.length;
    }

    // 持久化关注/粉丝计数到数据库
    DatabaseHelper.updateUserFollowStats(currentUserId, current.followingCount, current.followerCount);
    DatabaseHelper.updateUserFollowStats(targetUserId, target.followingCount, target.followerCount);
  }
  return target;
}

/**
 * 检查当前用户是否关注了目标用户
 */
export async function isFollowingUser(currentUserId: string, targetUserId: string): Promise<boolean> {
  await delay(50);
  const store: MockDataStore = getStore();
  const current: UserModel | undefined = store.users.find(u => u.id === currentUserId);
  if (!current) { return false; }
  return current.followedUserIds.includes(targetUserId);
}

/**
 * 获取用户关注的人列表
 */
export async function getFollowingUsers(userId: string): Promise<UserModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const user: UserModel | undefined = store.users.find(u => u.id === userId);
  if (!user) { return []; }
  const result: UserModel[] = [];
  for (const id of user.followedUserIds) {
    const u: UserModel | undefined = store.users.find(u => u.id === id);
    if (u) { result.push(u); }
  }
  return result;
}

/**
 * 获取关注用户的粉丝列表
 */
export async function getFollowerUsers(userId: string): Promise<UserModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const user: UserModel | undefined = store.users.find(u => u.id === userId);
  if (!user) { return []; }
  const result: UserModel[] = [];
  for (const id of user.followerUserIds) {
    const u: UserModel | undefined = store.users.find(u => u.id === id);
    if (u) { result.push(u); }
  }
  return result;
}

// ========== 通知相关 API ==========

export async function getNotifications(userId: string): Promise<NotificationItem[]> {
  await delay();
  const store: MockDataStore = getStore();
  const result: NotificationItem[] = [];
  for (const n of store.notifications) { result.push(n); }
  result.sort((a: NotificationItem, b: NotificationItem) =>
    new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
  );
  return result;
}

export async function getUnreadNotificationCount(userId: string): Promise<number> {
  await delay(100);
  const store: MockDataStore = getStore();
  let count: number = 0;
  for (const n of store.notifications) {
    if (!n.isRead) { count++; }
  }
  return count;
}

export async function markNotificationRead(notificationId: string): Promise<void> {
  await delay(100);
  const store: MockDataStore = getStore();
  const noti: NotificationItem | undefined = store.notifications.find(n => n.id === notificationId);
  if (noti) { noti.isRead = true; }
}

// ========== 相关问题 ==========

export async function getRelatedQuestions(questionId: string, limit: number = 5): Promise<QuestionModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const sourceQ: QuestionModel | undefined = store.questions.find(q => q.id === questionId);
  if (!sourceQ) { return []; }
  const related: ScoredQuestion[] = [];
  for (const other of store.questions) {
    if (other.id === questionId) { continue; }
    let overlap: number = 0;
    for (const tid of other.topicIds) {
      if (sourceQ.topicIds.includes(tid)) { overlap++; }
    }
    if (overlap > 0) {
      const item: ScoredQuestion = new ScoredQuestion();
      item.question = other;
      item.score = other.likeCount + overlap * 10;
      related.push(item);
    }
  }
  related.sort((a: ScoredQuestion, b: ScoredQuestion) => b.score - a.score);
  const result: QuestionModel[] = [];
  for (let i = 0; i < Math.min(limit, related.length); i++) {
    result.push(related[i].question);
  }
  return result;
}
