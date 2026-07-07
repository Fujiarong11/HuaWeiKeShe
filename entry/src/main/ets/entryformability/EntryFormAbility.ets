/**
 * 服务卡片 FormExtensionAbility
 * 提供服务卡片的数据绑定和更新逻辑
 */
import { formBindingData, formInfo, formProvider, FormExtensionAbility } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { getHotQuestions } from '../mock/MockData';

export default class EntryFormAbility extends FormExtensionAbility {
  /**
   * 卡片创建时回调
   */
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formData: Record<string, Object> = {
      'title': '热门问题',
      'question1': '加载中...',
      'question2': '加载中...',
      'question3': '加载中...',
      'answerCount1': '0',
      'answerCount2': '0',
      'answerCount3': '0',
      'updateTime': new Date().toLocaleTimeString()
    };

    const formId: string = want.parameters?.['ohos.extra.param.key.form_identity'] as string;
    if (formId) {
      this.loadAndUpdateForm(formId);
    }

    return formBindingData.createFormBindingData(formData);
  }

  onUpdateForm(formId: string): void {
    this.loadAndUpdateForm(formId);
  }

  onCastToNormalForm(formId: string): void {
  }

  onFormEvent(formId: string, message: string): void {
  }

  onRemoveForm(formId: string): void {
  }

  private async loadAndUpdateForm(formId: string): Promise<void> {
    if (!formId) { return; }
    try {
      const hotQuestions = await getHotQuestions(3);
      const formData: Record<string, Object> = {
        'title': '🔥 热门问题',
        'question1': hotQuestions.length > 0 ? hotQuestions[0].title.substring(0, 30) : '暂无',
        'question2': hotQuestions.length > 1 ? hotQuestions[1].title.substring(0, 30) : '暂无',
        'question3': hotQuestions.length > 2 ? hotQuestions[2].title.substring(0, 30) : '暂无',
        'answerCount1': hotQuestions.length > 0 ? `${hotQuestions[0].answerCount} 回答` : '',
        'answerCount2': hotQuestions.length > 1 ? `${hotQuestions[1].answerCount} 回答` : '',
        'answerCount3': hotQuestions.length > 2 ? `${hotQuestions[2].answerCount} 回答` : '',
        'updateTime': new Date().toLocaleTimeString()
      };
      const bindingData = formBindingData.createFormBindingData(formData);
      formProvider.updateForm(formId, bindingData);
    } catch (e) {
      // 更新失败，保持旧数据
    }
  }
}
