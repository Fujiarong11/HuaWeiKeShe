/**
 * 集中式数据层
 * 内存 store + DatabaseHelper 持久化（问题、回答存 DB，话题为系统预设）
 *
 * App 启动时从 DB 恢复数据到内存 store，运行时操作同步写 DB。
 * 注：此文件不再包含假数据种子，所有内容由真实用户产生。
 */
import { UserModel } from '../model/UserModel';
import { QuestionModel, QuestionStatus } from '../model/QuestionModel';
import { AnswerModel } from '../model/AnswerModel';
import { CommentModel, CommentTargetType } from '../model/CommentModel';
import { TopicModel } from '../model/TopicModel';
import { DatabaseHelper, QuestionRow, AnswerRow, UserRow } from '../data/DatabaseHelper';

// ============ 通知模型（内联定义）============

@Observed
export class NotificationItem {
  id: string = '';
  type: string = '';
  title: string = '';
  content: string = '';
  fromUserId: string = '';
  fromUserName: string = '';
  fromUserAvatar: string = '';
  targetQuestionId: string = '';
  targetAnswerId: string = '';
  isRead: boolean = false;
  createdAt: string = '';
}

// ============ 邀请模型 ============

@Observed
export class InviteRecord {
  id: string = '';
  questionId: string = '';
  fromUserId: string = '';
  toUserId: string = '';
  createdAt: string = '';
}

// ============ 种子问题数据类型 ============

interface SeedQuestionData {
  t: string;   // title
  c: string;   // content
  p: string[]; // topicIds
  a: string;   // authorId
  d: string;   // createdAt
}

// ============ 数据仓库 ============

export class MockDataStore {
  private static instance: MockDataStore;

  users: UserModel[] = [];
  questions: QuestionModel[] = [];
  answers: AnswerModel[] = [];
  comments: CommentModel[] = [];
  topics: TopicModel[] = [];
  notifications: NotificationItem[] = [];
  invites: InviteRecord[] = [];

  private nextUserId = 1;
  private nextQuestionId = 1;
  private nextAnswerId = 1;
  private nextCommentId = 1;
  private nextNotificationId = 1;
  private nextInviteId = 1;
  private nextTopicId = 6000; // 话题从 6000+ 开始，系统 20 个占用 6001-6020

  private dbLoaded: boolean = false;

  static getInstance(): MockDataStore {
    if (!MockDataStore.instance) {
      MockDataStore.instance = new MockDataStore();
      MockDataStore.instance.initSeedData();
    }
    return MockDataStore.instance;
  }

  genUserId(): string { return `u_${this.nextUserId++}`; }
  genQuestionId(): string { return `q_${this.nextQuestionId++}`; }
  genAnswerId(): string { return `a_${this.nextAnswerId++}`; }
  genCommentId(): string { return `c_${this.nextCommentId++}`; }
  genNotificationId(): string { return `n_${this.nextNotificationId++}`; }
  genInviteId(): string { return `inv_${this.nextInviteId++}`; }
  genTopicId(): string { return `t_${this.nextTopicId++}`; }

  private rand(min: number, max: number): number {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }

  private initSeedData(): void {
    this.seedTopics();
    this.seedUsers();
    this.seedQuestions();
  }

  // ========== 种子用户（纯内存，不写 DB）==========

  private seedUsers(): void {
    const u1: UserModel = new UserModel();
    u1.id = 'u_seed_1'; u1.name = '小明学长'; u1.avatar = '';
    u1.bio = '计算机科学与技术专业，热爱编程与分享';
    u1.college = '信息科学与技术学院'; u1.major = '计算机科学与技术'; u1.grade = '大三';
    u1.reputation = 520; u1.acceptedCount = 18; u1.totalAnswers = 45; u1.totalQuestions = 8;
    u1.followerCount = 3; u1.followingCount = 2;
    u1.followedTopicIds = ['t_6002','t_6005','t_6011'];
    u1.createdAt = '2025-09-01T08:00:00Z';
    this.users.push(u1);

    const u2: UserModel = new UserModel();
    u2.id = 'u_seed_2'; u2.name = '图书馆常驻选手'; u2.avatar = '';
    u2.bio = '考研备考中，偶尔分享学习心得';
    u2.college = '数学科学学院'; u2.major = '数学与应用数学'; u2.grade = '大四';
    u2.reputation = 380; u2.acceptedCount = 12; u2.totalAnswers = 32; u2.totalQuestions = 5;
    u2.followerCount = 2; u2.followingCount = 1;
    u2.followedTopicIds = ['t_6000','t_6003','t_6012'];
    u2.createdAt = '2025-09-01T08:00:00Z';
    this.users.push(u2);

    const u3: UserModel = new UserModel();
    u3.id = 'u_seed_3'; u3.name = '校园树洞'; u3.avatar = '';
    u3.bio = '匿名分享校园生活大小事';
    u3.college = '文学院'; u3.major = '汉语言文学'; u3.grade = '大三';
    u3.reputation = 710; u3.acceptedCount = 25; u3.totalAnswers = 58; u3.totalQuestions = 12;
    u3.followerCount = 5; u3.followingCount = 3;
    u3.followedTopicIds = ['t_6005','t_6007','t_6013','t_6014'];
    u3.createdAt = '2025-09-01T08:00:00Z';
    this.users.push(u3);
  }

  // ========== 种子问题（纯内存，不写 DB）==========

