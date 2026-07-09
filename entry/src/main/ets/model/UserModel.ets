/**
 * 用户数据模型
 */
@Observed
export class UserModel {
  id: string = '';
  name: string = '';
  avatar: string = '';
  bio: string = '';
  college: string = '';
  major: string = '';
  grade: string = '';
  reputation: number = 0;
  acceptedCount: number = 0;
  totalAnswers: number = 0;
  totalQuestions: number = 0;
  followerCount: number = 0;
  followingCount: number = 0;
  followedTopicIds: string[] = [];
  followedUserIds: string[] = [];
  followerUserIds: string[] = [];
  likedAnswerIds: string[] = [];
  collectedQuestionIds: string[] = [];
  createdAt: string = '';

  /** 采纳率 0-100 */
  get acceptanceRate(): number {
    const total: number = this.totalAnswers || 0;
    const accepted: number = this.acceptedCount || 0;
    if (total === 0) {
      return 0;
    }
    return Math.round((accepted / total) * 100);
  }
}

/**
 * 登录结果
 */
export interface LoginResult {
  success: boolean;
  user?: UserModel;
  token?: string;
  error?: string;
}

/**
 * 注册结果
 */
export interface RegisterResult {
  success: boolean;
  user?: UserModel;
  error?: string;
}

/**
 * 声望变化记录
 */
@Observed
export class ReputationRecord {
  id: string = '';
  userId: string = '';
  change: number = 0;
  reason: string = '';
  relatedId: string = '';
  createdAt: string = '';
}
