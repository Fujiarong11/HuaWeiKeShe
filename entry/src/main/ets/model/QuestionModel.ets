import { UserModel } from './UserModel';

/**
 * 问题状态枚举
 */
export enum QuestionStatus {
  PENDING = 'pending',
  OPEN = 'open',
  RESOLVED = 'resolved'
}

/**
 * 问题数据模型
 */
@Observed
export class QuestionModel {
  id: string = '';
  title: string = '';
  content: string = '';
  author: UserModel = new UserModel();
  topicIds: string[] = [];
  viewCount: number = 0;
  answerCount: number = 0;
  followerCount: number = 0;
  likeCount: number = 0;
  status: QuestionStatus = QuestionStatus.OPEN;
  isLiked: boolean = false;
  isCollected: boolean = false;
  createdAt: string = '';
  updatedAt: string = '';

  /** 格式化创建时间 */
  get formattedTime(): string {
    return formatRelativeTime(this.createdAt);
  }
}

/**
 * 将 ISO 时间字符串转换为相对时间描述
 */
export function formatRelativeTime(dateStr: string): string {
  if (!dateStr) {
    return '';
  }
  const now = new Date().getTime();
  const target = new Date(dateStr).getTime();
  const diff = now - target;
  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);

  if (minutes < 1) {
    return '刚刚';
  }
  if (minutes < 60) {
    return `${minutes}分钟前`;
  }
  if (hours < 24) {
    return `${hours}小时前`;
  }
  if (days < 30) {
    return `${days}天前`;
  }
  if (days < 365) {
    return `${Math.floor(days / 30)}个月前`;
  }
  return `${Math.floor(days / 365)}年前`;
}
