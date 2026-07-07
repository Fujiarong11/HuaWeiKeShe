/**
 * 问题详情 ViewModel
 * 处理问题详情、回答列表、评论等逻辑
 */
import { QuestionModel, QuestionStatus } from '../model/QuestionModel';
import { AnswerModel } from '../model/AnswerModel';
import { CommentModel, CommentTargetType } from '../model/CommentModel';
import { BasicDataSource } from '../common/datasource/BasicDataSource';
import { AnswerSortType } from '../common/constants/CommonConstants';
import {
  getQuestionById,
  getAnswersByQuestionId,
  getCommentsByTargetId,
  postAnswer,
  postComment,
  acceptAnswer,
  toggleAnswerLike,
  toggleQuestionLike,
  toggleQuestionCollect,
  getRelatedQuestions
} from '../mock/MockData';

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
   * 加载问题详情
   */
  async loadQuestionDetail(questionId: string): Promise<void> {
    this.isLoadingQuestion = true;
    this.errorMsg = '';
    try {
      const question = await getQuestionById(questionId);
      if (question) {
        this.currentQuestion = question;
        // 同时加载相关问题
        const related = await getRelatedQuestions(questionId);
        this.relatedQuestions = related;
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
   * 加载回答列表
   */
  async loadAnswers(questionId: string): Promise<void> {
    this.isLoadingAnswers = true;
    try {
      const answers = await getAnswersByQuestionId(questionId);
      this.answerDataSource.reloadData(answers);
    } catch (e) {
      this.errorMsg = '加载回答失败';
    } finally {
      this.isLoadingAnswers = false;
    }
  }

  /**
   * 加载某条回答的评论
   */
  async loadComments(answerId: string): Promise<BasicDataSource<CommentModel>> {
    if (this.commentMap.has(answerId)) {
      return this.commentMap.get(answerId)!;
    }
    const comments = await getCommentsByTargetId(answerId);
    const dataSource = new BasicDataSource<CommentModel>();
    dataSource.reloadData(comments);
    this.commentMap.set(answerId, dataSource);
    return dataSource;
  }

  /**
   * 发布回答
   */
  async submitAnswer(questionId: string, content: string, authorId: string): Promise<boolean> {
    if (!content.trim()) { return false; }
    this.isPostingAnswer = true;
    try {
      const answer = await postAnswer(questionId, content, authorId);
      this.answerDataSource.unshiftData(answer);
      if (this.currentQuestion) {
        this.currentQuestion.answerCount++;
      }
      return true;
    } catch (e) {
      this.errorMsg = '发布回答失败';
      return false;
    } finally {
      this.isPostingAnswer = false;
    }
  }

  /**
   * 发布评论
   */
  async submitComment(targetId: string, targetType: CommentTargetType, content: string, authorId: string): Promise<boolean> {
    if (!content.trim()) { return false; }
    try {
      const comment = await postComment(targetId, targetType, content, authorId);
      if (!this.commentMap.has(targetId)) {
        this.commentMap.set(targetId, new BasicDataSource<CommentModel>());
      }
      this.commentMap.get(targetId)!.pushData(comment);
      return true;
    } catch (e) {
      return false;
    }
  }

  /**
   * 采纳回答
   */
  async acceptAnswer(answerId: string): Promise<boolean> {
    try {
      const answer = await acceptAnswer(answerId);
      if (answer && this.currentQuestion) {
        this.currentQuestion.status = QuestionStatus.RESOLVED;
        // 重新加载回答列表以更新排序（采纳的置顶）
        await this.loadAnswers(this.currentQuestion.id);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /**
   * 点赞回答
   */
  async toggleAnswerLike(answerId: string): Promise<void> {
    const answer = await toggleAnswerLike(answerId);
    if (answer) {
      const idx = this.answerDataSource.findIndex(a => a.id === answerId);
      if (idx >= 0) {
        this.answerDataSource.updateData(idx, answer);
      }
    }
  }

  /**
   * 点赞问题
   */
  async toggleQuestionLike(): Promise<void> {
    if (!this.currentQuestion) { return; }
    const q = await toggleQuestionLike(this.currentQuestion.id);
    if (q) { this.currentQuestion = q; }
  }

  /**
   * 收藏问题
   */
  async toggleQuestionCollect(): Promise<void> {
    if (!this.currentQuestion) { return; }
    const q = await toggleQuestionCollect(this.currentQuestion.id);
    if (q) { this.currentQuestion = q; }
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
}
