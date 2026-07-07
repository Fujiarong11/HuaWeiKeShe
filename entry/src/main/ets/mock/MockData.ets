/**
 * 集中式模拟数据层
 * 提供所有校园问答互助平台的种子数据和 CRUD 操作
 */
import { UserModel } from '../model/UserModel';
import { QuestionModel, QuestionStatus } from '../model/QuestionModel';
import { AnswerModel } from '../model/AnswerModel';
import { CommentModel, CommentTargetType } from '../model/CommentModel';
import { TopicModel } from '../model/TopicModel';

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

// ============ 数据仓库 ============

class MockDataStore {
  private static instance: MockDataStore;

  users: UserModel[] = [];
  questions: QuestionModel[] = [];
  answers: AnswerModel[] = [];
  comments: CommentModel[] = [];
  topics: TopicModel[] = [];
  notifications: NotificationItem[] = [];
  invites: InviteRecord[] = [];

  private nextUserId = 100;
  private nextQuestionId = 1000;
  private nextAnswerId = 2000;
  private nextCommentId = 3000;
  private nextNotificationId = 4000;
  private nextInviteId = 5000;
  private nextTopicId = 6000;

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
    this.seedUsers();
    this.seedTopics();
    this.seedQuestions();
    this.updateTopicQuestionCounts();
    this.seedAnswers();
    this.seedComments();
    this.seedNotifications();
    this.seedRelationships();
  }

  // ========== 用户种子数据 ==========
  private seedUsers(): void {
    this.users = [];
    this.users.push(this.createUser('张学长', '', '计算机科学与技术专业，乐于助人',
      '信息工程学院', '计算机科学与技术', '研二', 1580, 42, 156, 8, 328, 56));
    this.users.push(this.createUser('李学姐', '', '英语专业，翻译方向',
      '外国语学院', '英语', '大四', 920, 28, 89, 12, 186, 42));
    this.users.push(this.createUser('王小萌', '', '大一新生，热爱学习',
      '理学院', '数学与应用数学', '大一', 145, 3, 15, 23, 28, 120));
    this.users.push(this.createUser('代码侠', '', '全栈开发者，热爱开源',
      '信息工程学院', '软件工程', '大三', 2340, 67, 210, 5, 512, 35));
    this.users.push(this.createUser('考研达人', '', '已上岸985，分享考研经验',
      '经济管理学院', '工商管理', '研一', 875, 19, 45, 3, 423, 28));
    this.users.push(this.createUser('图书馆常客', '', '书中自有黄金屋',
      '人文学院', '汉语言文学', '大二', 560, 12, 67, 15, 95, 78));
    this.users.push(this.createUser('理科小天才', '', '物理化学都可以来问',
      '理学院', '物理学', '大三', 1100, 35, 98, 10, 240, 45));
    this.users.push(this.createUser('校园百事通', '', '关于学校的一切我都知道',
      '新闻传播学院', '新闻学', '大四', 720, 20, 132, 6, 680, 90));
    this.users.push(this.createUser('实习小能手', '', '腾讯字节都待过，分享实习经验',
      '信息工程学院', '计算机科学与技术', '大四', 1560, 38, 78, 4, 890, 32));
    this.users.push(this.createUser('艺术青年', '', '用设计改变世界',
      '艺术设计学院', '视觉传达', '大三', 430, 8, 34, 18, 156, 105));
    this.users.push(this.createUser('留学生小明', '', '来自马来西亚的留学生',
      '国际教育学院', '国际经济与贸易', '大二', 280, 5, 22, 20, 78, 65));
    this.users.push(this.createUser('学霸笔记', '', '笔记整理狂魔，分享学习资料',
      '医学院', '临床医学', '大三', 1680, 48, 95, 2, 1200, 15));
    this.users.push(this.createUser('运动健将', '', '健身篮球都爱',
      '体育学院', '运动训练', '大二', 190, 2, 28, 11, 220, 80));
    this.users.push(this.createUser('美食探店家', '', '吃遍校园周边每一家店',
      '旅游学院', '酒店管理', '大三', 350, 6, 45, 16, 310, 55));
    this.users.push(this.createUser('心理小助手', '', '倾听你的烦恼',
      '教育学院', '应用心理学', '研二', 640, 15, 56, 7, 175, 38));
  }

  private createUser(name: string, avatar: string, bio: string,
    college: string, major: string, grade: string,
    reputation: number, acceptedCount: number, totalAnswers: number,
    totalQuestions: number, followerCount: number, followingCount: number): UserModel {
    const u = new UserModel();
    u.id = this.genUserId();
    u.name = name;
    u.avatar = avatar;
    u.bio = bio;
    u.college = college;
    u.major = major;
    u.grade = grade;
    u.reputation = reputation;
    u.acceptedCount = acceptedCount;
    u.totalAnswers = totalAnswers;
    u.totalQuestions = totalQuestions;
    u.followerCount = followerCount;
    u.followingCount = followingCount;
    u.createdAt = '2025-09-01T08:00:00Z';
    return u;
  }

  // ========== 话题种子数据 ==========
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
    const t = new TopicModel();
    t.id = this.genTopicId();
    t.name = name;
    t.description = description;
    t.icon = icon;
    t.color = color;
    t.followerCount = this.rand(50, 550);
    t.questionCount = 0; // 稍后根据实际问题数据统计
    return t;
  }

  /**
   * 根据实际问题数据更新每个话题的问题数量
   */
  private updateTopicQuestionCounts(): void {
    // 初始化所有话题的问题数为0
    for (const t of this.topics) {
      t.questionCount = 0;
    }
    // 统计每个话题下的实际问题数
    for (const q of this.questions) {
      for (const tid of q.topicIds) {
        const topic = this.topics.find(t => t.id === tid);
        if (topic) {
          topic.questionCount++;
        }
      }
    }
  }

  // ========== 问题种子数据 ==========
  private seedQuestions(): void {
    this.questions = [];
    const now = new Date();
    const titles: string[] = [
      '高等数学中极限的定义到底怎么理解？',
      'C语言指针学不会怎么办？',
      '考研数学一和数学三有什么区别？',
      '学校附近有什么好吃的推荐？',
      '大二暑假去实习还是去参加竞赛？',
      'Python 爬虫被反爬了怎么解决？',
      '如何高效准备英语四级？',
      '想转专业到计算机，需要做什么准备？',
      '论文查重率太高怎么办？',
      '线性代数到底有什么用？学到怀疑人生',
      '校招面试中算法题要刷到什么程度？',
      '新生选课有什么技巧？',
      '和室友作息不一致怎么办？',
      '摄影入门买什么相机好？',
      '数据结构到底该怎么学？',
      '考研英语一真题怎么高效利用？',
      '学生会和社团哪个更值得参加？',
      '大学期间要不要考驾照？',
      '答辩PPT怎么做才能让导师满意？',
      '如何提高编程能力？',
      '医学专业考研需要准备多久？',
      '怎么找到靠谱的兼职？',
      '健身新手怎么开始？',
      '想申请国外研究生，大一应该怎么准备？',
      '文科生能学好编程吗？',
      '期末复习效率太低怎么办？',
      '有没有好的二手教材购买渠道？',
      '德语和日语哪个好学？',
      '如何看待内卷现象？',
      'Web前端和移动端开发怎么选？'
    ];
    const contents: string[] = [
      '我看了课本上 ε-δ 定义很多遍还是不太懂，有没有通俗易懂的解释方式？',
      '指针和多级指针的关系搞不清楚，还有指针和数组的区别是什么？',
      '我是经管专业的，不知道该选数一还是数三。求推荐考研数学的复习资料。',
      '刚来学校不久，对周边不太熟悉。求推荐学校食堂和周边性价比高的餐厅。',
      '目前 GPA 3.6，有两个竞赛机会和一个实习 offer，不知道该怎么选。',
      '用 requests + BeautifulSoup 爬学校教务系统数据，总是被识别。',
      '英语基础一般，高考英语110分左右，想在大一上学期过四级。',
      '目前是材料专业的，想大二转计算机。需要补哪些课程？',
      '毕业论文初稿查重率38%，学校要求20%以下，有没有好的降重方法？',
      '矩阵、行列式、特征值这些概念感觉特别抽象，实际中真的会用到吗？',
      '听说现在大厂面试都要手撕算法，LeetCode 刷了多少题才能应付？',
      '大一新生马上要选课了，求学长学姐分享选课攻略！',
      '我习惯早睡早起，室友喜欢熬夜打游戏，经常半夜被吵醒。',
      '预算5000以内，主要拍校园风景和人像。单反还是微单？',
      '链表、栈、队列、树、图，感觉每个都懂一点但写代码就懵。',
      '买了近10年真题，不知道按什么顺序做，每套做完要怎么复盘。',
      '大一新生精力有限，不知道学生会和社团怎么选。',
      '听说大学期间考驾照比较便宜也有时间，但不知道有没有必要。',
      '毕业答辩在即，PPT做得太丑了。求分享一些好用的模板和排版技巧。',
      '学了 C 和 Python 基础语法，但自己写项目时完全没有思路。',
      '临床医学大三，打算考研。一般从什么时候开始准备比较好？',
      '想利用课余时间做兼职赚点生活费，但又怕被骗。',
      '身高175体重55kg太瘦了，想增肌增重。学校健身房怎么收费？',
      '目前大一，有出国读研的打算。GPA、语言成绩、科研哪个更重要？',
      '我是学新闻的，最近对前端开发很感兴趣。没有数理基础能学会吗？',
      '每次到期末就焦虑，看书看不进去，刷手机刷到半夜。',
      '新学期教材好贵啊，想买二手的。除了闲鱼还有什么校内渠道？',
      '想学一门第二外语，在德语和日语之间犹豫。哪个对将来就业更有帮助？',
      '身边的同学都越来越卷了，有时候感觉自己不够努力很焦虑。',
      '大三了想确定一个方向深入学习。前端和移动端哪个前景更好？'
    ];
    const authorIndices: number[] = [2, 2, 4, 2, 8, 3, 2, 6, 5, 10, 8, 10, 14, 9, 2, 4, 2, 12, 5, 10, 11, 13, 12, 2, 7, 5, 2, 1, 14, 3];
    const topicIdxGroups: number[][] = [
      [0], [2], [3, 0], [5], [4], [2, 11], [1], [2, 5], [9, 19], [0],
      [4, 2], [7, 5], [5, 14], [16, 5], [2, 11], [3, 1], [13, 7], [5],
      [19, 9], [2, 11], [3, 8], [18, 5], [15, 5], [10, 1], [2, 11, 16],
      [8, 14], [12, 5], [1, 10], [5, 14], [11, 2]
    ];
    const statuses: QuestionStatus[] = [
      QuestionStatus.OPEN, QuestionStatus.OPEN, QuestionStatus.RESOLVED,
      QuestionStatus.OPEN, QuestionStatus.OPEN, QuestionStatus.RESOLVED,
      QuestionStatus.OPEN, QuestionStatus.OPEN, QuestionStatus.RESOLVED,
      QuestionStatus.OPEN, QuestionStatus.OPEN, QuestionStatus.RESOLVED,
      QuestionStatus.OPEN, QuestionStatus.OPEN, QuestionStatus.OPEN,
      QuestionStatus.OPEN, QuestionStatus.RESOLVED, QuestionStatus.OPEN,
      QuestionStatus.OPEN, QuestionStatus.OPEN, QuestionStatus.OPEN,
      QuestionStatus.OPEN, QuestionStatus.OPEN, QuestionStatus.OPEN,
      QuestionStatus.RESOLVED, QuestionStatus.OPEN, QuestionStatus.RESOLVED,
      QuestionStatus.OPEN, QuestionStatus.OPEN, QuestionStatus.OPEN
    ];

    for (let i = 0; i < titles.length; i++) {
      const q = new QuestionModel();
      q.id = this.genQuestionId();
      q.title = titles[i];
      q.content = contents[i];
      q.author = this.users[authorIndices[i]];
      q.topicIds = topicIdxGroups[i].map(idx => this.topics[idx].id);
      q.status = statuses[i];
      q.viewCount = this.rand(50, 2000);
      q.likeCount = this.rand(5, 100);
      q.followerCount = this.rand(2, 50);
      q.createdAt = new Date(now.getTime() - (30 - i) * 86400000).toISOString();
      q.updatedAt = q.createdAt;
      q.answerCount = 0;
      this.questions.push(q);
    }
  }

  // ========== 回答种子数据 ==========
  private seedAnswers(): void {
    this.answers = [];
    const answerDefs: AnswerDef[] = [
      { qi: 0, c: 'ε-δ 定义的核心思想是"无限接近"。想象你在射箭：对于任意一个靶心周围的区域（ε），我都能告诉你站在多远以内（δ）就能射中这个区域。建议画个函数图像，标出 ε 和 δ 的范围。', ai: 6, acc: false, lb: 45 },
      { qi: 0, c: '补充一下：极限就是说"当 x 充分接近 a 时，f(x) 可以任意接近 L"。ε 就是"任意"的量化，δ 就是"充分"的量化。多做几道证明题就慢慢有感觉了。', ai: 0, acc: false, lb: 23 },
      { qi: 1, c: '指针就是存储内存地址的变量。一级指针是直接地址，二级指针是"写有地址的纸条"的地址。推荐《C和指针》这本书，里面的图很清楚。', ai: 3, acc: false, lb: 78 },
      { qi: 1, c: '推荐一个方法：用 VS Code 或 CLion 的调试功能，单步执行代码，观察内存窗口。你亲眼看到指针指向的地址和里面存的值，比看书直观100倍。', ai: 0, acc: false, lb: 34 },
      { qi: 2, c: '数一难度最高范围最广，一般理工科学硕考；数三相对简单，经管类考。你是经管的话选数三。复习资料推荐李永乐全书+660题，基础打牢再刷真题。', ai: 4, acc: true, lb: 156 },
      { qi: 3, c: '学校北门小吃街的麻辣烫人均15超实惠！二楼食堂的鸡排饭也推荐，12元管饱。南门的奶茶店周末买一送一。出西门左转300米有家湘菜馆，人均30。', ai: 13, acc: false, lb: 56 },
      { qi: 3, c: '补充一个：教工食堂二楼的兰州拉面，8块钱一大碗，比外面任何一家都好吃！还有东门外的那家煎饼果子，早上排队的人最多那家就对了。', ai: 7, acc: false, lb: 34 },
      { qi: 5, c: '学校教务系统大概率有反爬机制，单纯加 UA 和延时不够。试试：1）加完整的请求头；2）使用 session 保持 cookie；3）如果还不行就用 Selenium 模拟浏览器。注意合规性。', ai: 3, acc: true, lb: 89 },
      { qi: 8, c: '降重实用技巧：1）同义词替换+语序调整；2）把大段论述拆成短句用自己的话重新组织；3）专业术语保留但解释性文字可以换说法；4）中英文互译法慎用；5）引用部分正确标注可以排除。', ai: 11, acc: true, lb: 210 },
      { qi: 11, c: '选课必看攻略：1）去学校论坛搜"选修课推荐"；2）抢课时用电脑比手机快，提前复制好学号；3）热门课第一轮选不上没关系，补退选阶段经常有人退；4）关注课程考核方式。', ai: 7, acc: true, lb: 178 },
      { qi: 16, c: '各有优劣：学生会更正式锻炼组织协调能力对考公有加分；社团基于兴趣更轻松自由能交到志同道合的朋友。建议大一先各选一个体验一下，关键是别让这些事情影响学习。', ai: 7, acc: true, lb: 95 },
      { qi: 24, c: '完全能学好！编程本质上是逻辑思维和解决问题的能力，不是数学能力。前端开发是个很好的切入点，推荐学习路线：HTML+CSS → JavaScript → React。我认识好几个文科转前端的都找到了不错的工作！', ai: 3, acc: true, lb: 134 },
      { qi: 26, c: '推荐渠道：1）学校的二手书交易群（QQ搜索"学校名+二手书"）；2）图书馆负一层的二手书店；3）小程序"多抓鱼"；4）闲鱼搜"学校名+教材"。买之前让卖家拍目录页和ISBN号。', ai: 7, acc: true, lb: 67 },
      { qi: 4, c: '建议优先选实习。竞赛的奖项写在简历上不如实际工作经验有说服力。除非是ACM级别的比赛，否则大厂HR更看重实习经历。而且实习过程中也能学到很多课堂上学不到的东西。', ai: 8, acc: false, lb: 42 },
      { qi: 6, c: '四级备考核心就三样：单词+真题+听力。单词用墨墨背单词每天50个复习150个；真题做近5年的每套要精做精析；听力每天至少听30分钟推荐VOA慢速英语入门。', ai: 1, acc: false, lb: 67 },
      { qi: 7, c: '转计算机需要：1）高数线代成绩不能差；2）自学编程基础至少会一门语言；3）去目标学院官网看转专业实施细则。一般GPA要求在专业前30%左右。面试会让你写简单代码+问为什么想转。', ai: 0, acc: false, lb: 56 },
      { qi: 9, c: '线代的核心应用场景：1）计算机图形学；2）机器学习（数据就是矩阵）；3）密码学；4）经济学。推荐3Blue1Brown的线代本质系列视频，用动画直观展示线性变换，看完你会觉得线代真的很美！', ai: 6, acc: false, lb: 89 },
      { qi: 10, c: '要看目标公司和岗位：大厂算法岗一般200+道（Hard为主），后端开发100-150道（Medium为主），前端50-100道。重点是常见题型要熟练。推荐按"代码随想录"的路线刷。', ai: 3, acc: false, lb: 112 },
      { qi: 12, c: '室友问题建议：1）正式再沟通一次明确表达诉求；2）和辅导员反映申请调换宿舍；3）自备耳塞+眼罩过渡。这个事很常见不要觉得是自己太小气。实在解决不了就申请换宿舍。', ai: 14, acc: false, lb: 45 },
      { qi: 13, c: '5000预算推荐索尼A6400+套头，对焦快、视频能力强适合入门。如果主要拍照可以考虑富士X-T200直出色彩好。建议去实体店摸一下手感再决定。后期买个50mm f1.8定焦拍人像。', ai: 9, acc: false, lb: 34 },
      { qi: 14, c: '数据结构学习路线：1）先理解每种数据结构的定义和操作；2）用纸笔画出插入删除等操作的流程；3）看源码实现；4）LeetCode上找对应标签的题练习。关键是"画图+写代码"循环。', ai: 0, acc: false, lb: 78 },
      { qi: 15, c: '真题使用建议：留近3年做考前模拟，前面7年分题型做。每套分三步：1）限时做；2）精读解析把不认识的单词标出来背；3）分析错题类型。阅读重点是长难句拆解。', ai: 4, acc: false, lb: 45 },
      { qi: 17, c: '强烈建议大学期间考驾照！毕业后真的很难抽出整块时间。一般3000-4000元，寒暑假集中学2个月左右能拿证。学校附近的驾校一般都有学生优惠价。', ai: 12, acc: false, lb: 23 },
      { qi: 18, c: '答辩PPT要点：1）模板简洁不要花哨动画；2）结构：背景→问题→方法→结果→结论；3）多用图表少用文字；4）每页不超过5个要点；5）准备一个备用PPT。答辩时自信最重要。', ai: 0, acc: false, lb: 56 },
      { qi: 19, c: '从"会语法"到"会编程"的桥梁是做项目。推荐步骤：1）先模仿——GitHub上找一个简单项目读懂代码结构；2）做小工具——写个计算器、TODO列表等；3）参加开源项目从修小bug开始。', ai: 3, acc: false, lb: 89 },
      { qi: 20, c: '临床医学考研一般从大三下学期开始准备比较合理。每天有效学习时间6-8小时。西医综合是大头（占300分），先搞定生理生化病理基础课再攻内外科。英语政治也不能落下。', ai: 11, acc: false, lb: 67 },
      { qi: 21, c: '避坑指南：1）先交钱的都是骗子；2）校内勤工俭学最安全（图书馆实验室助理辅导员助理）；3）家教是不错的选择学校一般有正规平台；4）线上兼职注意辨别刷单类的千万别碰！', ai: 7, acc: false, lb: 78 },
      { qi: 22, c: '增肌新手计划：1）先去学校健身房办卡一般200-300一学期；2）前期先做全身训练（深蹲卧推硬拉三大项）每周3次；3）饮食多吃蛋白质（鸡胸肉鸡蛋牛奶）；4）保证充足睡眠。', ai: 12, acc: false, lb: 34 },
      { qi: 23, c: '大一规划留学时间线：大一稳住GPA开始背单词；大二考出托福/雅思参加科研或竞赛；大三上考GRE/GMAT暑假做实习；大四上学期9-12月递交申请。GPA是硬门槛。', ai: 1, acc: false, lb: 56 },
      { qi: 25, c: '提高专注力方法：1）番茄工作法25分钟专注+5分钟休息，用Forest App锁手机；2）每天列出最重要的3件事；3）换环境——宿舍学不进去就去图书馆；4）运动后再学习效果更好。', ai: 14, acc: false, lb: 45 },
      { qi: 27, c: '德语语法复杂入门难度大于日语；日语入门简单但越学越难。对就业来说：日语需求更大（日企多），德语在汽车/机械行业有优势。自学者建议选日语因为有汉字基础。推荐"标准日本语"教材。', ai: 1, acc: false, lb: 34 },
      { qi: 28, c: '内卷的本质是大家在没有增量的赛道上恶性竞争。建议：1）找到自己真正喜欢的方向兴趣驱动比焦虑驱动持久；2）横向比较少一些；3）适当的"躺平"也是一种智慧。学会取舍对自己好一点。', ai: 14, acc: false, lb: 89 },
      { qi: 29, c: '2024年了建议学Web前端+鸿蒙开发双修。Web前端生态成熟岗位多，鸿蒙是新兴方向竞争小机会多。可以先打好前端基础再学鸿蒙ArkTS。华为现在大力推鸿蒙生态这个方向未来几年肯定缺人。', ai: 3, acc: false, lb: 123 }
    ];

    for (const def of answerDefs) {
      const a = new AnswerModel();
      a.id = this.genAnswerId();
      a.questionId = this.questions[def.qi].id;
      a.content = def.c;
      a.author = this.users[def.ai];
      a.isAccepted = def.acc;
      a.likeCount = def.lb + this.rand(0, 20);
      a.commentCount = 0;
      const qCreated = new Date(this.questions[def.qi].createdAt).getTime();
      a.createdAt = new Date(qCreated + this.rand(0, 3) * 86400000).toISOString();
      this.answers.push(a);
    }

    // Update question answer counts
    for (const q of this.questions) {
      q.answerCount = this.answers.filter(a => a.questionId === q.id).length;
    }
  }

  // ========== 评论种子数据 ==========
  private seedComments(): void {
    this.comments = [];
    const commentDefs: CommentDef[] = [
      { ai: 0, c: '这个射箭的比喻太形象了！一下就懂了，谢谢！', u: 2, lb: 12 },
      { ai: 0, c: '补充一点，可以看看"马同学高等数学"的公众号，里面有图解。', u: 5, lb: 5 },
      { ai: 2, c: '《C和指针》确实是经典，强烈推荐。', u: 0, lb: 8 },
      { ai: 3, c: '确实，调试的时候看内存地址变化是最直观的学习方式。', u: 6, lb: 6 },
      { ai: 4, c: '太详细了，收藏了！', u: 2, lb: 20 },
      { ai: 5, c: '北门麻辣烫真的绝了！每次下课都要去吃。', u: 12, lb: 10 },
      { ai: 7, c: 'Selenium太重了，也可以试试Playwright，性能更好。', u: 8, lb: 7 },
      { ai: 8, c: '降重神器：秘塔写作猫，可以自动改写。', u: 5, lb: 15 },
      { ai: 9, c: '选课抢不到也不要慌，开学第一周去旁听，老师一般会给加签。', u: 11, lb: 12 },
      { ai: 10, c: '总结得好！大一就该多尝试，找到自己真正喜欢的。', u: 4, lb: 8 },
      { ai: 11, c: '作为文科转前端的过来人，补充一下：一开始别被各种框架吓到，先把JS基础打扎实。', u: 9, lb: 11 },
      { ai: 16, c: '线代推荐Gilbert Strang的MIT公开课，讲得特别好。', u: 0, lb: 9 },
      { ai: 31, c: '鸿蒙开发确实是个好方向，我们学校已经开始推鸿蒙课程了。', u: 7, lb: 18 }
    ];

    for (const def of commentDefs) {
      const cmt = new CommentModel();
      cmt.id = this.genCommentId();
      cmt.targetId = this.answers[def.ai].id;
      cmt.targetType = CommentTargetType.ANSWER;
      cmt.content = def.c;
      cmt.author = this.users[def.u];
      cmt.likeCount = def.lb + this.rand(0, 10);
      const aCreated = new Date(this.answers[def.ai].createdAt).getTime();
      cmt.createdAt = new Date(aCreated + this.rand(0, 86400000)).toISOString();
      this.comments.push(cmt);
    }

    for (const a of this.answers) {
      a.commentCount = this.comments.filter(c => c.targetId === a.id).length;
    }
  }

  // ========== 通知种子数据 ==========
  private seedNotifications(): void {
    this.notifications = [];
    this.notifications.push(this.createNotification(
      'answer', '新回答', '回答了你的问题"高等数学中极限的定义到底怎么理解？"',
      6, 0, undefined));
    this.notifications.push(this.createNotification(
      'like', '收到点赞', '赞了你的回答',
      2, undefined, 0));
    this.notifications.push(this.createNotification(
      'accept', '答案被采纳', '你的回答被采纳为最佳答案',
      4, undefined, 4));
    this.notifications.push(this.createNotification(
      'follow', '新的关注', '关注了你',
      10, undefined, undefined));
    this.notifications.push(this.createNotification(
      'invite', '邀请回答', '邀请你回答问题"Python爬虫被反爬了怎么解决？"',
      2, 5, undefined));
    this.notifications.push(this.createNotification(
      'comment', '新评论', '评论了你的回答："这个射箭的比喻太形象了！"',
      2, undefined, 0));
  }

  private createNotification(type: string, title: string, content: string,
    fromUserIdx: number, targetQIdx: number | undefined, targetAIdx: number | undefined): NotificationItem {
    const n = new NotificationItem();
    n.id = this.genNotificationId();
    n.type = type;
    n.title = title;
    n.content = content;
    n.fromUserId = this.users[fromUserIdx].id;
    n.fromUserName = this.users[fromUserIdx].name;
    n.fromUserAvatar = this.users[fromUserIdx].avatar;
    n.targetQuestionId = targetQIdx !== undefined ? this.questions[targetQIdx].id : '';
    n.targetAnswerId = targetAIdx !== undefined ? this.answers[targetAIdx].id : '';
    n.isRead = Math.random() > 0.5;
    n.createdAt = new Date(Date.now() - this.rand(1, 7) * 86400000).toISOString();
    return n;
  }

  // ========== 关系数据 ==========
  private seedRelationships(): void {
    this.users[0].followedTopicIds = [this.topics[0].id, this.topics[2].id, this.topics[11].id, this.topics[4].id];
    this.users[1].followedTopicIds = [this.topics[1].id, this.topics[10].id, this.topics[3].id];
    this.users[2].followedTopicIds = [this.topics[0].id, this.topics[2].id, this.topics[5].id, this.topics[7].id, this.topics[12].id, this.topics[18].id];
    this.users[3].followedTopicIds = [this.topics[2].id, this.topics[11].id, this.topics[4].id];
    this.users[4].followedTopicIds = [this.topics[3].id, this.topics[1].id, this.topics[8].id];
    this.users[7].followedTopicIds = [this.topics[5].id, this.topics[12].id, this.topics[18].id, this.topics[13].id];
    this.users[11].followedTopicIds = [this.topics[8].id, this.topics[3].id, this.topics[9].id];
    this.users[14].followedTopicIds = [this.topics[5].id, this.topics[14].id, this.topics[15].id];

    for (const t of this.topics) {
      t.isFollowed = this.users[2].followedTopicIds.includes(t.id);
    }
  }
}

