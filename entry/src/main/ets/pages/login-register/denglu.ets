/**
 * 登录 / 注册页面
 * 支持手机号登录和用户名注册两种模式，对接 Spring Boot 后端 HTTP API
 *
 * 页面布局从上到下：
 *   Logo → 模式切换Tab → 输入表单 → 提交按钮 → 底部提示
 *
 * 业务流程：
 *   表单输入 → 前端校验 → 调用 AuthService → 成功则跳转首页 / 失败则 Toast 提示
 */

// ==================== 导入依赖 ====================
import { AuthService } from '../../services/AuthService';
import { UserViewModel } from '../../viewmodel/UserViewModel';
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';

// ==================== 页面入口 ====================
@Entry
@Component
export struct LoginPage {
  // ==================== 状态变量 ====================
  @State isRegisterMode: boolean = false;   // true=注册模式  false=登录模式
  @State isLoading: boolean = false;        // 提交中，按钮禁用 +  loading 动画

  // ---- 登录 & 注册共用 ----
  @State phone: string = '';                // 手机号
  @State password: string = '';             // 密码

  // ---- 仅注册使用 ----
  @State username: string = '';             // 用户名
  @State confirmPassword: string = '';      // 确认密码

  // ==================== 服务实例 ====================
  private authService: AuthService = AuthService.getInstance();
  private userVM: UserViewModel = UserViewModel.getInstance();

  // ==================== UI 构建 ====================
  build() {
    Column() {
      // ========== ① Logo 品牌区 ==========
      Column() {
        Text('🎓')
          .fontSize(64)
          .margin({ bottom: 16 })

        Text('校园问答互助平台')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')

        Text('知识共享，互助成长')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 8 })
      }
      .width('100%')
      .margin({ top: 50 })
      .alignItems(HorizontalAlign.Center)

      // ========== ② 登录/注册 模式切换 Tab ==========
      Row() {
        Button('手机号登录')
          .fontSize(16)
          .fontWeight(this.isRegisterMode ? FontWeight.Normal : FontWeight.Bold)
          .fontColor(this.isRegisterMode ? '#999' : '#4A90D9')
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onClick(() => { this.isRegisterMode = false; })

        Text('|')
          .fontSize(18)
          .fontColor('#DDD')

        Button('账号注册')
          .fontSize(16)
          .fontWeight(this.isRegisterMode ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.isRegisterMode ? '#5CB85C' : '#999')
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onClick(() => { this.isRegisterMode = true; })
      }
      .width('60%')
      .margin({ top: 32 })
      .justifyContent(FlexAlign.Center)

      // ========== ③ 输入表单区 ==========
      Column() {
        // ---- 注册模式才显示：用户名 ----
        if (this.isRegisterMode) {
          TextInput({ placeholder: '请输入用户名（2-20字符）', text: this.username })
            .fontSize(15)
            .width('100%')
            .height(48)
            .backgroundColor('#F8F9FB')
            .borderRadius(10)
            .padding({ left: 16 })
            .margin({ bottom: 14 })
            .maxLength(20)
            .onChange((v: string) => { this.username = v; })
        }

        // ---- 手机号（登录 + 注册共用）----
        TextInput({ placeholder: '请输入手机号', text: this.phone })
          .fontSize(15)
          .width('100%')
          .height(48)
          .backgroundColor('#F8F9FB')
          .borderRadius(10)
          .padding({ left: 16 })
          .margin({ bottom: 14 })
          .type(InputType.PhoneNumber)
          .maxLength(11)
          .onChange((v: string) => { this.phone = v; })

        // ---- 密码（登录 + 注册共用）----
        TextInput({ placeholder: '请输入密码（6-20字符）', text: this.password })
          .fontSize(15)
          .width('100%')
          .height(48)
          .backgroundColor('#F8F9FB')
          .borderRadius(10)
          .padding({ left: 16 })
          .margin({ bottom: 14 })
          .type(InputType.Password)
          .maxLength(20)
          .onChange((v: string) => { this.password = v; })

        // ---- 注册模式才显示：确认密码 ----
        if (this.isRegisterMode) {
          TextInput({ placeholder: '请再次输入密码', text: this.confirmPassword })
            .fontSize(15)
            .width('100%')
            .height(48)
            .backgroundColor('#F8F9FB')
            .borderRadius(10)
            .padding({ left: 16 })
            .margin({ bottom: 14 })
            .type(InputType.Password)
            .maxLength(20)
            .onChange((v: string) => { this.confirmPassword = v; })
        }

        // ---- 提交按钮（根据模式显示"登录"或"注册"）----
        Button(this.isRegisterMode ? '注 册' : '登 录')
          .fontSize(16)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .height(48)
          .backgroundColor(this.isRegisterMode ? '#5CB85C' : '#4A90D9')
          .borderRadius(24)
          .enabled(!this.isLoading)
          .opacity(this.isLoading ? 0.6 : 1.0)
          .onClick(async () => { await this.handleSubmit(); })

        // ---- 底部切换提示文字 ----
        Text(this.isRegisterMode ? '已有账号？点击上方「手机号登录」' : '没有账号？点击上方「账号注册」')
          .fontSize(12)
          .fontColor('#BBB')
          .margin({ top: 16 })
      }
      .width('100%')
      .padding({ left: 32, right: 32 })
      .margin({ top: 24 })