  private seedQuestions(): void {
    const data: SeedQuestionData[] = [
      // ====== 高等数学 t_6000 ======
      { t: '可微与可导的区别到底是什么？', c: '高数课上说可微一定可导，但反过来成立吗？有没有反例可以直观理解？', p: ['t_6000'], a: 'u_seed_2', d: '2026-06-15T10:30:00Z' },
      { t: '二重积分换元法有没有什么技巧？', c: '每次做二重积分换元，Jacobian公式就记混…求大神分享记忆方法', p: ['t_6000','t_6012'], a: 'u_seed_1', d: '2026-06-20T14:20:00Z' },
      { t: '线性代数里特征值和特征向量到底有什么用？', c: '上课讲了半天只会算，完全不知道实际意义，学这个到底能干嘛？求通俗解释', p: ['t_6000'], a: 'u_seed_3', d: '2026-06-24T16:45:00Z' },
      { t: '泰勒公式展开到第几项？考试有没有判断技巧？', c: '每次做到泰勒展开就不确定要展到第几项，展开少了怕不够、多了又浪费时间', p: ['t_6000'], a: 'u_seed_2', d: '2026-07-02T11:20:00Z' },
      { t: '概率论排列组合总算不对，有什么解题套路吗？', c: '一到排列组合就犯迷糊，什么时候用A什么时候用C总是搞混，有没有好记的解题框架？', p: ['t_6000','t_6008'], a: 'u_seed_1', d: '2026-07-05T19:00:00Z' },
      // ====== 大学英语 t_6001 ======
      { t: '四级听力前5题总是听不懂怎么办？', c: '每次Section A的前5题都是听一遍就过了，完全跟不上节奏，有什么训练方法吗？', p: ['t_6001'], a: 'u_seed_3', d: '2026-06-18T09:15:00Z' },
      { t: '六级作文模板求推荐', c: '12月考六级，作文一直是我的弱项，有没有靠谱的模板可以推荐？', p: ['t_6001','t_6012'], a: 'u_seed_2', d: '2026-07-02T16:45:00Z' },
      { t: '英语口语太差了怎么办？有什么高效练习方法？', c: '学了这么多年英语还是不敢开口说，一开口就卡壳。有没有适合社恐的口语提升方法？', p: ['t_6001'], a: 'u_seed_1', d: '2026-06-28T14:30:00Z' },
      { t: '有什么好用的背单词APP推荐？', c: '墨墨、百词斩、不背单词都用过了，感觉效果都一般。大家用哪个APP坚持下来的？', p: ['t_6001'], a: 'u_seed_3', d: '2026-07-03T09:00:00Z' },
      { t: '不出国的话考雅思还是托福更有含金量？', c: '暂时没有出国打算，但想考个英语证书给简历加分。雅思和托福在国内求职中哪个认可度更高？', p: ['t_6001','t_6004'], a: 'u_seed_2', d: '2026-07-07T20:15:00Z' },
      // ====== 程序设计 t_6002 ======
      { t: 'Java和Python选哪个入门比较好？', c: '大一新生，下学期要选编程课，纠结Java还是Python，综合来看哪个更适合零基础？', p: ['t_6002'], a: 'u_seed_1', d: '2026-06-25T11:10:00Z' },
      { t: 'LeetCode刷题顺序推荐', c: '听说校招面试都要考算法，想开始刷LeetCode，该按什么顺序刷？easy->medium->hard还是按标签分类？', p: ['t_6002'], a: 'u_seed_3', d: '2026-07-01T20:30:00Z' },
      { t: '数据结构怎么学才不会忘？', c: '链表、栈、队列还勉强记得，一到二叉树和图就懵了。到底该怎么学数据结构才能真正掌握？', p: ['t_6002'], a: 'u_seed_2', d: '2026-06-21T10:00:00Z' },
      { t: 'Git 怎么用？小组合作代码老冲突快疯了', c: '每次和队友合并代码都是一场灾难，冲突解决不来、还经常丢代码。有没有适合小白的Git教程？', p: ['t_6002','t_6011'], a: 'u_seed_1', d: '2026-07-04T15:40:00Z' },
      { t: '面向对象编程的封装继承多态到底怎么理解？', c: '书上定义都背下来了，但一到实际写代码就不知道怎么设计类。有没有通俗易懂的例子？', p: ['t_6002'], a: 'u_seed_3', d: '2026-06-17T12:00:00Z' },
      // ====== 考研交流 t_6003 ======
      { t: '考研数学跟张宇还是汤家凤？', c: '25考研，数学一。听说张宇偏难、汤家凤偏基础，有没有过来人给点建议？', p: ['t_6003'], a: 'u_seed_2', d: '2026-05-10T08:00:00Z' },
      { t: '408专业课复习时间线', c: '跨考计算机，408四门课完全没学过，从现在开始还来得及吗？求复习规划', p: ['t_6003','t_6002'], a: 'u_seed_1', d: '2026-06-08T12:00:00Z' },
      { t: '每天复习多长时间比较合理？求考研作息表', c: '大三开始备考，平时还要上课，不知道每天该分配多少时间给考研。求上岸学长学姐分享每日作息', p: ['t_6003'], a: 'u_seed_3', d: '2026-06-14T22:30:00Z' },
      { t: '考研要不要报班？自学和报班哪个效果好？', c: '身边同学都报了考研班，费用动辄上万。有没有自学上岸的分享一下经验？报班到底值不值？', p: ['t_6003'], a: 'u_seed_2', d: '2026-06-26T17:00:00Z' },
      { t: '二本考985有希望吗？想听听真实经历', c: '二本院校想考985研究生，身边人都说难度太大。有没有逆袭上岸的学长学姐分享一下心路历程？', p: ['t_6003'], a: 'u_seed_1', d: '2026-07-03T23:15:00Z' },
      // ====== 就业实习 t_6004 ======
      { t: '大一暑假能找到实习吗？', c: '才学了一学期编程，暑假想找实习积累经验，是不是太早了？有什么适合低年级的实习岗位推荐？', p: ['t_6004'], a: 'u_seed_3', d: '2026-06-22T15:30:00Z' },
      { t: '互联网寒冬校招还有什么方向？', c: '感觉大厂都在裁员，25届校招是不是很难？除了互联网还有哪些行业值得投？', p: ['t_6004','t_6011'], a: 'u_seed_1', d: '2026-07-03T09:00:00Z' },
      { t: '简历上一片空白怎么办？没有实习经历怎么写简历？', c: '大三了还没有实习经历，简历上只有课程项目，感觉投出去都没人看。怎么包装课程项目？', p: ['t_6004'], a: 'u_seed_2', d: '2026-06-19T12:30:00Z' },
      { t: '技术岗面试一般问什么？有没有面经分享？', c: '第一次找实习完全不知道面试会问什么，据说有手撕代码、系统设计？求校招生分享真实面试经历', p: ['t_6004','t_6002'], a: 'u_seed_3', d: '2026-07-05T10:45:00Z' },
      { t: '国企和互联网大厂怎么选？求过来人分析利弊', c: '家里人希望我考国企图稳定，但自己想去互联网多学技术拿高薪。长远来看哪个选择更好？', p: ['t_6004'], a: 'u_seed_1', d: '2026-07-08T21:00:00Z' },
      // ====== 校园生活 t_6005 ======
      { t: '东区食堂哪家麻辣烫最好吃？', c: '新来的大一不太了解，求老生安利！东区食堂一楼的张记和二楼的川味哪个更值得排队？', p: ['t_6005'], a: 'u_seed_3', d: '2026-06-12T18:00:00Z' },
      { t: '图书馆选座攻略', c: '每次去图书馆都找不到好位置，哪些区域空调最舒适、声音最小？分享几个冷门好座位', p: ['t_6005'], a: 'u_seed_2', d: '2026-07-05T07:30:00Z' },
      { t: '宿舍晚上断电断网怎么办？', c: '11点就断电断网了，有时候作业还没写完。有什么应对方法？笔记本电池撑不了多久啊', p: ['t_6005'], a: 'u_seed_1', d: '2026-06-10T22:30:00Z' },
      { t: '校园卡丢了补办流程求告知', c: '今天不小心把校园卡弄丢了，补办要带什么材料？去哪里办？大概多久能拿到新卡？', p: ['t_6005'], a: 'u_seed_3', d: '2026-07-01T08:00:00Z' },
      { t: '学校附近有没有便宜的健身房推荐？', c: '想开始健身但预算有限，学校周边有没有月卡100以内的健身房？环境怎么样？', p: ['t_6005','t_6015'], a: 'u_seed_2', d: '2026-06-22T14:00:00Z' },
      // ====== 恋爱情感 t_6006 ======
      { t: '大学谈恋爱真的影响学习吗？', c: '家长说大学谈恋爱会耽误学习，但我看周围情侣学习也不错，到底有没有影响？过来人说说', p: ['t_6006'], a: 'u_seed_3', d: '2026-06-28T21:00:00Z' },
      { t: '喜欢上同班同学但不知道怎么开口', c: '暗恋同班一个同学好久了，平时也有一起上课但就是不敢表白，怕被拒绝后连朋友都做不成', p: ['t_6006'], a: 'u_seed_1', d: '2026-07-02T23:00:00Z' },
      { t: '异地恋坚持不下去了怎么办？', c: '异地两年了，见面越来越少、吵架越来越多。感觉彼此都在硬撑，该不该放手？', p: ['t_6006'], a: 'u_seed_2', d: '2026-06-18T20:00:00Z' },
      { t: '分手后怎么快速走出来？', c: '分手一个月了还是走不出来，看到ta朋友圈就很难受。有什么好的方法转移注意力？', p: ['t_6006','t_6014'], a: 'u_seed_3', d: '2026-07-06T01:30:00Z' },
      { t: '情侣日常开销怎么分配比较合理？', c: '和对象在一起半年了，之前都是AA但总觉得怪怪的。大家都是怎么处理恋爱开销的？', p: ['t_6006'], a: 'u_seed_1', d: '2026-06-25T17:00:00Z' },
      // ====== 新生专区 t_6007 ======
      { t: '宿舍必备物品清单求补充！', c: '马上报到了，已经准备：床帘、台灯、插线板、晾衣架。还有什么宿舍必需品求补充！', p: ['t_6007'], a: 'u_seed_3', d: '2026-07-08T10:00:00Z' },
      { t: '学校附近有什么好吃的？', c: '新生报到第三天，食堂吃腻了，求推荐学校周边性价比高的餐馆和小吃街', p: ['t_6007','t_6005'], a: 'u_seed_1', d: '2026-07-08T12:30:00Z' },
      { t: '军训有什么需要注意的？求过来人经验', c: '下个月要军训了，听说很累。求学长学姐分享军训必备物品和注意事项，不想晒成黑炭', p: ['t_6007'], a: 'u_seed_2', d: '2026-06-30T16:00:00Z' },
      { t: '选课系统怎么抢课？有什么技巧？', c: '新生第一次选课完全不知道流程，听说热门课几秒就抢完。有没有抢课技巧或者浏览器推荐？', p: ['t_6007'], a: 'u_seed_3', d: '2026-07-07T09:00:00Z' },
      { t: '校园网怎么连？Windows和Mac都要教程', c: '刚办好校园网账号但怎么也连不上，求Windows和Mac的详细连接教程，最好有截图', p: ['t_6007','t_6011'], a: 'u_seed_1', d: '2026-07-08T14:00:00Z' },
      // ====== 考试资料 t_6008 ======
      { t: '期末毛概重点有分享的吗？', c: '马上期末了，毛概还没复习完，有没有学长学姐整理的重点笔记？感激不尽！', p: ['t_6008'], a: 'u_seed_2', d: '2026-06-30T19:00:00Z' },
      { t: '大物实验报告怎么写拿高分？', c: '每次实验报告都被批"缺少误差分析"，到底该怎么写？求模板参考', p: ['t_6008'], a: 'u_seed_1', d: '2026-07-04T14:00:00Z' },
      { t: '马原期末考试有没有题库可以参考？', c: '马原内容太多了背不完，听说有历年真题库可以刷，有人知道在哪里可以找到吗？', p: ['t_6008'], a: 'u_seed_3', d: '2026-06-28T21:30:00Z' },
      { t: '高数下期末考试重点整理求分享', c: '高数下涵盖多元函数、曲线曲面积分、级数，有没有整理好的思维导图或重点笔记？', p: ['t_6008','t_6000'], a: 'u_seed_1', d: '2026-07-03T11:00:00Z' },
      { t: '四六级真题电子版求分享', c: '想开始刷真题了，求四六级历年真题PDF，最好带听力音频和答案解析的', p: ['t_6008','t_6001'], a: 'u_seed_2', d: '2026-07-06T15:00:00Z' },
      // ====== 科研学术 t_6009 ======
      { t: '本科生要不要进实验室？', c: '大二了，老师问要不要进他的实验室做项目，但担心影响课业，取舍之间怎么决策？', p: ['t_6009'], a: 'u_seed_2', d: '2026-06-10T16:00:00Z' },
      { t: '怎么找导师做科研项目？', c: '对科研很感兴趣但不知道怎么联系导师，发邮件应该怎么写？需要准备什么材料？', p: ['t_6009'], a: 'u_seed_1', d: '2026-06-20T10:30:00Z' },
      { t: '论文投稿被拒了怎么办？心态崩了', c: '第一篇论文投出去两个月收到desk reject，感觉自己的研究方向是不是没有价值。怎么调整心态？', p: ['t_6009'], a: 'u_seed_3', d: '2026-07-02T15:00:00Z' },
      { t: '大创项目申报书怎么写容易过？', c: '想申报国家级大创但不知道申报书怎么写才能脱颖而出，求往年成功案例参考', p: ['t_6009'], a: 'u_seed_2', d: '2026-06-25T09:00:00Z' },
      { t: '本科生发论文现实吗？有没有经验分享？', c: '听说本科生发SCI很难，想问问有没有成功发表的学长学姐分享一下投稿经验', p: ['t_6009'], a: 'u_seed_1', d: '2026-07-05T20:00:00Z' },
      // ====== 留学申请 t_6010 ======
      { t: 'GPA 3.2 能申到美硕CS吗？', c: '想去美国读CS硕士，但GPA只有3.2，还有没有希望？哪些学校对GPA要求相对宽松？', p: ['t_6010'], a: 'u_seed_3', d: '2026-06-05T11:00:00Z' },
      { t: '留学中介到底有没有必要找？', c: '准备出国读研但纠结要不要找中介，DIY到底难不难？中介费用动辄几万到底值不值？', p: ['t_6010'], a: 'u_seed_2', d: '2026-06-15T14:00:00Z' },
      { t: '托福和雅思哪个更好考？', c: '目标美英混申，不知道该考托福还是雅思，有人两个都考过吗？哪个更容易出分？', p: ['t_6010','t_6001'], a: 'u_seed_1', d: '2026-07-01T10:00:00Z' },
      { t: '推荐信找谁写比较靠谱？', c: '跟老师都不太熟，不知道怎么开口要推荐信。找辅导员写行不行？或者有什么技巧让老师愿意帮忙？', p: ['t_6010'], a: 'u_seed_3', d: '2026-06-22T16:30:00Z' },
      { t: '留学费用大概多少？有没有奖学金可以申请？', c: '家境一般但想去英国读一年硕，总花费大概多少？有没有针对中国留学生的奖学金？', p: ['t_6010'], a: 'u_seed_2', d: '2026-07-04T12:00:00Z' },
      // ====== 技术开发 t_6011 ======
      { t: '想学前端开发应该从哪里开始？', c: '完全零基础想学前端，HTML/CSS/JS/Vue/React这么多技术栈，应该按什么顺序学？', p: ['t_6011'], a: 'u_seed_1', d: '2026-06-19T13:00:00Z' },
      { t: '鸿蒙开发有前途吗？', c: '学校开了HarmonyOS选修课，值得学吗？市场上对鸿蒙开发的需求怎么样？', p: ['t_6011','t_6004'], a: 'u_seed_3', d: '2026-07-06T10:30:00Z' },
      { t: '后端学Java还是Go好就业？', c: '想做后端开发，大厂好像都在转Go，但市面上Java岗位还是最多的。怎么选？', p: ['t_6011','t_6004'], a: 'u_seed_2', d: '2026-06-28T11:00:00Z' },
      { t: '如何搭建自己的个人博客？', c: '想建一个个人技术博客来写学习笔记和项目总结，用什么框架搭比较好？Hexo还是VuePress？', p: ['t_6011'], a: 'u_seed_1', d: '2026-07-03T17:00:00Z' },
      { t: 'AI 方向怎么入门？需要哪些数学基础？', c: '想往AI方向发展但不知道从何入手，需要学哪些数学知识？Python要掌握到什么程度？', p: ['t_6011','t_6009'], a: 'u_seed_3', d: '2026-07-07T22:00:00Z' },
      // ====== 二手交易 t_6012 ======
      { t: '出大物上下册教材，九五新', c: '上完大物课教材就没用了，九五新上下册一起出，价格好商量，有需要的联系', p: ['t_6012'], a: 'u_seed_2', d: '2026-07-01T17:00:00Z' },
      { t: '求购二手显示器，预算500以内', c: '想配个外接显示器写代码用，27寸以下就行，预算500，有毕业学长出闲置的吗？', p: ['t_6012'], a: 'u_seed_1', d: '2026-06-24T13:00:00Z' },
      { t: '毕业清仓，台灯、风扇、书架便宜出', c: '大四离校带不走的全都便宜出了，台灯20、小风扇15、三层书架30，先到先得', p: ['t_6012'], a: 'u_seed_3', d: '2026-07-02T09:00:00Z' },
      { t: '二手交易平台哪个靠谱？', c: '闲鱼上骗子太多了，有没有校内专属的二手交易群或者平台？求拉', p: ['t_6012'], a: 'u_seed_2', d: '2026-06-18T18:00:00Z' },
      { t: '出全新未拆封机械键盘，买错了轴体', c: '买了一个红轴机械键盘但更喜欢青轴手感，全新未拆封原价350现260出，有要的吗？', p: ['t_6012'], a: 'u_seed_1', d: '2026-07-05T12:30:00Z' },
      // ====== 社团活动 t_6013 ======
      { t: '街舞社招新什么时候开始？', c: '看到表演被圈粉了！街舞社这学期什么时候招新？零基础可以加入吗？', p: ['t_6013'], a: 'u_seed_3', d: '2026-07-07T15:00:00Z' },
      { t: '哪个社团比较好玩又不会太忙？', c: '想参加社团丰富大学生活但又不想太占用学习时间，有没有氛围好活动适度的社团推荐？', p: ['t_6013'], a: 'u_seed_1', d: '2026-06-20T14:00:00Z' },
      { t: '摄影社和动漫社哪个更适合社恐？', c: '比较内向想通过社团交朋友，摄影社和动漫社哪个氛围更友好？社恐能融入吗？', p: ['t_6013'], a: 'u_seed_2', d: '2026-06-27T19:00:00Z' },
      { t: '社团面试一般问什么？需要准备才艺吗？', c: '看到好多社团都要面试，有点紧张。一般会问哪些问题？真的需要展示才艺吗？', p: ['t_6013','t_6007'], a: 'u_seed_3', d: '2026-07-04T11:00:00Z' },
      { t: '学生会和社团活动哪个更值得参加？', c: '时间有限只能选一个，学生会和社团活动对毕业就业和能力的提升哪个更大？', p: ['t_6013'], a: 'u_seed_1', d: '2026-06-23T16:00:00Z' },
      // ====== 心理健康 t_6014 ======
      { t: '期末压力大到失眠，怎么办？', c: '考试周每天晚上脑子里都在想复习内容，翻来覆去睡不着。有什么缓解焦虑的方法？', p: ['t_6014'], a: 'u_seed_1', d: '2026-07-04T23:00:00Z' },
      { t: '大学孤独感很重，怎么交到真心朋友？', c: '来大学一年了，虽然认识很多人但感觉都是表面关系，没有真正的朋友。正常吗？', p: ['t_6014'], a: 'u_seed_3', d: '2026-06-16T22:00:00Z' },
      { t: '心理咨询中心靠谱吗？去过的来说说', c: '最近状态很差想去学校心理咨询中心看看，但又怕被别人知道。去过的同学觉得有效果吗？', p: ['t_6014'], a: 'u_seed_2', d: '2026-06-29T15:00:00Z' },
      { t: '社恐怎么办？课堂presentation紧张到手抖', c: '每次做课堂展示就紧张到发抖，声音也变小了。有什么克服演讲恐惧的方法？', p: ['t_6014'], a: 'u_seed_1', d: '2026-07-02T10:00:00Z' },
      { t: '总觉得周围的人都很优秀，自己好差', c: '看着同学拿奖学金、进实验室、找实习，自己好像什么都做不好。怎么摆脱这种自我否定的情绪？', p: ['t_6014'], a: 'u_seed_3', d: '2026-07-06T00:30:00Z' },
      // ====== 体育运动 t_6015 ======
      { t: '羽毛球场地太难抢了！', c: '体育馆的羽毛球场地永远约不上，大家都是什么时候去抢的？有没有替代方案？', p: ['t_6015'], a: 'u_seed_2', d: '2026-06-27T16:30:00Z' },
      { t: '零基础学游泳，学校游泳馆有教练吗？', c: '从小没学过游泳想趁大学学会，学校游泳馆有没有教练？多少钱一节课？', p: ['t_6015'], a: 'u_seed_3', d: '2026-07-01T14:00:00Z' },
      { t: '想跑步减肥，操场一般几点开门？', c: '打算每天早上跑步减肥，操场跑道是全天开放的吗？早上几点可以进去？', p: ['t_6015'], a: 'u_seed_1', d: '2026-06-19T06:30:00Z' },
      { t: '有没有一起打篮球的？求球友', c: '技术一般但很热爱，周末想组个养生篮球局，水平不限，有人一起吗？', p: ['t_6015'], a: 'u_seed_2', d: '2026-06-25T18:00:00Z' },
      { t: '运动会报名了1500米，怎么训练？', c: '一时冲动报了运动会1500米，现在慌得不行。有没有科学的训练计划？只有一个月的准备时间', p: ['t_6015'], a: 'u_seed_3', d: '2026-07-05T21:00:00Z' },
      // ====== 设计创意 t_6016 ======
      { t: 'PS 有没有快速入门的方法？', c: '想做海报但完全不会Photoshop，网上教程太多看不完，有没有针对小白的快速入门路线？', p: ['t_6016'], a: 'u_seed_3', d: '2026-06-14T20:00:00Z' },
      { t: 'PPT怎么做才能不土？求设计模板', c: '每次做的PPT都被说像汇报材料，有没有好看的PPT模板网站推荐？免费的更好', p: ['t_6016'], a: 'u_seed_1', d: '2026-06-21T15:00:00Z' },
      { t: '想学视频剪辑，PR还是剪映？', c: '想做Vlog记录大学生活，PR太复杂了，剪映够用吗？有没有适合学生的剪辑软件推荐？', p: ['t_6016'], a: 'u_seed_2', d: '2026-07-01T20:00:00Z' },
      { t: '摄影新手买什么相机好？', c: '想入门摄影但预算有限，入门单反和微单怎么选？有没有3000以内的推荐？', p: ['t_6016'], a: 'u_seed_3', d: '2026-06-28T12:00:00Z' },
      { t: 'UI设计需要学哪些软件？', c: '对界面设计感兴趣想自学UI，需要掌握哪些设计软件？Figma好还是Sketch好？', p: ['t_6016'], a: 'u_seed_1', d: '2026-07-04T16:00:00Z' },
      // ====== 考证攻略 t_6017 ======
      { t: '计算机二级考C还是考Python？', c: '下学期想考计算机二级证书，办公类还是编程类比较好？C语言和Python哪个更好过？', p: ['t_6017'], a: 'u_seed_1', d: '2026-06-23T09:00:00Z' },
      { t: '教资考试非师范生可以考吗？', c: '非师范专业大三在读，想考教师资格证当个备选。非师范生能考吗？需要什么条件？', p: ['t_6017'], a: 'u_seed_3', d: '2026-06-15T10:30:00Z' },
      { t: '驾驶证在学校附近哪个驾校好？', c: '想趁大学把驾照拿了，学校附近驾校太多了不知道怎么选。有没有拿证的同学推荐？', p: ['t_6017'], a: 'u_seed_2', d: '2026-07-02T14:00:00Z' },
      { t: '大学期间考哪些证书含金量比较高？', c: '不想浪费时间考没用的证书，求过来人推荐大学期间最值得考的几个证书', p: ['t_6017','t_6004'], a: 'u_seed_1', d: '2026-06-29T11:00:00Z' },
      { t: '初级会计证难吗？非财会专业好考不？', c: '想考初级会计证充实简历，完全零基础非财会专业，自学能过吗？大概要准备多久？', p: ['t_6017'], a: 'u_seed_3', d: '2026-07-05T08:00:00Z' },
      // ====== 兼职信息 t_6018 ======
      { t: '校内勤工俭学岗位怎么申请？', c: '想在图书馆或行政楼找个勤工俭学的岗位，减轻家里负担，有人知道怎么申请吗？', p: ['t_6018'], a: 'u_seed_3', d: '2026-06-16T11:30:00Z' },
      { t: '家教怎么找？有没有靠谱平台推荐？', c: '想利用周末做家教赚生活费，但不知道去哪里找靠谱的家教信息。有好的平台或群推荐吗？', p: ['t_6018'], a: 'u_seed_2', d: '2026-06-22T09:00:00Z' },
      { t: '写文案兼职日结靠谱吗？', c: '看到网上很多写文案日结的兼职广告，一天几百块靠谱吗？会不会是骗人的？', p: ['t_6018'], a: 'u_seed_1', d: '2026-07-01T16:00:00Z' },
      { t: '暑假工去工厂好还是做服务行业好？', c: '暑假不想回家，想留在学校附近打工。工厂流水线和餐厅服务员哪个更推荐？', p: ['t_6018'], a: 'u_seed_3', d: '2026-06-27T13:00:00Z' },
      { t: '靠奖学金和兼职够生活费吗？经验分享', c: '不想跟家里要太多钱，靠奖学金和兼职能覆盖日常生活费和学费吗？有没有过来人分享经验', p: ['t_6018'], a: 'u_seed_2', d: '2026-07-06T19:00:00Z' },
      // ====== 毕业论文 t_6019 ======
      { t: '毕业论文选题怎么选才不会踩坑？', c: '大四了要开始定毕设题目，怎么选才能既有研究价值又不至于做不出来？求导师视角的建议', p: ['t_6019'], a: 'u_seed_2', d: '2026-06-29T14:00:00Z' },
      { t: '查重怎么降？从30%降到10%求方法', c: '初稿查重率30%心态崩了，引用部分也标红了怎么办？有没有靠谱的降重技巧？', p: ['t_6019'], a: 'u_seed_1', d: '2026-07-03T10:00:00Z' },
      { t: '论文排版格式老是调不对怎么办？', c: 'Word排版快疯了，目录页码对不齐、页眉页脚搞不定。有没有毕业论文排版模板？', p: ['t_6019'], a: 'u_seed_3', d: '2026-07-05T15:30:00Z' },
      { t: '答辩PPT怎么做？有没有模板分享？', c: '毕业答辩PPT不知道怎么做才算合格，应该放多少页？要包含哪些内容？有没有模板分享？', p: ['t_6019'], a: 'u_seed_2', d: '2026-07-07T11:00:00Z' },
      { t: '论文致谢可以写有趣一点吗？', c: '看到网上有些致谢写得特别好玩又感人，但导师说致谢要严肃一点。到底能不能写得有趣些？', p: ['t_6019'], a: 'u_seed_1', d: '2026-07-08T17:00:00Z' },
    ];

    for (const it of data) {
      const q: QuestionModel = new QuestionModel();
      q.id = this.genQuestionId();
      q.title = it.t;
      q.content = it.c;
      q.topicIds = it.p;
      q.status = QuestionStatus.OPEN;
      q.viewCount = this.rand(30, 280);
      q.likeCount = this.rand(2, 45);
      q.followerCount = this.rand(1, 12);
      q.answerCount = 0;
      q.createdAt = it.d;
      q.updatedAt = it.d;

      const author: UserModel | undefined = this.users.find(u => u.id === it.a);
      if (author) {
        q.author = author;
        author.totalQuestions++;
      }

      this.questions.push(q);

      for (const tid of it.p) {
        const topic: TopicModel | undefined = this.topics.find(t => t.id === tid);
        if (topic) { topic.questionCount++; }
      }
    }
  }