// ============ 辅助类型（仅用于种子数据）============

class AnswerDef {
  qi: number = 0;
  c: string = '';
  ai: number = 0;
  acc: boolean = false;
  lb: number = 0;
}

class CommentDef {
  ai: number = 0;
  c: string = '';
  u: number = 0;
  lb: number = 0;
}

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
  const store = getStore();
  const start = (page - 1) * pageSize;
  return store.questions.slice(start, start + pageSize);
}

export async function getQuestionById(id: string): Promise<QuestionModel | undefined> {
  await delay();
  const store = getStore();
  const result = store.questions.find(q => q.id === id);
  if (result) { result.viewCount++; }
  return result;
}

export async function getRecommendedQuestions(userId: string, page: number = 1, pageSize: number = 20): Promise<QuestionModel[]> {
  await delay();
  const store = getStore();
  const user = store.users.find(u => u.id === userId);
  if (!user) { return store.questions.slice(0, pageSize); }

  const scored: ScoredQuestion[] = [];
  for (const q of store.questions) {
    let topicOverlap = 0;
    for (const tid of q.topicIds) {
      if (user.followedTopicIds.includes(tid)) { topicOverlap++; }
    }
    let score = topicOverlap * 30;
    score += q.likeCount * 0.5;
    score += q.answerCount * 2;
    score += q.viewCount * 0.1;
    const ageHours = (Date.now() - new Date(q.createdAt).getTime()) / 3600000;
    if (ageHours < 168) { score += (168 - ageHours) / 168 * 20; }
    const item = new ScoredQuestion();
    item.question = q;
    item.score = score;
    scored.push(item);
  }

  scored.sort((a, b) => b.score - a.score);
  const start = (page - 1) * pageSize;
  const result: QuestionModel[] = [];
  for (let i = start; i < Math.min(start + pageSize, scored.length); i++) {
    result.push(scored[i].question);
  }
  return result;
}

