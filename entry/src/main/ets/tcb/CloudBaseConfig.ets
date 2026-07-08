/**
 * 腾讯云 CloudBase 配置
 * 环境 ID 和云函数名称
 */
export const CLOUDBASE_CONFIG = {
  /** 腾讯云环境 ID */
  env: 'huawei-login-d7g6viioB93b9ca26',

  /** 云函数名称 */
  functionName: 'scfnodejshelloworld',

  /** 云函数 HTTP 触发地址 */
  get httpEndpoint(): string {
    return `https://${this.env}.service.tcloudbase.com/${this.functionName}`;
  }
};
