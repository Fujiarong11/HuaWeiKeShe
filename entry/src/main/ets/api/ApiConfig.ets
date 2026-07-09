/**
 * 后端 API 地址配置
 * 本地开发时用电脑局域网IP + 后端端口，
 * 部署到服务器后改成服务器地址。
 *
 * ⚠️ 连接前请确保：
 *   1. 手机和电脑在同一WiFi
 *   2. 后端已启动（在IDEA里运行 CampusQaApplication）
 *   3. MySQL 已启动
 */
export class ApiConfig {
  /** 后端 API 基础地址 */
  static BASE_URL: string = 'http://172.20.10.5:8080';
}