  /**
   * 从 DB 加载问题和回答到内存 store（App 启动后调用一次）
   */
  async loadFromDb(): Promise<void> {
    if (this.dbLoaded) { return; }
    try {
      const dbQuestions: QuestionRow[] = await DatabaseHelper.queryAllQuestions();

      for (const row of dbQuestions) {
        const q: QuestionModel = this.rowToQuestionModel(row);
        this.questions.push(q);
      }

      // 恢复问题 ID 计数器
      if (dbQuestions.length > 0) {
        const maxQId: number = Math.max(...dbQuestions.map(r => {
          const parts: string[] = r.id.split('_');
          return parseInt(parts.length > 1 ? parts[1] : '0');
        }));
        this.nextQuestionId = maxQId + 1;
      }

      // 加载所有回答
      for (const q of this.questions) {
        const dbAnswers: AnswerRow[] = await DatabaseHelper.queryAnswersByQuestionId(q.id);
        for (const row of dbAnswers) {
          const a: AnswerModel = this.rowToAnswerModel(row);
          this.answers.push(a);
          q.answerCount++;
        }
      }

      if (this.answers.length > 0) {
        const maxAId: number = Math.max(...this.answers.map(a => {
          const parts: string[] = a.id.split('_');
          return parseInt(parts.length > 1 ? parts[1] : '0');
        }));
        this.nextAnswerId = maxAId + 1;
      }

      this.dbLoaded = true;
    } catch (err) {
      console.error('MockDataStore.loadFromDb failed:', JSON.stringify(err));
    }
  }

