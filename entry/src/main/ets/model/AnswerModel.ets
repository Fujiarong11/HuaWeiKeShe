import { UserModel } from './UserModel';
import { formatRelativeTime } from './QuestionModel';

/**
 * 回答数据模型
 */
@Observed
export class AnswerModel {
  id: string = '';
  questionId: string = '';
  content: string = '';
  author: UserModel = new UserModel();
  likeCount: number = 0;
  commentCount: number = 0;
  isAccepted: boolean = false;
  isLiked: boolean = false;
  createdAt: string = '';

  get formattedTime(): string {
    return formatRelativeTime(this.createdAt);
  }
}
