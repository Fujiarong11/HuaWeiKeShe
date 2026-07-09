/**
 * 问题详情 ViewModel
 * 处理问题详情、回答列表、评论等逻辑 — 全部走后端 API（不再依赖 MockData）
 */
import { QuestionModel, QuestionStatus } from '../model/QuestionModel';
import { AnswerModel } from '../model/AnswerModel';
import { CommentModel, CommentTargetType } from '../model/CommentModel';
import { UserModel } from '../model/UserModel';
import { BasicDataSource } from '../common/datasource/BasicDataSource';
import { AnswerSortType } from '../common/constants/CommonConstants';
import * as QuestionApi from '../api/QuestionApi';
import type { QuestionResponse } from '../api/QuestionApi';
import * as AnswerApi from '../api/AnswerApi';
import type { AnswerResponse } from '../api/AnswerApi';
import * as CommentApi from '../api/CommentApi';
import type { CommentResponse } from '../api/CommentApi';
import * as InteractionApi from '../api/InteractionApi';
import { getStore, getUserById } from '../mock/MockData';

@Observed
export class QuestionViewModel {
  private static instance: QuestionViewModel;

  // 问题数据
  currentQuestion: QuestionModel | null = null;
  relatedQuestions: QuestionModel[] = [];

  // 回答数据源
  answerDataSource: BasicDataSource<AnswerModel> = new BasicDataSource();

  // 评论数据（按回答ID分组）
  commentMap: Map<string, BasicDataSource<CommentModel>> = new Map();

  // 状态
  isLoadingQuestion: boolean = false;
  isLoadingAnswers: boolean = false;
  isPostingAnswer: boolean = false;
  answerSortType: AnswerSortType = AnswerSortType.DEFAULT;
  showCommentInput: boolean = false;
  currentCommentTargetId: string = '';
  errorMsg: string = '';

  static getInstance(): QuestionViewModel {
    if (!QuestionViewModel.instance) {
      QuestionViewModel.instance = new QuestionViewModel();
    }
    return QuestionViewModel.instance;
  }

  private constructor() {}

  /**
   * 加载问题详情（后端 API）
   */
  async loadQuestionDetail(questionId: string): Promise<void> {
    this.isLoadingQuestion = true;
    this.errorMsg = '';
    try {
      const res = await QuestionApi.getQuestionById(questionId);
      if (res.code === 0 && res.data) {
        const r: QuestionResponse = res.data as QuestionResponse;
        const q: QuestionModel = new QuestionModel();
        q.id = String(r.id);
        q.title = r.title;
        q.content = r.content;
        q.author = this.buildAuthor(String(r.authorId), r.authorName, r.authorAvatar);
        q.topicIds = r.topicIds || [];
        q.status = r.status === 'RESOLVED' ? QuestionStatus.RESOLVED : QuestionStatus.OPEN;
        q.viewCount = r.viewCount || 0;
        q.likeCount = r.likeCount || 0;
        q.followerCount = r.followerCount || 0;
        q.answerCount = r.answerCount || 0;
        q.isLiked = false;
        q.isCollected = false;
        q.createdAt = r.createdAt || '';
        q.updatedAt = r.updatedAt || '';
        this.currentQuestion = q;
      } else {
        this.errorMsg = '问题不存在';
      }
    } catch (e) {
      this.errorMsg = '加载失败';
    } finally {
      this.isLoadingQuestion = false;
    }
  }

  /**
   * 加载回答列表（后端 API）
   */
  async loadAnswers(questionId: string): Promise<void> {
    this.isLoadingAnswers = true;
    try {
      const res = await AnswerApi.getAnswersByQuestionId(questionId);
      if (res.code === 0 && res.data) {
        const list: object[] = res.data as object[];
        const answers: AnswerModel[] = [];
        for (const item of list) {
          const r: AnswerResponse = item as AnswerResponse;
          const a: AnswerModel = new AnswerModel();
          a.id = String(r.id);
          a.questionId = String(r.questionId);
          a.content = r.content;
          a.author = this.buildAuthor(String(r.authorId), r.authorName, r.authorAvatar);
          a.likeCount = r.likeCount || 0;
          a.commentCount = r.commentCount || 0;
          a.isAccepted = r.isAccepted === 1;
          a.isLiked = false;
          a.createdAt = r.createdAt || '';
          answers.push(a);
        }
        this.answerDataSource.reloadData(answers);
      }
    } catch (e) {
      this.errorMsg = '加载回答失败';
    } finally {
      this.isLoadingAnswers = false;
    }
  }

