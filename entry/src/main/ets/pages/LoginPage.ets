/**
 * 登录页面
 * 简易登录/注册（演示用的模拟登录）
 */
import { UserViewModel } from '../viewmodel/UserViewModel';
import { router } from '@kit.ArkUI';

@Entry
@Component
export struct LoginPage {
  @State isLoading: boolean = false;
  @State username: string = '王小萌';
  @State password: string = '123456';
  private userVM: UserViewModel = UserViewModel.getInstance();

  build() {
    Column() {
      // Logo 区域
      Column() {
        Text('🎓')
          .fontSize(64).margin({ bottom: 16 })

        Text('校园问答互助平台')
          .fontSize(24).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')

        Text('知识共享，互助成长')
          .fontSize(14).fontColor('#999').margin({ top: 8 })
      }
      .width('100%').margin({ top: 80 }).alignItems(HorizontalAlign.Center)

      // 登录表单
      Column() {
        TextInput({ placeholder: '用户名', text: this.username })
          .fontSize(15).width('100%').height(48)
          .backgroundColor('#F8F9FB').borderRadius(10)
          .padding({ left: 16 }).margin({ bottom: 14 })
          .onChange((v: string) => { this.username = v; })

        TextInput({ placeholder: '密码', text: this.password })
          .fontSize(15).width('100%').height(48)
          .backgroundColor('#F8F9FB').borderRadius(10)
          .padding({ left: 16 }).margin({ bottom: 24 })
          .type(InputType.Password)
          .onChange((v: string) => { this.password = v; })

        Button('登录 / 注册')
          .fontSize(16).fontColor(Color.White).fontWeight(FontWeight.Medium)
          .width('100%').height(48)
          .backgroundColor('#4A90D9').borderRadius(24)
          .onClick(async () => {
            this.isLoading = true;
            const user = await this.userVM.login();
            this.isLoading = false;
            if (user) {
              router.replaceUrl({ url: 'pages/Index' });
            }
          })

        Text('登录即表示同意《用户协议》和《隐私政策》')
          .fontSize(11).fontColor('#BBB').margin({ top: 12 })
      }
      .width('100%').padding({ left: 32, right: 32 }).margin({ top: 50 })

      // 演示账号提示
      Column() {
        Text('💡 演示模式')
          .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#FF9500')
        Text('点击登录按钮即可自动登录体验')
          .fontSize(12).fontColor('#BBB').margin({ top: 4 })
      }
      .width('100%').padding(16).margin({ top: 30, left: 32, right: 32 })
      .backgroundColor('#FFF8E1').borderRadius(10)
      .alignItems(HorizontalAlign.Center)

      if (this.isLoading) {
        LoadingProgress()
          .width(24).height(24).margin({ top: 24 })
      }

      Blank()
    }
    .width('100%').height('100%').backgroundColor('#FFFFFF')
  }
}