export async function getHotQuestions(limit: number = 10): Promise<QuestionModel[]> {
  await delay();
  const store = getStore();
  const sorted: QuestionModel[] = [];
  for (const q of store.questions) {
    sorted.push(q);
  }
  sorted.sort((a, b) =>
    (b.likeCount * 1 + b.answerCount * 3 + b.viewCount * 0.5) -
    (a.likeCount * 1 + a.answerCount * 3 + a.viewCount * 0.5)
  );
  return sorted.slice(0, limit);
}

export async function getQuestionsByTopic(topicId: string, page: number = 1, pageSize: number = 20): Promise<QuestionModel[]> {
  await delay();
  const store = getStore();
  const filtered: QuestionModel[] = [];
  for (const q of store.questions) {
    if (q.topicIds.includes(topicId)) { filtered.push(q); }
  }
  const start = (page - 1) * pageSize;
  return filtered.slice(start, start + pageSize);
}

export async function searchQuestions(keyword: string): Promise<QuestionModel[]> {
  await delay();
  const store = getStore();
  const kw = keyword.toLowerCase();
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
  const store = getStore();
  const kw = keyword.toLowerCase();
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
  const result = new SearchAllResult();
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
  const store = getStore();
  const author = store.users.find(u => u.id === authorId);
  const question = new QuestionModel();
  question.id = store.genQuestionId();
  question.title = title;
  question.content = content;
  question.author = author ? author : new UserModel();
  question.topicIds = topicIds;
  question.status = QuestionStatus.OPEN;
  question.createdAt = new Date().toISOString();
  question.updatedAt = question.createdAt;
  store.questions.unshift(question);
  // 更新相关话题的问题数量
  for (const tid of topicIds) {
    const topic = store.topics.find(t => t.id === tid);
    if (topic) {
      topic.questionCount++;
    }
  }
  return question;
}

