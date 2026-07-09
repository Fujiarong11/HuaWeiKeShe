/**
 * 用户信息条组件
 * 显示头像、姓名、声望等信息
 */
import { UserModel } from '../model/UserModel';

@Component
export struct UserInfoBar {
  @Prop user: UserModel = new UserModel();
  @Prop showReputation: boolean = true;
  @Prop avatarSize: number = 36;
  @Prop showTime: string = '';
  onUserClick?: (userId: string) => void;

  build() {
    Row() {
      // 头像占位（用首字代替）
      Text(this.user.name ? this.user.name.charAt(0) : '?')
        .fontSize(this.avatarSize * 0.45)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .width(this.avatarSize)
        .height(this.avatarSize)
        .borderRadius(this.avatarSize / 2)
        .backgroundColor(this.getAvatarColor(this.user.name))
        .textAlign(TextAlign.Center)

      Column() {
        Row() {
          Text(this.user.name || '匿名用户')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .maxLines(1)

          if (this.showReputation && this.user.reputation > 0) {
            Text(`Lv.${this.getLevel()}`)
              .fontSize(10)
              .fontColor('#FF9500')
              .backgroundColor('#FFF3E0')
              .borderRadius(4)
              .padding({ left: 4, right: 4, top: 2, bottom: 2 })
              .margin({ left: 4 })
          }
        }

        Row() {
          if (this.user.college) {
            Text(this.user.college)
              .fontSize(11)
              .fontColor('#999')
              .maxLines(1)
          }
          if (this.showTime) {
            Text(' · ')
              .fontSize(11)
              .fontColor('#CCC')
            Text(this.showTime)
              .fontSize(11)
              .fontColor('#999')
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 8 })
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      if (this.onUserClick && this.user.id) {
        this.onUserClick(this.user.id);
      }
    })
  }

  /**
   * 根据用户名生成稳定的头像背景色
   */
  private getAvatarColor(name: string): string {
    const colors = ['#4A90D9', '#E8634A', '#5CB85C', '#F0AD4E', '#9B59B6',
      '#1ABC9C', '#E91E63', '#FF9800', '#3F51B5', '#FF5722'];
    if (!name) { return colors[0]; }
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = name.charCodeAt(i) + ((hash << 5) - hash);
    }
    return colors[Math.abs(hash) % colors.length];
  }

  /**
   * 根据声望值计算等级
   */
  private getLevel(): number {
    const rep = this.user.reputation;
    if (rep >= 2000) { return 10; }
    if (rep >= 1500) { return 9; }
    if (rep >= 1000) { return 8; }
    if (rep >= 700) { return 7; }
    if (rep >= 500) { return 6; }
    if (rep >= 300) { return 5; }
    if (rep >= 150) { return 4; }
    if (rep >= 50) { return 3; }
    if (rep >= 10) { return 2; }
    return 1;
  }
}
