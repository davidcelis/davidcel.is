import { Controller } from '@hotwired/stimulus'
import { defineOptions, ink } from 'ink-mde'

export default class extends Controller {
  static targets = ['editor', 'type', 'title', 'content', 'characterCounter']
  static values = {
    characterLimit: { type: Number, default: 500 }
  }

  static mentionRegex = /(@[\S]+)@[\S]+\.[\S]{2,}/g
  static urlRegex = /https?:\/\/[\S]+\.[\S]{2,}/g
  static urlPlaceholder = 'xxxxxxxxxxxxxxxxxxxxxxx'

  connect () {
    const options = defineOptions({
      interface: {
        attribution: false,
      },
      hooks: {
        afterUpdate: (content) => {
          this.countCharacters(content);
          this.setHiddenContentField(content);
        }
      }
    });

    ink(this.editorTarget, options);
  }

  setHiddenContentField(content) {
    this.contentTarget.value = content;
  }

  countCharacters(rawContent) {
    // First, parse any URLs in the content and replace them with a placeholder
    // so that each one properly registers as 23 characters.
    let content = rawContent.replace(this.constructor.urlRegex, this.constructor.urlPlaceholder);

    // Then, parse out the domain fragment from any @mentions; for mentions like
    // @davidcelis@xoxo.zone, the "@xoxo.zone" is not counted against the limit.
    content = content.replace(this.constructor.mentionRegex, '$1');

    const textLength = content.length;

    this.characterCounterTarget.innerHTML = `${textLength}/${this.characterLimitValue}`;

    if (textLength > this.characterLimitValue) {
      this.titleTarget.classList.remove('hidden');
      this.characterCounterTarget.classList.remove('text-slate-500');
      this.characterCounterTarget.classList.add('text-pink-500');
      this.typeTarget.value = 'Article';
    } else {
      this.titleTarget.classList.add('hidden');
      this.characterCounterTarget.classList.remove('text-pink-500');
      this.characterCounterTarget.classList.add('text-slate-500');
      this.typeTarget.value = 'Note';
    }
  }
}
