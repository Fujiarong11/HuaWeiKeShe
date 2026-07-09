/**
 * 服务卡片 FormExtensionAbility
 * 桌面卡片：调后端 API 获取热门问题（按浏览量排名）
 */
import { formBindingData, formProvider, FormExtensionAbility } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import * as QuestionApi from '../api/QuestionApi';
import type { QuestionResponse } from '../api/QuestionApi';

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const data: Record<string, Object> = {
      'title': '🔥 热门问题',
      'question1': '正在加载...', 'question2': '', 'question3': '',
      'answerCount1': '', 'answerCount2': '', 'answerCount3': '',
      'qid1': '', 'qid2': '', 'qid3': '',
      'inviteTitle': '📩 邀请回答', 'inviteCount': '',
      'updateTime': ''
    };
    const formId: string = want.parameters?.['ohos.extra.param.key.form_identity'] as string;
    if (formId) {
      this.loadAndUpdateForm(formId);
    }
    return formBindingData.createFormBindingData(data);
  }

  onUpdateForm(formId: string): void {
    this.loadAndUpdateForm(formId);
  }

  onCastToNormalForm(formId: string): void {}
  onFormEvent(formId: string, message: string): void {}
  onRemoveForm(formId: string): void {}

  private async loadAndUpdateForm(formId: string): Promise<void> {
    if (!formId) { return; }
    try {
      const res = await QuestionApi.getHotQuestions(1, 3);
      const data: Record<string, Object> = {
        'title': '🔥 热门问题',
        'question1': '', 'question2': '', 'question3': '',
        'answerCount1': '', 'answerCount2': '', 'answerCount3': '',
        'qid1': '', 'qid2': '', 'qid3': '',
        'inviteTitle': '📩 邀请回答', 'inviteCount': '查看详情',
        'updateTime': new Date().toLocaleTimeString()
      };

      if (res.code === 0 && res.data) {
        const list: object[] = res.data as object[];
        const items: QuestionResponse[] = [];
        for (const item of list) {
          items.push(item as QuestionResponse);
        }
        if (items.length > 0) {
          data['question1'] = items[0].title.substring(0, 30);
          data['answerCount1'] = `👁${items[0].viewCount} 💬${items[0].answerCount}`;
          data['qid1'] = String(items[0].id);
        }
        if (items.length > 1) {
          data['question2'] = items[1].title.substring(0, 30);
          data['answerCount2'] = `👁${items[1].viewCount} 💬${items[1].answerCount}`;
          data['qid2'] = String(items[1].id);
        }
        if (items.length > 2) {
          data['question3'] = items[2].title.substring(0, 30);
          data['answerCount3'] = `👁${items[2].viewCount} 💬${items[2].answerCount}`;
          data['qid3'] = String(items[2].id);
        }
      } else {
        data['question1'] = '请先启动后端服务';
        data['question2'] = '然后登录应用发帖';
        data['question3'] = '即可查看热门问题';
      }

      const binding = formBindingData.createFormBindingData(data);
      formProvider.updateForm(formId, binding);
    } catch (_e) {
      const data: Record<string, Object> = {
        'title': '🔥 热门问题',
        'question1': '请先启动后端服务', 'question2': '', 'question3': '',
        'qid1': '', 'qid2': '', 'qid3': '',
        'answerCount1': '', 'answerCount2': '', 'answerCount3': '',
        'inviteTitle': '📩 邀请回答', 'inviteCount': '',
        'updateTime': new Date().toLocaleTimeString()
      };
      formProvider.updateForm(formId, formBindingData.createFormBindingData(data));
    }
  }
}