  /**
   * 从 DB 加载当前用户数据到内存 store（登录后调用）
   * 确保用户数据在内存 store 中存在，以便后续操作能找到 author
   */
  syncUserFromDb(userRow: UserRow): UserModel {
    let followedIds: string[] = [];
    try {
      const parsed: Object = JSON.parse(userRow.followedTopicIds) as Object;
      followedIds = parsed as string[];
    } catch (_e) {
      followedIds = [];
    }

    const existing: UserModel | undefined = this.users.find(u => u.id === userRow.id);
    if (existing) {
      existing.name = userRow.name || userRow.username;
      existing.avatar = userRow.avatar;
      existing.bio = userRow.bio;
      existing.college = userRow.college;
      existing.major = userRow.major;
      existing.grade = userRow.grade;
      existing.reputation = userRow.reputation;
      existing.acceptedCount = userRow.acceptedCount;
      existing.totalAnswers = userRow.totalAnswers;
      existing.totalQuestions = userRow.totalQuestions;
      existing.followerCount = userRow.followerCount;
      existing.followingCount = userRow.followingCount;
      existing.followedTopicIds = followedIds;
      this.restoreTopicFollowState(followedIds);
      return existing;
    }
    const u: UserModel = new UserModel();
    u.id = userRow.id;
    u.name = userRow.username || userRow.name;
    u.avatar = userRow.avatar;
    u.bio = userRow.bio;
    u.college = userRow.college;
    u.major = userRow.major;
    u.grade = userRow.grade;
    u.reputation = userRow.reputation;
    u.acceptedCount = userRow.acceptedCount;
    u.totalAnswers = userRow.totalAnswers;
    u.totalQuestions = userRow.totalQuestions;
    u.followerCount = userRow.followerCount;
    u.followingCount = userRow.followingCount;
    u.createdAt = userRow.createdAt;
    u.followedTopicIds = followedIds;
    this.users.push(u);
    this.restoreTopicFollowState(followedIds);
    return u;
  }

