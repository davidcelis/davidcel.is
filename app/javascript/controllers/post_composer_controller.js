import { Controller } from '@hotwired/stimulus'
import { defineOptions, ink } from 'ink-mde'

export default class extends Controller {
  static targets = ['editor', 'type', 'title', 'content', 'mediaAttachments', 'characterCounter', 'dummyFileField'];
  static values = {
    characterLimit: { type: Number, default: 500 },
    fileLimit: { type: Number, default: 4 },
  };

  // TODO: Once Safari supports positive look-behinds, we can use these instead:
  // static mentionRegex = /(?<=^|[^\/\w])(?:(@[a-z0-9_]+)((?:@[\w.-]+\w+)?))/gi;
  // static urlRegex = /(?<=^|[^\/\w])https?:\/\/[\S]+\.[\S]{2,}/gi;
  static mentionRegex = /(?:^|[^\/\S])(?:(@[a-z0-9_]+)((?:@[\w.-]+\w+)?))/gi;
  static urlRegex = /(?:^|[^\/\S])https?:\/\/[\S]+\.[\S]{2,}/gi;
  static urlPlaceholder = 'xxxxxxxxxxxxxxxxxxxxxxx';

  connect () {
    const options = defineOptions({
      interface: {
        appearance: 'light',
        attribution: false,
      },
      hooks: {
        afterUpdate: (content) => {
          this.parseContent(content);
        }
      },
      files: {
        clipboard: true,
        dragAndDrop: true,
        injectMarkup: false,
        types: ['image/*', 'video/*'],
        handler: (files) => {
          this.addMediaAttachments(files);
        },
      },
    });

    ink(this.editorTarget, options);
  };

  selectFiles() {
    this.dummyFileFieldTarget.click();
  }

  dummyFileFieldChanged() {
    this.addMediaAttachments(this.dummyFileFieldTarget.files)

    this.dummyFileFieldTarget.value = null;
  }

  addMediaAttachments(files) {
    // Create a new DataTransfer object to store any already-selected files
    // along with the new files we're adding here.
    const dataTransfer = new DataTransfer();

    // Add the existing files to the DataTransfer object
    for (let i = 0; i < this.mediaAttachmentsTarget.files.length; i++) {
      dataTransfer.items.add(this.mediaAttachmentsTarget.files[i]);
    }

    // Add newly selected files to the DataTransfer object, skipping any
    // files that are already attached to the post.
    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      const alreadyAttached = Array.from(this.mediaAttachmentsTarget.files).some((attachedFile) => {
        return attachedFile.name === file.name && attachedFile.size === file.size && attachedFile.type === file.type && attachedFile.lastModified === file.lastModified;
      });

      if (!alreadyAttached) {
        dataTransfer.items.add(file);
      }
    }

    if (dataTransfer.files.length > this.fileLimitValue) {
      alert(`This post can only have ${this.fileLimitValue} files.`);
      return;
    }

    this.mediaAttachmentsTarget.files = dataTransfer.files;

    console.log(this.mediaAttachmentsTarget.files);
  }

  parseContent(rawContent) {
    // First, update the hidden content field and trim the result.
    this.contentTarget.value = rawContent.trim();

    // Then, start counting characters, starting with parsing out the domain
    // fragment from any mentions; for mentions like @davidcelis@xoxo.zone,
    // the "@xoxo.zone" is not counted against the limit.
    //
    // TODO: Once we can use the positive lookbehind regex, we can just do this:
    // content = rawContent.replaceAll(this.constructor.mentionRegex, '$1');
    let content = rawContent.replaceAll(this.constructor.mentionRegex, (match) => {
      return match.replace(/(?:(@[a-z0-9_]+)((?:@[\w.-]+\w+)?))/i, '$1');
    });

    // Then, parse any URLs in the content and replace them with a placeholder
    // so that each one properly registers as 23 characters.
    //
    // TODO: Once we can use the positive lookbehind regex, we can just do this:
    // content = rawContent.replaceAll(this.constructor.urlRegex, '$1');
    content = content.replaceAll(this.constructor.urlRegex, (match) => {
      return match.replace(/https?:\/\/[\S]+\.[\S]{2,}/i, this.constructor.urlPlaceholder);
    });

    const remaining = this.characterLimitValue - content.length;

    this.characterCounterTarget.innerHTML = remaining;

    if (remaining < 0) {
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
  };
}
