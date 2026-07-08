# 云函数部署说明

## 目录结构

```
cloudfunctions/
├── README.md                  # 本文件
└── user-auth/                 # 用户认证云函数
    ├── package.json           # 依赖配置
    └── index.js               # 主函数代码
```

## 部署步骤

### 1. 登录华为 AGC 控制台

前往 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)，进入你的项目。

### 2. 创建云函数

1. 在 AGC 控制台左侧菜单选择「云函数」
2. 点击「创建云函数」
3. 函数名称：`user-auth`
4. 运行时：Node.js 18

### 3. 部署代码

将 `user-auth` 目录下的文件打包上传：

```bash
cd cloudfunctions/user-auth
npm install
zip -r user-auth.zip .
```

在 AGC 控制台上传 `user-auth.zip` 并部署。

### 4. 配置云数据库

1. 在 AGC 控制台选择「云数据库」
2. 创建集合 `users`
3. 为 `username` 字段创建唯一索引

## 前端调用

```typescript
import agconnect from '@hw-agconnect/cloud';

const result = await agconnect.cloud().callFunction({
  name: 'user-auth',
  version: '$latest',
  data: {
    action: 'register',  // 或 'login'
    username: 'testuser',
    password: '123456'
  }
});
```

## API 说明

### 注册（register）

**请求:**
```json
{ "action": "register", "username": "用户名", "password": "密码" }
```

**成功响应:**
```json
{
  "success": true,
  "user": { "id": "...", "username": "...", "name": "...", ... },
  "token": "base64token..."
}
```

**失败响应:**
```json
{ "success": false, "error": "用户名已存在 / 校验失败信息" }
```

### 登录（login）

**请求:**
```json
{ "action": "login", "username": "用户名", "password": "密码" }
```

**成功响应:**
```json
{
  "success": true,
  "user": { "id": "...", "username": "...", "name": "...", ... },
  "token": "base64token..."
}
```

**失败响应:**
```json
{ "success": false, "error": "用户名或密码错误" }
```
