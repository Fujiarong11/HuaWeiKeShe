/**
 * 通知页面
 * 展示各类系统通知
 */
import { NotificationItem } from '../../store/DataStore';
import * as NotificationApi from '../../api/NotificationApi';
import type { NotificationResponse } from '../../api/NotificationApi';
import { EmptyPlaceholder } from '../../components/EmptyPlaceholder';
import { router } from '@kit.ArkUI';

@Component
export struct NotificationPage {
  @StorageLink('currentUserId') currentUserId: string = '';
  @State notifications: NotificationItem[] = [];
  @State isRefreshing: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.loadNotifications();
  }

  async loadNotifications(): Promise<void> {
    if (this.currentUserId) {
      try {
        const res = await NotificationApi.getNotifications(this.currentUserId);
        if (res.code === 0 && res.data) {
          const list: object[] = res.data as object[];
          const items: NotificationItem[] = [];
          for (const item of list) {
            const r: NotificationResponse = item as NotificationResponse;
            const n: NotificationItem = new NotificationItem();
            n.id = String(r.id);
            n.type = r.type;
            n.title = r.title;
            n.content = r.content;
            n.fromUserId = String(r.fromUserId || '');
            n.fromUserName = r.fromUserName || '';
            n.fromUserAvatar = r.fromUserAvatar || '';
            n.targetQuestionId = String(r.targetQuestionId || '');
            n.targetAnswerId = String(r.targetAnswerId || '');
            n.isRead = r.isRead === 1;
            n.createdAt = r.createdAt || '';
            items.push(n);
          }
          this.notifications = items;
        }
      } catch (e) {
        this.notifications = [];
      }
    }
  }

  private async onRefresh(): Promise<void> {
    this.isRefreshing = true;
    await this.loadNotifications();
    this.isRefreshing = false;
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('消息通知')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
        Blank()
        Text('全部已读')
          .fontSize(13).fontColor('#4A90D9')
          .onClick(() => {
            this.notifications.forEach(n => { n.isRead = true; });
          })
      }
      .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })

      Refresh({ refreshing: $$this.isRefreshing }) {
        if (this.notifications.length === 0) {
          Column() {
            EmptyPlaceholder({
              icon: '🔔',
              title: '暂无通知',
              description: '当有人回答你的问题或赞了你的内容时，会在这里收到通知'
            })
          }
          .width('100%').layoutWeight(1)
        } else {
          List() {
            ForEach(this.notifications, (noti: NotificationItem) => {
              ListItem() {
                Row() {
                  Text(this.getNotiIcon(noti.type))
                    .fontSize(22).width(40).height(40).borderRadius(20)
                    .backgroundColor(this.getNotiBgColor(noti.type)).textAlign(TextAlign.Center)

                  Column() {
                    Row() {
                      Text(noti.title)
                        .fontSize(14).fontWeight(noti.isRead ? FontWeight.Normal : FontWeight.Bold)
                        .fontColor(noti.isRead ? '#666' : '#1A1A1A')
                      Blank()
                      Text(this.getFormattedTime(noti.createdAt))
                        .fontSize(11).fontColor('#BBB')
                    }.width('100%')

                    Text(noti.content)
                      .fontSize(13).fontColor('#999').maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%').margin({ top: 4 })

                    if (noti.fromUserName) {
                      Row() {
                        Text(noti.fromUserName.charAt(0))
                          .fontSize(10).fontColor(Color.White)
                          .width(18).height(18).borderRadius(9)
                          .backgroundColor('#999').textAlign(TextAlign.Center)
                        Text(noti.fromUserName)
                          .fontSize(12).fontColor('#999').margin({ left: 4 })
                      }.margin({ top: 6 })
                    }
                  }
                  .layoutWeight(1).margin({ left: 10 }).alignItems(HorizontalAlign.Start)

                  if (!noti.isRead) {
                    Circle({ width: 8, height: 8 })
                      .fill('#FF4757')
                      .margin({ left: 8 })
                  }
                }
                .width('100%').padding(14).backgroundColor(noti.isRead ? Color.White : '#FAFBFF').borderRadius(10)
                .margin({ left: 16, right: 16, top: 4, bottom: 4 })
                .onClick(() => {
                  NotificationApi.markRead(noti.id);
                  noti.isRead = true;
                  if (noti.targetQuestionId) {
                    router.pushUrl({
                      url: 'pages/question/tiezi',
                      params: { questionId: noti.targetQuestionId }
                    });
                  }
                })
              }
            }, (noti: NotificationItem) => noti.id)
          }
          .width('100%').layoutWeight(1).scrollBar(BarState.Off)
        }
      }
      .onRefreshing(() => {
        this.onRefresh();
      })
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#F5F6FA')
  }

  private getNotiIcon(type: string): string {
    switch (type) {
      case 'answer': return '💬';
      case 'like': return '❤️';
      case 'accept': return '✅';
      case 'follow': return '👤';
      case 'invite': return '📩';
      case 'comment': return '💭';
      default: return '🔔';
    }
  }

  private getNotiBgColor(type: string): string {
    switch (type) {
      case 'answer': return '#E3F2FD';
      case 'like': return '#FFEBEE';
      case 'accept': return '#E8F5E9';
      case 'follow': return '#F3E5F5';
      case 'invite': return '#FFF3E0';
      case 'comment': return '#E0F7FA';
      default: return '#F5F5F5';
    }
  }

  private getFormattedTime(dateStr: string): string {
    if (!dateStr) { return ''; }
    const now = Date.now();
    const target = new Date(dateStr).getTime();
    const diff = now - target;
    const mins = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);
    if (mins < 1) { return '刚刚'; }
    if (mins < 60) { return `${mins}分钟前`; }
    if (hours < 24) { return `${hours}小时前`; }
    if (days < 7) { return `${days}天前`; }
    return new Date(dateStr).toLocaleDateString();
  }
}
