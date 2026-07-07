/**
 * 搜索栏组件
 */
@Component
export struct SearchBar {
  @Prop placeholder: string = '搜索问题、话题、用户...';
  @Prop showBack: boolean = false;
  onChange?: (value: string) => void;
  onSubmit?: (value: string) => void;
  onBack?: () => void;
  private inputValue: string = '';

  build() {
    Row() {
      if (this.showBack) {
        Text('←')
          .fontSize(22)
          .fontColor('#333')
          .margin({ right: 8 })
          .onClick(() => {
            if (this.onBack) {
              this.onBack();
            }
          })
      }

      Row() {
        Text('🔍')
          .fontSize(14)
          .margin({ right: 6 })

        TextInput({ placeholder: this.placeholder, text: this.inputValue })
          .fontSize(14)
          .layoutWeight(1)
          .height(36)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .onChange((value: string) => {
            this.inputValue = value;
            if (this.onChange) {
              this.onChange(value);
            }
          })
          .onSubmit((enterKey: EnterKeyType) => {
            if (this.onSubmit) {
              this.onSubmit(this.inputValue);
            }
          })
      }
      .layoutWeight(1)
      .height(40)
      .backgroundColor('#F5F5F5')
      .borderRadius(20)
      .padding({ left: 12, right: 12 })

      if (this.inputValue) {
        Text('取消')
          .fontSize(14)
          .fontColor('#4A90D9')
          .margin({ left: 10 })
          .onClick(() => {
            this.inputValue = '';
            if (this.onChange) {
              this.onChange('');
            }
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }
}