  private restoreTopicFollowState(followedIds: string[]): void {
    for (const tid of followedIds) {
      const topic: TopicModel | undefined = this.topics.find(t => t.id === tid);
      if (topic) {
        topic.isFollowed = true;
      }
    }
  }

  // ========== Row → Model 转换 ==========

  private rowToQuestionModel(row: QuestionRow): QuestionModel {
    const q: QuestionModel = new QuestionModel();
    q.id = row.id;
    q.title = row.title;
    q.content = row.content;
    // 懒加载 author：如果内存 store 有对应的用户就用，否则创建一个占位 UserModel
    const author: UserModel | undefined = this.users.find(u => u.id === row.authorId);
    if (author) {
      q.author = author;
    } else {
      const placeholder: UserModel = new UserModel();
      placeholder.id = row.authorId;
      placeholder.name = row.authorName;
      placeholder.avatar = row.authorAvatar;
      q.author = placeholder;
    }
    try {
      const parsed: Object = JSON.parse(row.topicIds) as Object;
      q.topicIds = parsed as string[];
    } catch (_e) {
      q.topicIds = [];
    }
    q.status = row.status === 'RESOLVED' ? QuestionStatus.RESOLVED : QuestionStatus.OPEN;
    q.viewCount = row.viewCount;
    q.likeCount = row.likeCount;
    q.followerCount = row.followerCount;
    q.answerCount = row.answerCount;
    q.createdAt = row.createdAt;
    q.updatedAt = row.updatedAt;
    return q;
  }

  private rowToAnswerModel(row: AnswerRow): AnswerModel {
    const a: AnswerModel = new AnswerModel();
    a.id = row.id;
    a.questionId = row.questionId;
    a.content = row.content;
    const author: UserModel | undefined = this.users.find(u => u.id === row.authorId);
    if (author) {
      a.author = author;
    } else {
      const placeholder: UserModel = new UserModel();
      placeholder.id = row.authorId;
      placeholder.name = row.authorName;
      placeholder.avatar = row.authorAvatar;
      a.author = placeholder;
    }
    a.isAccepted = row.isAccepted === 1;
    a.likeCount = row.likeCount;
    a.commentCount = row.commentCount;
    a.createdAt = row.createdAt;
    return a;
  }

  private questionToRow(q: QuestionModel): QuestionRow {
    const row: QuestionRow = {
      id: q.id,
      title: q.title,
      content: q.content,
      authorId: q.author.id,
      authorName: q.author.name,
      authorAvatar: q.author.avatar,
      topicIds: JSON.stringify(q.topicIds),
      status: q.status === QuestionStatus.RESOLVED ? 'RESOLVED' : 'OPEN',
      viewCount: q.viewCount,
      likeCount: q.likeCount,
      followerCount: q.followerCount,
      answerCount: q.answerCount,
      createdAt: q.createdAt,
      updatedAt: q.updatedAt
    };
    return row;
  }

  private answerToRow(a: AnswerModel): AnswerRow {
    const row: AnswerRow = {
      id: a.id,
      questionId: a.questionId,
      content: a.content,
      authorId: a.author.id,
      authorName: a.author.name,
      authorAvatar: a.author.avatar,
      isAccepted: a.isAccepted ? 1 : 0,
      likeCount: a.likeCount,
      commentCount: a.commentCount,
      createdAt: a.createdAt
    };
    return row;
  }

  // ========== 话题种子数据（系统预设，保留）==========

  private seedTopics(): void {
    this.topics = [];
    this.topics.push(this.createTopic('高等数学', '微积分、线性代数、概率论', '📐', '#4A90D9'));
    this.topics.push(this.createTopic('大学英语', '四六级、雅思托福、口语练习', '🇬🇧', '#E8634A'));
    this.topics.push(this.createTopic('程序设计', 'C/C++/Java/Python 编程答疑', '💻', '#5CB85C'));
    this.topics.push(this.createTopic('考研交流', '考研经验、资料分享、院校选择', '📚', '#F0AD4E'));
    this.topics.push(this.createTopic('就业实习', '简历修改、面试技巧、实习内推', '💼', '#9B59B6'));
    this.topics.push(this.createTopic('校园生活', '食堂美食、宿舍指南、校园活动', '🏫', '#1ABC9C'));
    this.topics.push(this.createTopic('恋爱情感', '情感咨询、恋爱技巧', '💕', '#E91E63'));
    this.topics.push(this.createTopic('新生专区', '报到指南、选课攻略、社团介绍', '🎓', '#FF9800'));
    this.topics.push(this.createTopic('考试资料', '期末考试、考证资料分享', '📝', '#607D8B'));
    this.topics.push(this.createTopic('科研学术', '论文写作、实验方法、学术会议', '🔬', '#3F51B5'));
    this.topics.push(this.createTopic('留学申请', '海外院校、语言考试、文书准备', '✈️', '#00BCD4'));
    this.topics.push(this.createTopic('技术开发', '前端后端、移动开发、AI 讨论', '⚡', '#FF5722'));
    this.topics.push(this.createTopic('二手交易', '教材转让、电子产品、生活用品', '🔄', '#795548'));
    this.topics.push(this.createTopic('社团活动', '社团纳新、活动通知、才艺展示', '🎉', '#8BC34A'));
    this.topics.push(this.createTopic('心理健康', '压力疏导、心理咨询、成长互助', '🧠', '#9C27B0'));
    this.topics.push(this.createTopic('体育运动', '健身打卡、球类约战、运动会', '⚽', '#F44336'));
    this.topics.push(this.createTopic('设计创意', '平面设计、UI/UX、摄影后期', '🎨', '#FF6F00'));
    this.topics.push(this.createTopic('考证攻略', '教资、会计、计算机等级考试', '📋', '#009688'));
    this.topics.push(this.createTopic('兼职信息', '校内勤工俭学、校外兼职', '💰', '#CDDC39'));
    this.topics.push(this.createTopic('毕业论文', '选题、开题、答辩经验分享', '📖', '#673AB7'));
  }