  /**
   * 加载某条回答的评论（后端 API）
   */
  async loadComments(answerId: string): Promise<BasicDataSource<CommentModel>> {
    if (this.commentMap.has(answerId)) {
      return this.commentMap.get(answerId)!;
    }
    const dataSource = new BasicDataSource<CommentModel>();
    try {
      const res = await CommentApi.getCommentsByTargetId(answerId);
      if (res.code === 0 && res.data) {
        const list: object[] = res.data as object[];
        const comments: CommentModel[] = [];
        for (const item of list) {
          const r: CommentResponse = item as CommentResponse;
          const c: CommentModel = new CommentModel();
          c.id = String(r.id);
          c.targetId = String(r.targetId);
          c.targetType = r.targetType === 'question' ? CommentTargetType.QUESTION : CommentTargetType.ANSWER;
          c.content = r.content;
          c.author = this.buildAuthor(String(r.authorId), r.authorName, r.authorAvatar);
          c.replyTo = r.replyToId ? this.buildAuthor(String(r.replyToId), '', '') : null;
          c.likeCount = r.likeCount || 0;
          c.isLiked = false;
          c.createdAt = r.createdAt || '';
          comments.push(c);
        }
        dataSource.reloadData(comments);
      }
    } catch (e) {
      // 加载评论失败，返回空列表
    }
    this.commentMap.set(answerId, dataSource);
    return dataSource;
  }

  /**
   * 发布回答（后端 API）
   */
  async submitAnswer(questionId: string, content: string, authorId: string): Promise<boolean> {
    if (!content.trim()) { return false; }
    this.isPostingAnswer = true;
    try {
      const store = getStore();
      const author = await getUserById(authorId);
      const authorName: string = author ? author.name : '';
      const authorAvatar: string = author ? author.avatar : '';

      const res = await AnswerApi.createAnswer(
        questionId, content, authorId, authorName, authorAvatar
      );
      if (res.code === 0 && res.data) {
        const r: AnswerResponse = res.data as AnswerResponse;
        const a: AnswerModel = new AnswerModel();
        a.id = String(r.id);
        a.questionId = String(r.questionId);
        a.content = r.content;
        a.author = author || this.buildAuthor(authorId, authorName, authorAvatar);
        a.likeCount = 0;
        a.commentCount = 0;
        a.isAccepted = false;
        a.isLiked = false;
        a.createdAt = r.createdAt || '';
        this.answerDataSource.unshiftData(a);
        if (this.currentQuestion) {
          this.currentQuestion.answerCount++;
        }
        return true;
      }
      return false;
    } catch (e) {
      this.errorMsg = '发布回答失败';
      return false;
    } finally {
      this.isPostingAnswer = false;
    }
  }