export async function toggleQuestionLike(questionId: string): Promise<QuestionModel | undefined> {
  await delay(100);
  const store = getStore();
  const q = store.questions.find(q => q.id === questionId);
  if (q) {
    q.isLiked = !q.isLiked;
    q.likeCount += q.isLiked ? 1 : -1;
  }
  return q;
}

export async function toggleQuestionCollect(questionId: string): Promise<QuestionModel | undefined> {
  await delay(100);
  const store = getStore();
  const q = store.questions.find(q => q.id === questionId);
  if (q) {
    q.isCollected = !q.isCollected;
    q.followerCount += q.isCollected ? 1 : -1;
  }
  return q;
}

// ========== 回答相关 API ==========

export async function getAnswersByQuestionId(questionId: string): Promise<AnswerModel[]> {
  await delay();
  const store = getStore();
  const filtered: AnswerModel[] = [];
  for (const a of store.answers) {
    if (a.questionId === questionId) { filtered.push(a); }
  }
  filtered.sort((a, b) => {
    if (a.isAccepted !== b.isAccepted) { return a.isAccepted ? -1 : 1; }
    return b.likeCount - a.likeCount;
  });
  return filtered;
}

export async function postAnswer(questionId: string, content: string, authorId: string): Promise<AnswerModel> {
  await delay();
  const store = getStore();
  const author = store.users.find(u => u.id === authorId);
  const answer = new AnswerModel();
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

  const question = store.questions.find(q => q.id === questionId);
  if (question) {
    question.answerCount++;
  }

  if (question && author && question.author.id !== authorId) {
    const noti = new NotificationItem();
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
  const store = getStore();
  const answer = store.answers.find(a => a.id === answerId);
  if (answer) {
    answer.isAccepted = true;
    const question = store.questions.find(q => q.id === answer.questionId);
    if (question) {
      question.status = QuestionStatus.RESOLVED;
    }
    const author = store.users.find(u => u.id === answer.author.id);
    if (author) {
      author.reputation += 25;
      author.acceptedCount += 1;
    }
  }
  return answer;
}

export async function toggleAnswerLike(answerId: string): Promise<AnswerModel | undefined> {
  await delay(100);
  const store = getStore();
  const a = store.answers.find(a => a.id === answerId);
  if (a) {
    a.isLiked = !a.isLiked;
    a.likeCount += a.isLiked ? 1 : -1;
  }
  return a;
}

// ========== 评论相关 API ==========

export async function getCommentsByTargetId(targetId: string): Promise<CommentModel[]> {
  await delay();
  const store = getStore();
  const filtered: CommentModel[] = [];
  for (const c of store.comments) {
    if (c.targetId === targetId) { filtered.push(c); }
  }
  filtered.sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());
  return filtered;
}

