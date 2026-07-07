/**
 * 全局常量定义
 */

// 分页常量
export const PAGE_SIZE: number = 20;
export const COMMENT_PAGE_SIZE: number = 10;

// AppStorage 键名
export const STORAGE_KEY_CURRENT_USER = 'currentUser';
export const STORAGE_KEY_CURRENT_USER_ID = 'currentUserId';
export const STORAGE_KEY_DEVICE_TYPE = 'deviceType';
export const STORAGE_KEY_UNREAD_COUNT = 'unreadNotificationCount';
export const STORAGE_KEY_IS_DARK_MODE = 'isDarkMode';

// 设备类型
export const DEVICE_TYPE_PHONE = 'phone';
export const DEVICE_TYPE_TABLET = 'tablet';

// 声望规则
export const REPUTATION_ACCEPTED = 25;
export const REPUTATION_ANSWER_LIKED = 10;
export const REPUTATION_QUESTION_LIKED = 5;
export const REPUTATION_POST_ANSWER = 2;
export const REPUTATION_FIRST_ANSWER = 5;

// 通知类型
export enum NotificationType {
  ANSWER = 'answer',
  COMMENT = 'comment',
  LIKE = 'like',
  ACCEPT = 'accept',
  FOLLOW = 'follow',
  INVITE = 'invite',
  SYSTEM = 'system'
}

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

// 搜索结果 Tab
export enum SearchResultTab {
  ALL = 'all',
  QUESTION = 'question',
  TOPIC = 'topic',
  USER = 'user'
}
