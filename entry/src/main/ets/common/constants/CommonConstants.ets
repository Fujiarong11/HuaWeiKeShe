/**
 * 全局常量定义
 */

// 分页常量
export const PAGE_SIZE: number = 20;

// 排序方式
export enum AnswerSortType {
  DEFAULT = 'default',   // 采纳优先 + 点赞排序
  NEWEST = 'newest'      // 时间倒序
}

// 首页分类 Tab
export enum HomeTabType {
  RECOMMEND = 'recommend',
  HOT = 'hot',
  NEWEST = 'newest',
  FOLLOWING = 'following'
}
