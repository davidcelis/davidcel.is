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
    const textLength = this.contentTarget.textLength;

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