      // ---- 提交 loading 动画 ----
      if (this.isLoading) {
        LoadingProgress()
          .width(24)
          .height(24)
          .margin({ top: 20 })
          .color('#4A90D9')
      }

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  // ==================== 业务逻辑 ====================

  /**
   * ③ 表单前端校验
   * 在发送 HTTP 请求前先验证格式合法性，减少无效请求
   * @returns 错误消息字符串，null 表示校验通过
   */
  private validateForm(): string | null {
    // ---- 注册模式：校验用户名格式 ----
    if (this.isRegisterMode) {
      const userError = this.authService.validateUsername(this.username);
      if (userError) {
        return userError;
      }
    }

    // ---- 校验手机号格式（登录注册都需要）----
    const phoneError = this.authService.validatePhone(this.phone);
    if (phoneError) {
      return phoneError;
    }

    // ---- 校验密码长度 ----
    const passError = this.authService.validatePassword(this.password);
    if (passError) {
      return passError;
    }

    // ---- 注册模式：两次密码一致性 ----
    if (this.isRegisterMode) {
      if (!this.confirmPassword) {
        return '请再次输入密码';
      }
      if (this.password !== this.confirmPassword) {
        return '两次输入的密码不一致';
      }
    }

    return null;  // 校验通过
  }

  /**
   * ④ 表单提交处理
   * 校验 → 调 AuthService API → 写 UserViewModel 状态 → 跳转首页
   */
  private async handleSubmit(): Promise<void> {
    // Step 1: 前端校验
    const error = this.validateForm();
    if (error) {
      promptAction.showToast({ message: error, duration: 2000 });
      return;
    }

    this.isLoading = true;

    try {
      if (this.isRegisterMode) {
        // ---- 注册流程 ----
        const result = await this.authService.register(
          this.username.trim(),
          this.phone.trim(),
          this.password
        );

        if (result.success && result.user) {
          // 写入全局登录状态
          this.userVM.isLoggedIn = true;
          this.userVM.currentUser = result.user;
          promptAction.showToast({ message: '注册成功！', duration: 1500 });
          router.replaceUrl({ url: 'pages/home/Index' });
        } else {
          promptAction.showToast({ message: result.error || '注册失败，请重试', duration: 2000 });
        }
      } else {
        // ---- 登录流程 ----
        const result = await this.authService.login(this.phone.trim(), this.password);

        if (result.success && result.user) {
          // 写入全局登录状态
          this.userVM.isLoggedIn = true;
          this.userVM.currentUser = result.user;
          promptAction.showToast({ message: '登录成功！', duration: 1500 });
          router.replaceUrl({ url: 'pages/home/Index' });
        } else {
          promptAction.showToast({ message: result.error || '登录失败，请重试', duration: 2000 });
        }
      }
    } catch (e) {
      // 网络异常兜底
      promptAction.showToast({ message: '网络连接失败，请检查网络后重试', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }
}
