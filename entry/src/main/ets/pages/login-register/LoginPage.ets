/**
 * 登录页面
 * 支持手机号登录和用户名注册两种模式
 * 对接 Spring Boot 后端 HTTP API
 */
import { AuthService } from '../../services/AuthService';
import { UserViewModel } from '../../viewmodel/UserViewModel';
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
export struct LoginPage {
  @State isRegisterMode: boolean = false;   // 登录/注册模式切换
  @State isLoading: boolean = false;
  // 公共字段
  @State phone: string = '';                 // 手机号（登录和注册都用）
  @State password: string = '';
  // 注册专用字段
  @State username: string = '';
  @State confirmPassword: string = '';

  private authService: AuthService = AuthService.getInstance();
  private userVM: UserViewModel = UserViewModel.getInstance();

  build() {
    Column() {
      // Logo 区域
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

      // 登录/注册 切换 Tab
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

      // 表单区域
      Column() {
        // 注册模式：用户名
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

        // 手机号
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

        // 密码
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

        // 注册模式：确认密码
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

        // 提交按钮
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

        // 底部提示
        Text(this.isRegisterMode ? '已有账号？点击上方「手机号登录」' : '没有账号？点击上方「账号注册」')
          .fontSize(12)
          .fontColor('#BBB')
          .margin({ top: 16 })
      }
      .width('100%')
      .padding({ left: 32, right: 32 })
      .margin({ top: 24 })

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

  /**
   * 表单验证
   */
  private validateForm(): string | null {
    // 注册模式校验用户名
    if (this.isRegisterMode) {
      const userError = this.authService.validateUsername(this.username);
      if (userError) {
        return userError;
      }
    }

    // 校验手机号（登录和注册都需要）
    const phoneError = this.authService.validatePhone(this.phone);
    if (phoneError) {
      return phoneError;
    }

    // 校验密码
    const passError = this.authService.validatePassword(this.password);
    if (passError) {
      return passError;
    }

    // 注册模式额外校验确认密码
    if (this.isRegisterMode) {
      if (!this.confirmPassword) {
        return '请再次输入密码';
      }
      if (this.password !== this.confirmPassword) {
        return '两次输入的密码不一致';
      }
    }

    return null;
  }

  /**
   * 处理提交
   */
  private async handleSubmit(): Promise<void> {
    const error = this.validateForm();
    if (error) {
      promptAction.showToast({ message: error, duration: 2000 });
      return;
    }

    this.isLoading = true;

    try {
      if (this.isRegisterMode) {
        // --- 注册 ---
        const result = await this.authService.register(
          this.username.trim(),
          this.phone.trim(),
          this.password
        );

        if (result.success && result.user) {
          this.userVM.isLoggedIn = true;
          this.userVM.currentUser = result.user;
          promptAction.showToast({ message: '注册成功！', duration: 1500 });
          router.replaceUrl({ url: 'pages/home/Index' });
        } else {
          promptAction.showToast({ message: result.error || '注册失败，请重试', duration: 2000 });
        }
      } else {
        // --- 登录 ---
        const result = await this.authService.login(this.phone.trim(), this.password);

        if (result.success && result.user) {
          this.userVM.isLoggedIn = true;
          this.userVM.currentUser = result.user;
          promptAction.showToast({ message: '登录成功！', duration: 1500 });
          router.replaceUrl({ url: 'pages/home/Index' });
        } else {
          promptAction.showToast({ message: result.error || '登录失败，请重试', duration: 2000 });
        }
      }
    } catch (e) {
      promptAction.showToast({ message: '网络连接失败，请检查网络后重试', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }
}
