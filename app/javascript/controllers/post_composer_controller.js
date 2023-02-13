import { Controller } from '@hotwired/stimulus'
import { defineOptions, ink } from 'ink-mde'

export default class extends Controller {
  static targets = [
    // Post fields
    'title',
    'content',
    'type',
    'mediaAttachments',

    // Utility targets
    'editor',
    'mediaPreviewZone',
    'mediaPreview',
    'characterCounter',
    'dummyFileField'
  ];

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
      placeholder: "What’s happening?",
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
    this.mediaPreviewZoneTarget.innerHTML = '';

    // If we have any files, unhide the media preview zone and render image or
    // video previews for each file.
    for (let i = 0; i < this.mediaAttachmentsTarget.files.length; i++) {
      const file = this.mediaAttachmentsTarget.files[i];
      const previewElement = this.createPreviewElementFor(file);

      this.mediaPreviewZoneTarget.appendChild(previewElement);
    }
  }

  createPreviewElementFor(file) {
    const previewElement = document.createElement('div');
    previewElement.classList.add('relative', 'w-32', 'h-32', 'mb-2');
    previewElement.dataset.postComposerTarget = 'mediaPreview';
    previewElement.dataset.controller = 'tooltip';

    let mediaPreview;
    if (file.type.startsWith('image/')) {
      mediaPreview = document.createElement('img');
    } else if (file.type.startsWith('video/')) {
      mediaPreview = document.createElement('video');
    }

    mediaPreview.src = URL.createObjectURL(file);
    mediaPreview.classList.add('object-cover', 'rounded', 'h-full', 'w-full', 'shadow-md');
    previewElement.appendChild(mediaPreview);

    // Add a button that'll toggle a small, tooltip-enabled form for alt text
    const altTextButton = document.createElement('button');
    altTextButton.classList.add('absolute', 'bottom-1', 'left-1', 'px-1', 'font-bold', 'font-ui-sans', 'rounded-[.25rem]', 'bg-black', 'bg-opacity-[.65]', 'hover:bg-black', 'text-white', 'select-none');
    altTextButton.innerHTML = '+ALT'
    altTextButton.dataset.action = 'click->tooltip#ignore:prevent'
    altTextButton.dataset.tooltipTarget = 'trigger';
    previewElement.appendChild(altTextButton);

    // First, add a hidden input that will sync with the form's alt text field.
    // This is necessary because the form is in a tooltip, which is appended to
    // the document body, so it's not a child of the form.
    const altTextHiddenInput = document.createElement('input');
    altTextHiddenInput.type = 'hidden';
    altTextHiddenInput.name = 'post[media_attachment_descriptions][]';
    altTextHiddenInput.value = '';
    previewElement.appendChild(altTextHiddenInput);

    // Then, start building the tooltip form by creating a wrapper div
    const altTextForm = document.createElement('div');
    altTextForm.classList.add('hidden', 'flex', 'flex-col', 'gap-4', 'p-4', 'max-w-prose')
    altTextForm.dataset.tooltipTarget = 'content';

    // Add a header with a dismiss button
    const altTextFormHeader = document.createElement('div');
    altTextFormHeader.classList.add('flex', 'justify-between');
    const altTextFormH2 = document.createElement('h2');
    altTextFormH2.classList.add('text-xl', 'font-bolt', 'text-slate-900');
    altTextFormH2.innerHTML = 'Description';
    const altTextFormDismissButton = document.createElement('button');
    altTextFormDismissButton.classList.add('text-sm', 'py-0', 'px-2', 'rounded-sm', 'transition', 'active:transition-none', 'bg-slate-100', 'font-medium', 'hover:bg-pink-100', 'active:bg-slate-100', 'active:text-pink-900/60', 'link-primary');
    altTextFormDismissButton.dataset.action = 'click->tooltip#ignore:prevent';
    altTextFormDismissButton.innerHTML = 'Close';

    // Add a text input for the alt text
    const altTextInput = document.createElement('textarea');
    altTextInput.classList.add('border', 'border-slate-200', 'rounded', 'p-2', 'text-slate-900', 'focus:outline-none', 'focus:ring-2', 'focus:ring-pink-500', 'focus:border-transparent', 'placeholder:italic', 'h-32', 'w-64', 'sm:w-96', 'md:w-120');
    altTextInput.placeholder = 'Describe the image';

    // Set up an event listener that will sync the alt text input's value with
    // the hidden input's value.
    altTextInput.addEventListener('input', (event) => {
      altTextHiddenInput.value = event.target.value;
    });

    altTextFormHeader.appendChild(altTextFormH2);
    altTextFormHeader.appendChild(altTextFormDismissButton);
    altTextForm.appendChild(altTextFormHeader);
    altTextForm.appendChild(altTextInput);
    previewElement.appendChild(altTextForm);

    const removeButton = document.createElement('button');
    removeButton.classList.add('absolute', 'top-1', 'right-1', 'p-1', 'rounded-full', 'bg-black', 'bg-opacity-[.65]', 'hover:bg-black');
    removeButton.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 fill-white" viewBox="0 0 320 512"><path d="M310.6 150.6c12.5-12.5 12.5-32.8 0-45.3s-32.8-12.5-45.3 0L160 210.7 54.6 105.4c-12.5-12.5-32.8-12.5-45.3 0s-12.5 32.8 0 45.3L114.7 256 9.4 361.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0L160 301.3 265.4 406.6c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3L205.3 256 310.6 150.6z"/></svg>'
    removeButton.dataset.action = 'click->post-composer#removeMediaAttachment:prevent';
    removeButton.dataset.postComposerFilenameParam = file.name;
    removeButton.dataset.postComposerFilesizeParam = file.size;
    removeButton.dataset.postComposerFiletypeParam = file.type;
    removeButton.dataset.postComposerFileLastModifiedParam = file.lastModified;
    previewElement.appendChild(removeButton);

    return previewElement;
  };

  removeMediaAttachment(event) {
    const dataTransfer = new DataTransfer();

    for (let i = 0; i < this.mediaAttachmentsTarget.files.length; i++) {
      const file = this.mediaAttachmentsTarget.files[i];

      if (file.name !== event.params.filename || file.size !== event.params.filesize || file.type !== event.params.filetype || file.lastModified !== event.params.fileLastModified) {
        dataTransfer.items.add(file);
      }
    }

    this.mediaAttachmentsTarget.files = dataTransfer.files;

    const previewElement = event.target.closest('[data-post-composer-target="mediaPreview"]');
    previewElement.remove();
  };

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