export async function postComment(targetId: string, targetType: CommentTargetType, content: string, authorId: string): Promise<CommentModel> {
  await delay();
  const store = getStore();
  const author = store.users.find(u => u.id === authorId);
  const comment = new CommentModel();
  comment.id = store.genCommentId();
  comment.targetId = targetId;
  comment.targetType = targetType;
  comment.content = content;
  comment.author = author ? author : new UserModel();
  comment.createdAt = new Date().toISOString();
  store.comments.push(comment);

  if (targetType === CommentTargetType.ANSWER) {
    const answer = store.answers.find(a => a.id === targetId);
    if (answer) { answer.commentCount++; }
  }

  return comment;
}

// ========== 话题相关 API ==========

export async function getAllTopics(): Promise<TopicModel[]> {
  await delay();
  const store = getStore();
  const result: TopicModel[] = [];
  for (const t of store.topics) { result.push(t); }
  return result;
}

export async function getFollowedTopics(userId: string): Promise<TopicModel[]> {
  await delay();
  const store = getStore();
  const user = store.users.find(u => u.id === userId);
  if (!user) { return []; }
  const result: TopicModel[] = [];
  for (const t of store.topics) {
    if (user.followedTopicIds.includes(t.id)) { result.push(t); }
  }
  return result;
}

