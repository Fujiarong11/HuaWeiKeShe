/**
 * 首页推荐 ViewModel
 * 处理首页信息流的个性化推荐逻辑
 */
import { QuestionModel } from '../model/QuestionModel';
import { TopicModel } from '../model/TopicModel';
import { BasicDataSource } from '../common/datasource/BasicDataSource';
import { PAGE_SIZE, HomeTabType } from '../common/constants/CommonConstants';
import {
  getRecommendedQuestions,
  getHotQuestions,
  getQuestions,
  getFollowedTopics
} from '../mock/MockData';

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
   * 加载首页推荐内容
   */
  async loadRecommendFeed(userId: string, page: number = 1): Promise<void> {
    if (page === 1) {
      this.isRefreshing = true;
    } else {
      this.isLoading = true;
    }
    this.errorMsg = '';

    try {
      let questions: QuestionModel[];
      switch (this.currentTab) {
        case HomeTabType.HOT:
          questions = await getHotQuestions(PAGE_SIZE);
          break;
        case HomeTabType.NEWEST:
          questions = await getQuestions(page, PAGE_SIZE);
          break;
        case HomeTabType.FOLLOWING:
          questions = await getRecommendedQuestions(userId, page, PAGE_SIZE);
          break;
        default:
          questions = await getRecommendedQuestions(userId, page, PAGE_SIZE);
      }

      if (page === 1) {
        this.questionDataSource.reloadData(questions);
      } else {
        this.questionDataSource.appendData(questions);
      }

      this.hasMore = questions.length >= PAGE_SIZE;
      this.currentPage = page;
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
   * 加载关注话题（顶部横滑栏）
   */
  async loadFollowedTopics(userId: string): Promise<void> {
    const topics = await getFollowedTopics(userId);
    this.topicDataSource.reloadData(topics);
  }
}