  private createTopic(name: string, description: string, icon: string, color: string): TopicModel {
    const t: TopicModel = new TopicModel();
    t.id = this.genTopicId();
    t.name = name;
    t.description = description;
    t.icon = icon;
    t.color = color;
    t.followerCount = this.rand(50, 550);
    t.questionCount = 0;
    return t;
  }
}

// ============ 辅助类型 ============

class ScoredQuestion {
  question: QuestionModel = new QuestionModel();
  score: number = 0;
}

// ============ 公开 API ============

export function getStore(): MockDataStore {
  return MockDataStore.getInstance();
}

function delay(ms: number = 300): Promise<void> {
  return new Promise<void>((resolve: Function) => {
    setTimeout(() => { resolve(); }, ms + Math.random() * 200);
  });
}

// ========== 问题相关 API ==========

export async function getQuestions(page: number = 1, pageSize: number = 20): Promise<QuestionModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const start: number = (page - 1) * pageSize;
  return store.questions.slice(start, start + pageSize);
}

export async function getQuestionById(id: string): Promise<QuestionModel | undefined> {
  await delay();
  const store: MockDataStore = getStore();
  const result: QuestionModel | undefined = store.questions.find(q => q.id === id);
  if (result) {
    result.viewCount++;
  }
  return result;
}

export async function getRecommendedQuestions(userId: string, page: number = 1, pageSize: number = 20): Promise<QuestionModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  // 简单排序：按创建时间倒序（最新），无用户画像时退化为最新列表
  const sorted: QuestionModel[] = [];
  for (const q of store.questions) {
    sorted.push(q);
  }
  sorted.sort((a: QuestionModel, b: QuestionModel) =>
    new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
  );
  const start: number = (page - 1) * pageSize;
  return sorted.slice(start, start + pageSize);
}

export async function getHotQuestions(limit: number = 10): Promise<QuestionModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const sorted: QuestionModel[] = [];
  for (const q of store.questions) {
    sorted.push(q);
  }
  sorted.sort((a: QuestionModel, b: QuestionModel) =>
    (b.likeCount * 1 + b.answerCount * 3 + b.viewCount * 0.5) -
    (a.likeCount * 1 + a.answerCount * 3 + a.viewCount * 0.5)
  );
  return sorted.slice(0, limit);
}

export async function getQuestionsByTopic(topicId: string, page: number = 1, pageSize: number = 20): Promise<QuestionModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const filtered: QuestionModel[] = [];
  for (const q of store.questions) {
    if (q.topicIds.includes(topicId)) {
      filtered.push(q);
    }
  }
  const start: number = (page - 1) * pageSize;
  return filtered.slice(start, start + pageSize);
}

export async function searchQuestions(keyword: string): Promise<QuestionModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const kw: string = keyword.toLowerCase();
  const result: QuestionModel[] = [];
  for (const q of store.questions) {
    if (q.title.toLowerCase().includes(kw) || q.content.toLowerCase().includes(kw)) {
      result.push(q);
    }
  }
  return result;
}

export async function searchAll(keyword: string): Promise<SearchAllResult> {
  await delay();
  const store: MockDataStore = getStore();
  const kw: string = keyword.toLowerCase();
  const questions: QuestionModel[] = [];
  const topics: TopicModel[] = [];
  const users: UserModel[] = [];
  for (const q of store.questions) {
    if (q.title.toLowerCase().includes(kw) || q.content.toLowerCase().includes(kw)) {
      questions.push(q);
    }
  }
  for (const t of store.topics) {
    if (t.name.toLowerCase().includes(kw) || t.description.toLowerCase().includes(kw)) {
      topics.push(t);
    }
  }
  for (const u of store.users) {
    if (u.name.toLowerCase().includes(kw) || u.college.toLowerCase().includes(kw) || u.bio.toLowerCase().includes(kw)) {
      users.push(u);
    }
  }
  const result: SearchAllResult = new SearchAllResult();
  result.questions = questions;
  result.topics = topics;
  result.users = users;
  return result;
}

export class SearchAllResult {
  questions: QuestionModel[] = [];
  topics: TopicModel[] = [];
  users: UserModel[] = [];
}

export async function postQuestion(title: string, content: string, topicIds: string[], authorId: string): Promise<QuestionModel> {
  await delay();
  const store: MockDataStore = getStore();
  const author: UserModel | undefined = store.users.find(u => u.id === authorId);
  const question: QuestionModel = new QuestionModel();
  question.id = store.genQuestionId();
  question.title = title;
  question.content = content;
  question.author = author ? author : new UserModel();
  question.topicIds = topicIds;
  question.status = QuestionStatus.OPEN;
  question.createdAt = new Date().toISOString();
  question.updatedAt = question.createdAt;
  store.questions.unshift(question);

  // 同步写入 DB
  const questionRow: QuestionRow = {
    id: question.id,
    title: question.title,
    content: question.content,
    authorId: question.author.id,
    authorName: question.author.name,
    authorAvatar: question.author.avatar,
    topicIds: JSON.stringify(question.topicIds),
    status: 'OPEN',
    viewCount: question.viewCount,
    likeCount: question.likeCount,
    followerCount: question.followerCount,
    answerCount: question.answerCount,
    createdAt: question.createdAt,
    updatedAt: question.updatedAt
  };
  DatabaseHelper.insertQuestion(questionRow);

  // 更新话题的问题数量
  for (const tid of topicIds) {
    const topic: TopicModel | undefined = store.topics.find(t => t.id === tid);
    if (topic) {
      topic.questionCount++;
    }
  }

  // 更新用户提问数
  if (author) {
    author.totalQuestions++;
    DatabaseHelper.updateUser({
      id: author.id,
      phone: author.id,
      username: author.name,
      password: '',
      name: author.name,
      avatar: author.avatar,
      bio: author.bio,
      college: author.college,
      major: author.major,
      grade: author.grade,
      reputation: author.reputation,
      acceptedCount: author.acceptedCount,
      totalAnswers: author.totalAnswers,
      totalQuestions: author.totalQuestions,
      followerCount: author.followerCount,
      followingCount: author.followingCount,
      followedTopicIds: JSON.stringify(author.followedTopicIds),
      createdAt: author.createdAt
    });
  }

  return question;
}

export async function toggleQuestionLike(questionId: string): Promise<QuestionModel | undefined> {
  await delay(100);
  const store: MockDataStore = getStore();
  const q: QuestionModel | undefined = store.questions.find(q => q.id === questionId);
  if (q) {
    q.isLiked = !q.isLiked;
    q.likeCount += q.isLiked ? 1 : -1;
  }
  return q;
}

export async function toggleQuestionCollect(questionId: string): Promise<QuestionModel | undefined> {
  await delay(100);
  const store: MockDataStore = getStore();
  const q: QuestionModel | undefined = store.questions.find(q => q.id === questionId);
  if (q) {
    q.isCollected = !q.isCollected;
    q.followerCount += q.isCollected ? 1 : -1;
  }
  return q;
}

// ========== 删除操作 ==========

