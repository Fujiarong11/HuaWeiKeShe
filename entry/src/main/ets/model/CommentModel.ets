import { UserModel } from './UserModel';
import { formatRelativeTime } from './QuestionModel';

/**
 * 评论目标类型
 */
export enum CommentTargetType {
  QUESTION = 'question',
  ANSWER = 'answer'
}

/**
 * 评论数据模型
 */
@Observed
export class CommentModel {
  id: string = '';
  targetId: string = '';
  targetType: CommentTargetType = CommentTargetType.ANSWER;
  content: string = '';
  author: UserModel = new UserModel();
  replyTo: UserModel | null = null;
  likeCount: number = 0;
  isLiked: boolean = false;
  createdAt: string = '';

  get formattedTime(): string {
    return formatRelativeTime(this.createdAt);
  }
}
