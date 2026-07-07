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

/**
 * 话题分类
 */
export enum TopicCategory {
  STUDY = '学业答疑',
  EXAM = '考研就业',
  LIFE = '校园生活',
  TECH = '技术讨论',
  FRESHMAN = '新生专区',
  CLUB = '社团活动'
}

/**
 * 话题分类颜色映射
 */
export const TOPIC_CATEGORY_COLORS: Record<string, string> = {
  '学业答疑': '#4A90D9',
  '考研就业': '#E8634A',
  '校园生活': '#5CB85C',
  '技术讨论': '#F0AD4E',
  '新生专区': '#9B59B6',
  '社团活动': '#1ABC9C'
};