export async function deleteQuestion(questionId: string): Promise<boolean> {
  await delay(100);
  const store: MockDataStore = getStore();
  const qIdx: number = store.questions.findIndex(q => q.id === questionId);
  if (qIdx < 0) { return false; }
  const question: QuestionModel = store.questions[qIdx];

  const remaining: AnswerModel[] = [];
  for (const a of store.answers) {
    if (a.questionId !== questionId) {
      remaining.push(a);
    }
  }
  store.answers = remaining;

  const newQuestions: QuestionModel[] = [];
  for (let i = 0; i < store.questions.length; i++) {
    if (i !== qIdx) { newQuestions.push(store.questions[i]); }
  }
  store.questions = newQuestions;

  const author: UserModel | undefined = store.users.find(u => u.id === question.author.id);
  if (author && author.totalQuestions > 0) {
    author.totalQuestions--;
  }

  for (const tid of question.topicIds) {
    const topic: TopicModel | undefined = store.topics.find(t => t.id === tid);
    if (topic && topic.questionCount > 0) {
      topic.questionCount--;
    }
  }

  await DatabaseHelper.deleteAnswersByQuestionId(questionId);
  await DatabaseHelper.deleteQuestion(questionId);

  if (author) {
    DatabaseHelper.updateUser({
      id: author.id,
      phone: author.id,
      username: author.name,
      password: '',
      name: author.name,
      avatar: author.avatar,
      bio: author.bio,
      college: author.college,
      major: author.major,
      grade: author.grade,
      reputation: author.reputation,
      acceptedCount: author.acceptedCount,
      totalAnswers: author.totalAnswers,
      totalQuestions: author.totalQuestions,
      followerCount: author.followerCount,
      followingCount: author.followingCount,
      followedTopicIds: JSON.stringify(author.followedTopicIds),
      createdAt: author.createdAt
    });
  }

  return true;
}

export async function deleteAnswer(answerId: string): Promise<boolean> {
  await delay(100);
  const store: MockDataStore = getStore();
  const aIdx: number = store.answers.findIndex(a => a.id === answerId);
  if (aIdx < 0) { return false; }
  const answer: AnswerModel = store.answers[aIdx];

  const remaining: AnswerModel[] = [];
  for (let i = 0; i < store.answers.length; i++) {
    if (i !== aIdx) { remaining.push(store.answers[i]); }
  }
  store.answers = remaining;

  const question: QuestionModel | undefined = store.questions.find(q => q.id === answer.questionId);
  if (question && question.answerCount > 0) {
    question.answerCount--;
  }

  const author: UserModel | undefined = store.users.find(u => u.id === answer.author.id);
  if (author && author.totalAnswers > 0) {
    author.totalAnswers--;
  }

  await DatabaseHelper.deleteAnswer(answerId);
  if (question) {
    DatabaseHelper.updateQuestion({
      id: question.id,
      title: question.title,
      content: question.content,
      authorId: question.author.id,
      authorName: question.author.name,
      authorAvatar: question.author.avatar,
      topicIds: JSON.stringify(question.topicIds),
      status: question.status === QuestionStatus.RESOLVED ? 'RESOLVED' : 'OPEN',
      viewCount: question.viewCount,
      likeCount: question.likeCount,
      followerCount: question.followerCount,
      answerCount: question.answerCount,
      createdAt: question.createdAt,
      updatedAt: question.updatedAt
    });
  }
  if (author) {
    DatabaseHelper.updateUser({
      id: author.id,
      phone: author.id,
      username: author.name,
      password: '',
      name: author.name,
      avatar: author.avatar,
      bio: author.bio,
      college: author.college,
      major: author.major,
      grade: author.grade,
      reputation: author.reputation,
      acceptedCount: author.acceptedCount,
      totalAnswers: author.totalAnswers,
      totalQuestions: author.totalQuestions,
      followerCount: author.followerCount,
      followingCount: author.followingCount,
      followedTopicIds: JSON.stringify(author.followedTopicIds),
      createdAt: author.createdAt
    });
  }

  return true;
}

// ========== 回答相关 API ==========

export async function getAnswersByQuestionId(questionId: string): Promise<AnswerModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const filtered: AnswerModel[] = [];
  for (const a of store.answers) {
    if (a.questionId === questionId) {
      filtered.push(a);
    }
  }
  filtered.sort((a: AnswerModel, b: AnswerModel) => {
    if (a.isAccepted !== b.isAccepted) { return a.isAccepted ? -1 : 1; }
    return b.likeCount - a.likeCount;
  });
  return filtered;
}

export async function postAnswer(questionId: string, content: string, authorId: string): Promise<AnswerModel> {
  await delay();
  const store: MockDataStore = getStore();
  const author: UserModel | undefined = store.users.find(u => u.id === authorId);
  const answer: AnswerModel = new AnswerModel();
  answer.id = store.genAnswerId();
  answer.questionId = questionId;
  answer.content = content;
  answer.author = author ? author : new UserModel();
  answer.createdAt = new Date().toISOString();

  if (author) {
    author.totalAnswers += 1;
    author.reputation += 2;
  }

  store.answers.push(answer);

  const question: QuestionModel | undefined = store.questions.find(q => q.id === questionId);
  if (question) {
    question.answerCount++;
  }

  // 同步写入 DB
  const answerRow: AnswerRow = {
    id: answer.id,
    questionId: answer.questionId,
    content: answer.content,
    authorId: answer.author.id,
    authorName: answer.author.name,
    authorAvatar: answer.author.avatar,
    isAccepted: answer.isAccepted ? 1 : 0,
    likeCount: answer.likeCount,
    commentCount: answer.commentCount,
    createdAt: answer.createdAt
  };
  DatabaseHelper.insertAnswer(answerRow);

  // 更新用户数据
  if (author) {
    DatabaseHelper.updateUser({
      id: author.id,
      phone: author.id,
      username: author.name,
      password: '',
      name: author.name,
      avatar: author.avatar,
      bio: author.bio,
      college: author.college,
      major: author.major,
      grade: author.grade,
      reputation: author.reputation,
      acceptedCount: author.acceptedCount,
      totalAnswers: author.totalAnswers,
      totalQuestions: author.totalQuestions,
      followerCount: author.followerCount,
      followingCount: author.followingCount,
      followedTopicIds: JSON.stringify(author.followedTopicIds),
      createdAt: author.createdAt
    });
  }

  // 通知问题作者
  if (question && author && question.author.id !== authorId) {
    const noti: NotificationItem = new NotificationItem();
    noti.id = store.genNotificationId();
    noti.type = 'answer';
    noti.title = '新回答';
    noti.content = `${author.name}回答了你的问题"${question.title.substring(0, 20)}..."`;
    noti.fromUserId = authorId;
    noti.fromUserName = author.name;
    noti.fromUserAvatar = author.avatar;
    noti.targetQuestionId = questionId;
    noti.targetAnswerId = answer.id;
    noti.isRead = false;
    noti.createdAt = new Date().toISOString();
    store.notifications.unshift(noti);
  }

  return answer;
}

export async function acceptAnswer(answerId: string): Promise<AnswerModel | undefined> {
  await delay();
  const store: MockDataStore = getStore();
  const answer: AnswerModel | undefined = store.answers.find(a => a.id === answerId);
  if (answer) {
    answer.isAccepted = true;
    const question: QuestionModel | undefined = store.questions.find(q => q.id === answer.questionId);
    if (question) {
      question.status = QuestionStatus.RESOLVED;
    }
    const author: UserModel | undefined = store.users.find(u => u.id === answer.author.id);
    if (author) {
      author.reputation += 25;
      author.acceptedCount += 1;
      // 同步用户数据到 DB
      DatabaseHelper.updateUser({
        id: author.id,
        phone: author.id,
        username: author.name,
        password: '',
        name: author.name,
        avatar: author.avatar,
        bio: author.bio,
        college: author.college,
        major: author.major,
        grade: author.grade,
        reputation: author.reputation,
        acceptedCount: author.acceptedCount,
        totalAnswers: author.totalAnswers,
        totalQuestions: author.totalQuestions,
        followerCount: author.followerCount,
        followingCount: author.followingCount,
      followedTopicIds: JSON.stringify(author.followedTopicIds),
        createdAt: author.createdAt
      });
    }
  }
  return answer;
}

export async function toggleAnswerLike(answerId: string): Promise<AnswerModel | undefined> {
  await delay(100);
  const store: MockDataStore = getStore();
  const a: AnswerModel | undefined = store.answers.find(a => a.id === answerId);
  if (a) {
    a.isLiked = !a.isLiked;
    a.likeCount += a.isLiked ? 1 : -1;
  }
  return a;
}

// ========== 评论相关 API ==========

export async function getCommentsByTargetId(targetId: string): Promise<CommentModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const filtered: CommentModel[] = [];
  for (const c of store.comments) {
    if (c.targetId === targetId) {
      filtered.push(c);
    }
  }
  filtered.sort((a: CommentModel, b: CommentModel) =>
    new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
  );
  return filtered;
}

