/**
 * 首页推荐 ViewModel
 * 处理首页信息流的个性化推荐逻辑 — 全部走后端 API
 */
import { QuestionModel, QuestionStatus } from '../model/QuestionModel';
import { TopicModel } from '../model/TopicModel';
import { UserModel } from '../model/UserModel';
import { BasicDataSource } from '../common/datasource/BasicDataSource';
import { PAGE_SIZE, HomeTabType } from '../common/constants/CommonConstants';
import * as QuestionApi from '../api/QuestionApi';
import type { QuestionResponse } from '../api/QuestionApi';
import { getStore, getFollowedTopics } from '../store/DataStore';

@Observed
export class HomeViewModel {
  private static instance: HomeViewModel;

  // 数据源
  questionDataSource: BasicDataSource<QuestionModel> = new BasicDataSource();
  topicDataSource: BasicDataSource<TopicModel> = new BasicDataSource();

  // 状态
  isLoading: boolean = false;
  isRefreshing: boolean = false;
  hasMore: boolean = true;
  currentTab: HomeTabType = HomeTabType.RECOMMEND;
  currentPage: number = 1;
  errorMsg: string = '';

  static getInstance(): HomeViewModel {
    if (!HomeViewModel.instance) {
      HomeViewModel.instance = new HomeViewModel();
    }
    return HomeViewModel.instance;
  }

  private constructor() {}

  /**
   * 加载首页推荐内容（后端 API）
   */
  async loadRecommendFeed(userId: string, page: number = 1): Promise<void> {
    if (page === 1) {
      this.isRefreshing = true;
    } else {
      this.isLoading = true;
    }
    this.errorMsg = '';

    try {
      const res = this.currentTab === HomeTabType.HOT
        ? await QuestionApi.getHotQuestions(page, PAGE_SIZE)
        : this.currentTab === HomeTabType.NEWEST
          ? await QuestionApi.getQuestionList(page, PAGE_SIZE)
          : await QuestionApi.getRecommendedQuestions(userId, page, PAGE_SIZE);

      if (res.code === 0 && res.data) {
        const list: object[] = res.data as object[];
        const questions: QuestionModel[] = [];
        for (const item of list) {
          const r: QuestionResponse = item as QuestionResponse;
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
          q.createdAt = r.createdAt || '';
          q.updatedAt = r.updatedAt || '';
          questions.push(q);
        }

        if (page === 1) {
          this.questionDataSource.reloadData(questions);
        } else {
          this.questionDataSource.appendData(questions);
        }

        this.hasMore = questions.length >= PAGE_SIZE;
        this.currentPage = page;
      }
    } catch (e) {
      this.errorMsg = '加载失败，请下拉重试';
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  /**
   * 下拉刷新
   */
  async refresh(userId: string): Promise<void> {
    this.currentPage = 1;
    this.hasMore = true;
    await this.loadRecommendFeed(userId, 1);
  }

  /**
   * 加载更多
   */
  async loadMore(userId: string): Promise<void> {
    if (this.isLoading || !this.hasMore) {
      return;
    }
    await this.loadRecommendFeed(userId, this.currentPage + 1);
  }

  /**
   * 切换分类标签
   */
  async switchTab(tab: HomeTabType, userId: string): Promise<void> {
    this.currentTab = tab;
    this.currentPage = 1;
    this.hasMore = true;
    await this.loadRecommendFeed(userId, 1);
  }

  /**
   * 加载关注话题（顶部横滑栏）— 暂用本地，等待话题后端 API
   */
  async loadFollowedTopics(userId: string): Promise<void> {
    const topics = await getFollowedTopics(userId);
    this.topicDataSource.reloadData(topics);
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
