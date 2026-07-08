/**
 * 用户认证云函数
 * 处理注册（user-register）和登录（user-login）
 *
 * 前端调用方式（AGC SDK）：
 *   agconnect.cloud.callFunction({
 *     name: 'user-auth',
 *     version: '$latest',
 *     data: { action: 'login', username: 'xxx', password: 'xxx' }
 *   })
 */
const bcrypt = require('bcryptjs');

const SALT_ROUNDS = 10; // bcrypt 哈希强度

// ============================================================
// AGC 云数据库操作（实际部署时需要替换为云数据库 SDK）
// ============================================================

/**
 * 模拟云数据库 - 实际部署时替换为 AGC cloudDB 调用
 * 使用 Map 存储用户，key 为 username（唯一索引）
 */
const userDB = new Map();

/**
 * 根据用户名查询用户
 * 实际部署：cloudDB.collection('users').where({ username }).get()
 */
async function findUserByUsername(username) {
  // TODO: 替换为 AGC 云数据库查询
  // const result = await cloudDB.collection('users').where({ username }).get();
  // return result.data[0] || null;
  return userDB.get(username) || null;
}

/**
 * 插入新用户
 * 实际部署：cloudDB.collection('users').add(user)
 */
async function insertUser(user) {
  // TODO: 替换为 AGC 云数据库插入
  // const result = await cloudDB.collection('users').add(user);
  // return result;
  userDB.set(user.username, user);
  return user;
}

// ============================================================
// 工具函数
// ============================================================

/**
 * 创建新用户对象（不含密码）
 */
function createUserObject(username) {
  const now = new Date().toISOString();
  return {
    id: `u_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
    username: username,
    name: username, // 默认显示名同用户名
    avatar: '',
    bio: '',
    college: '',
    major: '',
    grade: '',
    reputation: 0,
    acceptedCount: 0,
    totalAnswers: 0,
    totalQuestions: 0,
    followerCount: 0,
    followingCount: 0,
    followedTopicIds: [],
    likedAnswerIds: [],
    collectedQuestionIds: [],
    createdAt: now
  };
}

/**
 * 生成简易 token（实际部署时应使用 JWT）
 */
function generateToken(user) {
  // TODO: 替换为 JWT 签名
  // return jwt.sign({ userId: user.id, username: user.username }, SECRET, { expiresIn: '7d' });
  const payload = JSON.stringify({ userId: user.id, username: user.username, ts: Date.now() });
  return Buffer.from(payload).toString('base64');
}

/**
 * 校验输入参数
 */
function validateInput(username, password) {
  const errors = [];

  if (!username || username.trim().length === 0) {
    errors.push('用户名不能为空');
  } else if (username.trim().length < 2) {
    errors.push('用户名至少需要2个字符');
  } else if (username.trim().length > 20) {
    errors.push('用户名不能超过20个字符');
  } else if (!/^[a-zA-Z0-9_一-龥]+$/.test(username.trim())) {
    errors.push('用户名只能包含中文、英文、数字和下划线');
  }

  if (!password || password.length === 0) {
    errors.push('密码不能为空');
  } else if (password.length < 6) {
    errors.push('密码至少需要6个字符');
  } else if (password.length > 20) {
    errors.push('密码不能超过20个字符');
  }

  return errors;
}

// ============================================================
// 处理入口
// ============================================================

/**
 * 注册处理
 */
async function handleRegister(username, password) {
  // 1. 输入校验
  const errors = validateInput(username, password);
  if (errors.length > 0) {
    return { success: false, error: errors[0] };
  }

  const cleanUsername = username.trim();

  // 2. 检查用户名是否已存在
  const existingUser = await findUserByUsername(cleanUsername);
  if (existingUser) {
    return { success: false, error: '该用户名已被注册' };
  }

  // 3. 密码哈希
  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

  // 4. 创建用户对象
  const newUser = createUserObject(cleanUsername);
  newUser.passwordHash = passwordHash;

  // 5. 存入数据库
  await insertUser(newUser);

  // 6. 生成 token
  const token = generateToken(newUser);

  // 7. 返回用户信息（不含密码）
  const userWithoutPassword = { ...newUser };
  delete userWithoutPassword.passwordHash;

  return {
    success: true,
    user: userWithoutPassword,
    token: token
  };
}

/**
 * 登录处理
 */
async function handleLogin(username, password) {
  // 1. 输入校验
  const errors = validateInput(username, password);
  if (errors.length > 0) {
    return { success: false, error: errors[0] };
  }

  const cleanUsername = username.trim();

  // 2. 查询用户
  const user = await findUserByUsername(cleanUsername);
  if (!user) {
    return { success: false, error: '用户名或密码错误' };
  }

  // 3. 密码比对
  const isMatch = await bcrypt.compare(password, user.passwordHash);
  if (!isMatch) {
    return { success: false, error: '用户名或密码错误' };
  }

  // 4. 生成 token
  const token = generateToken(user);

  // 5. 返回用户信息（不含密码）
  const userWithoutPassword = { ...user };
  delete userWithoutPassword.passwordHash;

  return {
    success: true,
    user: userWithoutPassword,
    token: token
  };
}

// ============================================================
// AGC 云函数入口
// ============================================================

/**
 * 云函数主入口
 * event.data 从 agconnect.cloud.callFunction 的 data 参数传入
 */
module.exports.handler = async function (event, context, callback, logger) {
  const { action, username, password } = event.data || event;

  logger.info(`user-auth called, action: ${action}, username: ${username}`);

  let result;
  switch (action) {
    case 'register':
      result = await handleRegister(username, password);
      break;
    case 'login':
      result = await handleLogin(username, password);
      break;
    default:
      result = { success: false, error: `未知操作: ${action}，支持 register 或 login` };
  }

  logger.info(`user-auth result: ${JSON.stringify({ action, success: result.success })}`);

  return result;
};
