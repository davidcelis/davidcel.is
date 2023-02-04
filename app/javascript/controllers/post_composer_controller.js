import { Controller } from '@hotwired/stimulus'
import { defineOptions, ink } from 'ink-mde'

import { remark } from 'remark'
import remarkGfm from 'remark-gfm'
import remarkSmartypants from '@davidcelis/remark-smartypants'

export default class extends Controller {
  static targets = ['editor', 'type', 'title', 'content', 'characterCounter']
  static values = {
    characterLimit: { type: Number, default: 500 }
  }

  static mentionRegex = /(?<=^|[^\/\w])(?:(@[a-z0-9_]+)((?:@[\w.-]+\w+)?))/gi
  static urlRegex = /https?:\/\/[\S]+\.[\S]{2,}/gi
  static urlPlaceholder = 'xxxxxxxxxxxxxxxxxxxxxxx'

  static markdownProcessor = remark()
    .use(remarkGfm)
    .use(remarkSmartypants)

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
    this.contentTarget.value = content.trim();
  }

  async countCharacters(rawContent) {
    // First, parse out the domain fragment from any mentions; for mentions like
    // @davidcelis@xoxo.zone, the "@xoxo.zone" is not counted against the limit.
    let content = rawContent.replaceAll(this.constructor.mentionRegex, '$1');

    // Then, parse any URLs in the content and replace them with a placeholder
    // so that each one properly registers as 23 characters.
    content = content.replaceAll(this.constructor.urlRegex, this.constructor.urlPlaceholder);

    // Finally, parse out any remaining Markdown syntax from the content.
    content = await this.constructor.markdownProcessor.process(content);
    content = String(content).trim();

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
