import { Controller } from '@hotwired/stimulus'
import '@popperjs/core'
import 'tippy.js';

export default class extends Controller {
  static targets = ['trigger', 'hide', 'content']

  static values = {
    appendTo: { type: String },
  }

  connect() {
    const content = this.contentTarget;
    content.classList.remove('hidden');

    this.hideTarget.addEventListener('click', () => {
      this.triggerTarget._tippy.hide();
    });

    this.show(content);
  }

  show(content) {
    tippy(this.triggerTarget, {
      content: content,
      appendTo: this.appendToValue || (() => document.body),
      interactive: true,
      offset: [0, 8],
      placement: 'bottom-start',
      trigger: 'click',
      theme: 'light',
      maxWidth: 'none',
    });
  }

  ignore(event) {
    event.stopPropagation();
  }

  hide() {
    this.triggerTarget._tippy.hide();
  }
}