export async function postComment(targetId: string, targetType: CommentTargetType, content: string, authorId: string): Promise<CommentModel> {
  await delay();
  const store: MockDataStore = getStore();
  const author: UserModel | undefined = store.users.find(u => u.id === authorId);
  const comment: CommentModel = new CommentModel();
  comment.id = store.genCommentId();
  comment.targetId = targetId;
  comment.targetType = targetType;
  comment.content = content;
  comment.author = author ? author : new UserModel();
  comment.createdAt = new Date().toISOString();
  store.comments.push(comment);

  if (targetType === CommentTargetType.ANSWER) {
    const answer: AnswerModel | undefined = store.answers.find(a => a.id === targetId);
    if (answer) {
      answer.commentCount++;
    }
  }

  return comment;
}

// ========== 话题相关 API ==========

export async function getAllTopics(): Promise<TopicModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const result: TopicModel[] = [];
  for (const t of store.topics) {
    result.push(t);
  }
  return result;
}

export async function getFollowedTopics(userId: string): Promise<TopicModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const user: UserModel | undefined = store.users.find(u => u.id === userId);
  if (!user) {
    return [];
  }
  const result: TopicModel[] = [];
  for (const t of store.topics) {
    if (user.followedTopicIds.includes(t.id)) {
      result.push(t);
    }
  }
  return result;
}

export async function toggleTopicFollow(topicId: string, userId: string): Promise<TopicModel | undefined> {
  await delay(100);
  const store: MockDataStore = getStore();
  const topic: TopicModel | undefined = store.topics.find(t => t.id === topicId);
  const user: UserModel | undefined = store.users.find(u => u.id === userId);
  if (topic && user) {
    topic.isFollowed = !topic.isFollowed;
    topic.followerCount += topic.isFollowed ? 1 : -1;
    if (topic.isFollowed) {
      if (!user.followedTopicIds.includes(topicId)) {
        const newIds: string[] = [];
        for (const id of user.followedTopicIds) { newIds.push(id); }
        newIds.push(topicId);
        user.followedTopicIds = newIds;
      }
    } else {
      const newIds: string[] = [];
      for (const id of user.followedTopicIds) {
        if (id !== topicId) { newIds.push(id); }
      }
      user.followedTopicIds = newIds;
    }
  }
  return topic;
}

// ========== 用户相关 API ==========

export async function getUserById(id: string): Promise<UserModel | undefined> {
  await delay();
  const store: MockDataStore = getStore();
  const found: UserModel | undefined = store.users.find(u => u.id === id);
  if (found) {
    return found;
  }
  // 内存中没有，尝试从 DB 查
  const dbUser: UserRow | null = await DatabaseHelper.queryUserById(id);
  if (dbUser) {
    return store.syncUserFromDb(dbUser);
  }
  return undefined;
}

/** @deprecated 不再硬编码返回假用户，改用 AppStorage 中的当前用户 */
export async function getCurrentUser(): Promise<UserModel> {
  await delay();
  // 返回 AppStorage 中的当前用户，如果没有则返回空 UserModel
  const currentUser: UserModel | undefined = AppStorage.get<UserModel>('currentUser');
  if (currentUser) {
    return currentUser;
  }
  return new UserModel();
}

export async function toggleFollowUser(targetUserId: string, currentUserId: string): Promise<UserModel | undefined> {
  await delay(100);
  const store: MockDataStore = getStore();
  const target: UserModel | undefined = store.users.find(u => u.id === targetUserId);
  const current: UserModel | undefined = store.users.find(u => u.id === currentUserId);
  if (!target || !current) { return target; }

  const isFollowing: boolean = current.followedUserIds.includes(targetUserId);

  if (isFollowing) {
    // 取关：减计数，移出关注/粉丝列表
    target.followerCount = Math.max(0, target.followerCount - 1);
    current.followingCount = Math.max(0, current.followingCount - 1);
    target.followerUserIds = target.followerUserIds.filter((id: string) => id !== currentUserId);
    current.followedUserIds = current.followedUserIds.filter((id: string) => id !== targetUserId);
  } else {
    // 关注：加计数，加入关注/粉丝列表
    target.followerCount += 1;
    current.followingCount += 1;
    if (!target.followerUserIds.includes(currentUserId)) {
      target.followerUserIds = [...target.followerUserIds, currentUserId];
    }
    if (!current.followedUserIds.includes(targetUserId)) {
      current.followedUserIds = [...current.followedUserIds, targetUserId];
    }
  }

  // 持久化双方用户数据到 DB
  DatabaseHelper.updateUser({
    id: target.id, phone: target.id, username: target.name, password: '',
    name: target.name, avatar: target.avatar, bio: target.bio,
    college: target.college, major: target.major, grade: target.grade,
    reputation: target.reputation, acceptedCount: target.acceptedCount,
    totalAnswers: target.totalAnswers, totalQuestions: target.totalQuestions,
    followerCount: target.followerCount, followingCount: target.followingCount,
    followedTopicIds: JSON.stringify(target.followedTopicIds),
    createdAt: target.createdAt
  });
  DatabaseHelper.updateUser({
    id: current.id, phone: current.id, username: current.name, password: '',
    name: current.name, avatar: current.avatar, bio: current.bio,
    college: current.college, major: current.major, grade: current.grade,
    reputation: current.reputation, acceptedCount: current.acceptedCount,
    totalAnswers: current.totalAnswers, totalQuestions: current.totalQuestions,
    followerCount: current.followerCount, followingCount: current.followingCount,
    followedTopicIds: JSON.stringify(current.followedTopicIds),
    createdAt: current.createdAt
  });

  // 同步 AppStorage 中的 currentUser
  const appUser: UserModel | undefined = AppStorage.get<UserModel>('currentUser');
  if (appUser && appUser.id === currentUserId) {
    AppStorage.setOrCreate('currentUser', current);
  }

  return target;
}

export async function isFollowingUser(currentUserId: string, targetUserId: string): Promise<boolean> {
  await delay(50);
  const store: MockDataStore = getStore();
  const current: UserModel | undefined = store.users.find(u => u.id === currentUserId);
  if (!current) { return false; }
  return current.followedUserIds.includes(targetUserId);
}

export async function getFollowingUsers(userId: string): Promise<UserModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const user: UserModel | undefined = store.users.find(u => u.id === userId);
  if (!user) { return []; }
  const result: UserModel[] = [];
  for (const id of user.followedUserIds) {
    const u: UserModel | undefined = store.users.find(u => u.id === id);
    if (u) { result.push(u); }
  }
  return result;
}

export async function getFollowerUsers(userId: string): Promise<UserModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const user: UserModel | undefined = store.users.find(u => u.id === userId);
  if (!user) { return []; }
  const result: UserModel[] = [];
  for (const id of user.followerUserIds) {
    const u: UserModel | undefined = store.users.find(u => u.id === id);
    if (u) { result.push(u); }
  }
  return result;
}

// ========== 通知相关 API ==========

export async function getNotifications(userId: string): Promise<NotificationItem[]> {
  await delay();
  const store: MockDataStore = getStore();
  const result: NotificationItem[] = [];
  for (const n of store.notifications) { result.push(n); }
  result.sort((a: NotificationItem, b: NotificationItem) =>
    new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
  );
  return result;
}

export async function getUnreadNotificationCount(userId: string): Promise<number> {
  await delay(100);
  const store: MockDataStore = getStore();
  let count: number = 0;
  for (const n of store.notifications) {
    if (!n.isRead) { count++; }
  }
  return count;
}

export async function markNotificationRead(notificationId: string): Promise<void> {
  await delay(100);
  const store: MockDataStore = getStore();
  const noti: NotificationItem | undefined = store.notifications.find(n => n.id === notificationId);
  if (noti) { noti.isRead = true; }
}

// ========== 相关问题 ==========

export async function getRelatedQuestions(questionId: string, limit: number = 5): Promise<QuestionModel[]> {
  await delay();
  const store: MockDataStore = getStore();
  const sourceQ: QuestionModel | undefined = store.questions.find(q => q.id === questionId);
  if (!sourceQ) { return []; }
  const related: ScoredQuestion[] = [];
  for (const other of store.questions) {
    if (other.id === questionId) { continue; }
    let overlap: number = 0;
    for (const tid of other.topicIds) {
      if (sourceQ.topicIds.includes(tid)) { overlap++; }
    }
    if (overlap > 0) {
      const item: ScoredQuestion = new ScoredQuestion();
      item.question = other;
      item.score = other.likeCount + overlap * 10;
      related.push(item);
    }
  }
  related.sort((a: ScoredQuestion, b: ScoredQuestion) => b.score - a.score);
  const result: QuestionModel[] = [];
  for (let i = 0; i < Math.min(limit, related.length); i++) {
    result.push(related[i].question);
  }
  return result;
}
