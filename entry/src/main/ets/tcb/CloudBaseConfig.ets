/**
 * 腾讯云 CloudBase 配置
 * 环境 ID 和云函数名称
 */
export class CloudBaseConfig {
  /** 腾讯云环境 ID */
  env: string = 'huawei-login-d7g6viioB93b9ca26';

  /** 云函数名称 */
  functionName: string = 'scfnodejshelloworld';
}

export const CLOUDBASE_CONFIG = new CloudBaseConfig();
