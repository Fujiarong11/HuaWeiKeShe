/**
 * 话题数据模型
 */
@Observed
export class TopicModel {
  id: string = '';
  name: string = '';
  description: string = '';
  icon: string = '';
  color: string = '';
  followerCount: number = 0;
  questionCount: number = 0;
  isFollowed: boolean = false;
}
