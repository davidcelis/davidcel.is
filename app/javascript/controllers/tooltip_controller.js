import { Controller } from '@hotwired/stimulus'
import '@popperjs/core'
import 'tippy.js';

export default class extends Controller {
  static targets = ['trigger', 'content']

  connect() {
    const target = this.contentTarget;
    target.classList.remove('hidden');

    tippy(this.triggerTarget, {
      content: target,
      appendTo: () => document.body,
      interactive: true,
      offset: [0, 8],
      placement: 'bottom-start',
      trigger: 'click',
      theme: 'light',
      maxWidth: 'none',
    });

    target.querySelector('button').addEventListener('click', () => {
      this.triggerTarget._tippy.hide();
    });
  }

  ignore(event) {
    event.stopPropagation();
  }
}