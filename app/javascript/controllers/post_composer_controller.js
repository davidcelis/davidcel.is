import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['type', 'title', 'content', 'characterCounter']
  static values = {
    characterLimit: { type: Number, default: 500 }
  }

  resizeContent() {
    this.contentTarget.style.height = 'auto';
    this.contentTarget.style.height = `${this.contentTarget.scrollHeight}px`;
  }

  countCharacters() {
    const rawContent = this.contentTarget.value || '';

    // First, parse any URLs in the content and replace them with a placeholder
    // so that each one properly registers as 23 characters.
    const urlPlaceholder = 'xxxxxxxxxxxxxxxxxxxxxxx';
    const urlRegex = /https?:\/\/[\S]+\.[\S]{2,}/g;
    let content = rawContent.replace(urlRegex, urlPlaceholder);

    // Then, parse out the domain fragment from any @mentions; for mentions like
    // @davidcelis@xoxo.zone, the "@xoxo.zone" is not counted against the limit.
    const mentionRegex = /(@\S+)@[\S]+\.[\S]{2,}/g;
    content = content.replace(mentionRegex, '$1');

    const textLength = content.length;

    this.characterCounterTarget.innerHTML = `${textLength}/${this.characterLimitValue}`;

    if (textLength > this.characterLimitValue) {
      this.titleTarget.classList.remove('hidden');
      this.characterCounterTarget.classList.add('text-red-500');
      this.typeTarget.value = 'Article';
    } else {
      this.titleTarget.classList.add('hidden');
      this.characterCounterTarget.classList.remove('text-red-500');
      this.typeTarget.value = 'Note';
    }
  }
}
