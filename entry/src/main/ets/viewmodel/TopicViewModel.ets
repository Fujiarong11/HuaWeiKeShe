/**
 * 话题广场 ViewModel
 * 处理话题列表、分类、关注等功能
 */
import { TopicModel } from '../model/TopicModel';
import { BasicDataSource } from '../common/datasource/BasicDataSource';
import { getAllTopics, toggleTopicFollow } from '../store/DataStore';

@Observed
export class TopicViewModel {
  private static instance: TopicViewModel;

  allTopics: TopicModel[] = [];
  allTopicDataSource: BasicDataSource<TopicModel> = new BasicDataSource();
  followedTopicDataSource: BasicDataSource<TopicModel> = new BasicDataSource();
  isLoading: boolean = false;
  searchKeyword: string = '';

  static getInstance(): TopicViewModel {
    if (!TopicViewModel.instance) {
      TopicViewModel.instance = new TopicViewModel();
    }
    return TopicViewModel.instance;
  }

  private constructor() {}

  /**
   * 加载所有话题
   */
  async loadAllTopics(): Promise<void> {
    this.isLoading = true;
    try {
      this.allTopics = await getAllTopics();
      this.applyFilter();
    } catch (e) {
      // 加载失败保持旧数据
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 搜索过滤话题
   */
  searchTopics(keyword: string): void {
    this.searchKeyword = keyword;
    this.applyFilter();
  }

  /**
   * 应用过滤和排序
   */
  private applyFilter(): void {
    let list = [...this.allTopics];

    // 关键词过滤
    if (this.searchKeyword.trim()) {
      const kw = this.searchKeyword.toLowerCase();
      list = list.filter(t =>
        t.name.toLowerCase().includes(kw) || t.description.toLowerCase().includes(kw)
      );
    }

    // 排序：已关注 > 热门(关注人数) > 问题数
    list.sort((a, b) => {
      if (a.isFollowed !== b.isFollowed) { return a.isFollowed ? -1 : 1; }
      if (a.followerCount !== b.followerCount) { return b.followerCount - a.followerCount; }
      return b.questionCount - a.questionCount;
    });

    this.allTopicDataSource.reloadData(list);
    this.followedTopicDataSource.reloadData(list.filter(t => t.isFollowed));
  }

  /**
   * 关注/取消关注话题
   */
  async toggleFollow(topicId: string, userId: string): Promise<void> {
    const updated = await toggleTopicFollow(topicId, userId);
    if (updated) {
      // 更新 allTopics 中的数据
      const idx = this.allTopics.findIndex(t => t.id === topicId);
      if (idx >= 0) {
        this.allTopics[idx] = updated;
      }
      this.applyFilter();
    }
  }
}