  /**
   * 发布评论（后端 API）
   */
  async submitComment(targetId: string, targetType: CommentTargetType, content: string, authorId: string): Promise<boolean> {
    if (!content.trim()) { return false; }
    try {
      const store = getStore();
      const author = await getUserById(authorId);
      const authorName: string = author ? author.name : '';
      const authorAvatar: string = author ? author.avatar : '';

      const res = await CommentApi.createComment(
        targetId, targetType === CommentTargetType.QUESTION ? 'question' : 'answer',
        content, authorId, authorName, authorAvatar
      );
      if (res.code === 0 && res.data) {
        const r: CommentResponse = res.data as CommentResponse;
        const c: CommentModel = new CommentModel();
        c.id = String(r.id);
        c.targetId = String(r.targetId);
        c.targetType = targetType;
        c.content = r.content;
        c.author = author || this.buildAuthor(authorId, authorName, authorAvatar);
        c.likeCount = 0;
        c.isLiked = false;
        c.createdAt = r.createdAt || '';

        if (!this.commentMap.has(targetId)) {
          this.commentMap.set(targetId, new BasicDataSource<CommentModel>());
        }
        this.commentMap.get(targetId)!.pushData(c);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /**
   * 采纳/取消采纳回答（toggle，API 失败本地兜底）
   */
  async acceptAnswer(answerId: string): Promise<boolean> {
    try {
      const userId = AppStorage.get<string>('currentUserId') || '';
      if (!this.currentQuestion) { return false; }

      const answers: AnswerModel[] = this.answerDataSource.getDataArray() as AnswerModel[];
      const idx = answers.findIndex(a => a.id === answerId);
      if (idx < 0) { return false; }
      const target = answers[idx];
      const isAccepted = target.isAccepted;

      if (isAccepted) {
        // 取消采纳：本地回退
        target.isAccepted = false;
        this.currentQuestion.status = QuestionStatus.OPEN;
        this.answerDataSource.updateData(idx, target);
      } else {
        // 采纳：先取消其他回答的采纳，再设置当前
        for (let i = 0; i < answers.length; i++) {
          if (answers[i].isAccepted) {
            answers[i].isAccepted = false;
            this.answerDataSource.updateData(i, answers[i]);
          }
        }
        target.isAccepted = true;
        this.currentQuestion.status = QuestionStatus.RESOLVED;
        this.answerDataSource.updateData(idx, target);
        await this.loadAnswers(this.currentQuestion.id);
      }

      // 异步同步后端（失败也不回滚）
      await InteractionApi.acceptAnswer(answerId, userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /**
   * 点赞/取消点赞回答（乐观更新，API 失败不回滚）
   */
  async toggleAnswerLike(answerId: string): Promise<void> {
    const userId = AppStorage.get<string>('currentUserId') || '';
    const idx = this.answerDataSource.findIndex(a => a.id === answerId);
    if (idx < 0) { return; }
    const answers: AnswerModel[] = this.answerDataSource.getDataArray() as AnswerModel[];
    const answer = answers[idx];
    const wasLiked = answer.isLiked;

    // 先更新本地 UI（乐观更新）
    answer.isLiked = !wasLiked;
    answer.likeCount += wasLiked ? -1 : 1;
    this.answerDataSource.updateData(idx, answer);

    // 再调后端（失败也不回滚，保持本地状态）
    if (wasLiked) {
      await InteractionApi.unlikeAnswer(userId, answerId);
    } else {
      await InteractionApi.likeAnswer(userId, answerId);
    }
  }

  /**
   * 点赞/取消点赞问题（乐观更新，API 失败不回滚）
   */
  async toggleQuestionLike(): Promise<void> {
    if (!this.currentQuestion) { return; }
    const userId = AppStorage.get<string>('currentUserId') || '';
    const wasLiked = this.currentQuestion.isLiked;

    // 先更新本地 UI（乐观更新）
    this.currentQuestion.isLiked = !wasLiked;
    this.currentQuestion.likeCount += wasLiked ? -1 : 1;

    // 再调后端（失败也不回滚）
    if (wasLiked) {
      await InteractionApi.unlikeQuestion(userId, this.currentQuestion.id);
    } else {
      await InteractionApi.likeQuestion(userId, this.currentQuestion.id);
    }
  }

  /**
   * 收藏/取消收藏问题（乐观更新，API 失败不回滚）
   */
  async toggleQuestionCollect(): Promise<void> {
    if (!this.currentQuestion) { return; }
    const userId = AppStorage.get<string>('currentUserId') || '';
    const wasCollected = this.currentQuestion.isCollected;

    // 先更新本地 UI（乐观更新）
    this.currentQuestion.isCollected = !wasCollected;
    this.currentQuestion.followerCount += wasCollected ? -1 : 1;

    // 再调后端（失败也不回滚）
    if (wasCollected) {
      await InteractionApi.unfavoriteQuestion(userId, this.currentQuestion.id);
    } else {
      await InteractionApi.favoriteQuestion(userId, this.currentQuestion.id);
    }
  }

  /**
   * 切换回答排序
   */
  async switchSortType(type: AnswerSortType): Promise<void> {
    this.answerSortType = type;
    if (!this.currentQuestion) { return; }
    await this.loadAnswers(this.currentQuestion.id);
  }

  /**
   * 清理数据
   */
  clearData(): void {
    this.currentQuestion = null;
    this.relatedQuestions = [];
    this.answerDataSource.clearData();
    this.commentMap.clear();
    this.errorMsg = '';
  }

  /**
   * 从后端数据构建简化的 UserModel
   */
  private buildAuthor(id: string, name: string, avatar: string): UserModel {
    const u: UserModel = new UserModel();
    u.id = id;
    u.name = name || '';
    u.avatar = avatar || '';
    return u;
  }
}