export async function toggleTopicFollow(topicId: string, userId: string): Promise<TopicModel | undefined> {
  await delay(100);
  const store = getStore();
  const topic = store.topics.find(t => t.id === topicId);
  const user = store.users.find(u => u.id === userId);
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
  const store = getStore();
  return store.users.find(u => u.id === id);
}

export async function getCurrentUser(): Promise<UserModel> {
  await delay();
  const store = getStore();
  return store.users[2];
}

export async function toggleFollowUser(targetUserId: string, currentUserId: string): Promise<UserModel | undefined> {
  await delay(100);
  const store = getStore();
  const target = store.users.find(u => u.id === targetUserId);
  const current = store.users.find(u => u.id === currentUserId);
  if (target && current) {
    target.followerCount += 1;
    current.followingCount += 1;
  }
  return target;
}

// ========== 通知相关 API ==========

export async function getNotifications(userId: string): Promise<NotificationItem[]> {
  await delay();
  const store = getStore();
  const result: NotificationItem[] = [];
  for (const n of store.notifications) { result.push(n); }
  result.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  return result;
}

export async function getUnreadNotificationCount(userId: string): Promise<number> {
  await delay(100);
  const store = getStore();
  let count = 0;
  for (const n of store.notifications) {
    if (!n.isRead) { count++; }
  }
  return count;
}

export async function markNotificationRead(notificationId: string): Promise<void> {
  await delay(100);
  const store = getStore();
  const noti = store.notifications.find(n => n.id === notificationId);
  if (noti) { noti.isRead = true; }
}

// ========== 分布式相关 ==========

export async function getRelatedQuestions(questionId: string, limit: number = 5): Promise<QuestionModel[]> {
  await delay();
  const store = getStore();
  const sourceQ = store.questions.find(q => q.id === questionId);
  if (!sourceQ) { return []; }
  const related: ScoredQuestion[] = [];
  for (const other of store.questions) {
    if (other.id === questionId) { continue; }
    let overlap = 0;
    for (const tid of other.topicIds) {
      if (sourceQ.topicIds.includes(tid)) { overlap++; }
    }
    if (overlap > 0) {
      const item2 = new ScoredQuestion();
      item2.question = other;
      item2.score = other.likeCount + overlap * 10;
      related.push(item2);
    }
  }
  related.sort((a, b) => b.score - a.score);
  const result: QuestionModel[] = [];
  for (let i = 0; i < Math.min(limit, related.length); i++) {
    result.push(related[i].question);
  }
  return result;
}
