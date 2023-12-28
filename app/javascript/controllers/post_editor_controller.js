import { Controller } from '@hotwired/stimulus'
import { DirectUpload } from '@rails/activestorage'
import { defineOptions, wrap } from 'ink-mde'

export default class extends Controller {
  static targets = [
    // Post fields
    'type',
    'title',
    'content',

    // Utility targets
    'form',
    'editor',
    'mediaPreviewZone',
    'mediaPreview',
    'characterCounter',
    'dummyFileField'
  ];

  static values = {
    characterWarning: { type: Number, default: 300 },
    characterLimit: { type: Number, default: 500 },
    fileLimit: { type: Number, default: 4 },
    directUploadUrl: String,
  };

  // TODO: Once Safari supports positive look-behinds, we can use these instead:
  // static mentionRegex = /(?<=^|[^\/\w])(?:(@[a-z0-9_]+)((?:@[\w.-]+\w+)?))/gi;
  // static urlRegex = /(?<=^|[^\/\w])https?:\/\/[\S]+\.[\S]{2,}/gi;
  static mentionRegex = /(?:^|[^\/\S])(?:(@[a-z0-9_]+)((?:@[\w.-]+\w+)?))/gi;
  static urlRegex = /(?:^|[^\/\S])https?:\/\/[\S]+\.[\S]{2,}/gi;
  static urlPlaceholder = 'xxxxxxxxxxxxxxxxxxxxxxx';

  connect() {
    // Initialize the editor
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

    wrap(this.editorTarget, options);

    this.parseContent(this.editorTarget.value);
  };

  selectFiles() {
    this.dummyFileFieldTarget.click();
  }

  dummyFileFieldChanged() {
    this.addMediaAttachments(this.dummyFileFieldTarget.files)

    this.dummyFileFieldTarget.value = null;
  }

  addMediaAttachments(files) {
    if (this.mediaPreviewTargets.length + files.length > this.fileLimitValue) {
      alert(`You can only attach ${this.fileLimitValue} images or videos to this post.`);
      return;
    }

    Array.from(files).forEach(file => this.uploadMediaAttachment(file))
  };

  uploadMediaAttachment(file) {
    // Make sure we haven't already uploaded this file
    if (this.mediaPreviewTargets.some(preview => {
      return preview.dataset.fileName === file.name &&
        preview.dataset.fileType === file.type &&
        preview.dataset.fileSize === String(file.size) &&
        preview.dataset.fileLastModified === String(file.lastModified);
    })) {
      return;
    }

    const imageUrl = URL.createObjectURL(file);

    const previewElement = document.createElement('div');
    previewElement.classList.add('relative', 'w-32', 'h-32', 'mb-2');
    previewElement.dataset.postEditorTarget = 'mediaPreview';
    previewElement.dataset.controller = 'reveal';

    // Add the file's metadata to the preview element so we can prevent duplicates
    previewElement.dataset.fileName = file.name;
    previewElement.dataset.fileSize = file.size;
    previewElement.dataset.fileType = file.type;
    previewElement.dataset.fileLastModified = file.lastModified;

    // Set up the preview element's content, starting with the media itself.
    let mediaPreview;
    if (file.type.startsWith('image/')) {
      mediaPreview = document.createElement('img');
    } else if (file.type.startsWith('video/')) {
      mediaPreview = document.createElement('video');
    }

    mediaPreview.src = imageUrl;
    mediaPreview.classList.add('object-cover', 'rounded', 'height-full', 'w-full', 'shadow-md');
    previewElement.appendChild(mediaPreview);

    // For editing posts, we'll likely have existing media attachments that are
    // in the form and have an `id` instead of a `signed_id`. To keep each item
    // consistent so that the nested attributes work, we'll add a hidden input
    // with the `id` that's just a placeholder for the `signed_id`.
    const idHiddenInput = document.createElement('input');
    idHiddenInput.type = 'hidden';
    idHiddenInput.name = 'post[media_attachments][][id]';
    previewElement.appendChild(idHiddenInput);

    // Add a hidden input to store the file's ID once it's uploaded.
    const signedIdHiddenInput = document.createElement('input');
    signedIdHiddenInput.type = 'hidden';
    signedIdHiddenInput.name = 'post[media_attachments][][signed_id]';
    previewElement.appendChild(signedIdHiddenInput);

    // Add a button that'll toggle a small modal with a form for alt text.
    // This will be hidden at first, and then shown when the upload completes.
    const altTextButton = document.createElement('button');
    altTextButton.classList.add('hidden', 'absolute', 'bottom-1', 'left-1', 'px-1', 'font-bold', 'font-ui-sans', 'rounded-[.25rem]', 'bg-black', 'bg-opacity-[.65]', 'hover:bg-black', 'text-white', 'select-none');
    altTextButton.innerHTML = '+ALT'
    altTextButton.dataset.action = 'click->reveal#show:prevent'
    altTextButton.dataset.revealTarget = 'button';
    previewElement.appendChild(altTextButton);

    // Then, start building the modal itself by creating a wrapper div.
    const altTextModal = document.createElement('div');
    altTextModal.classList.add('hidden');
    altTextModal.dataset.revealTarget = 'item';

    // Add a background blur that'll dismiss the modal when clicked.
    const altTextFormBackgroundBlur = document.createElement('div');
    altTextFormBackgroundBlur.classList.add('fixed', 'inset-0', 'z-[25]', 'height-screen', 'w-screen', 'bg-slate-800/40', 'backdrop-blur-sm', 'opacity-100');
    altTextFormBackgroundBlur.dataset.action = 'click->reveal#hide:prevent';
    altTextModal.appendChild(altTextFormBackgroundBlur);

    // Then, start building the form itself.
    const altTextForm = document.createElement('div');
    altTextForm.classList.add('fixed', 'top-8', 'max-h-[92vh]', 'inset-x-4', 'mx-auto', 'z-[50]', 'origin-top', 'flex', 'flex-col', 'gap-4', 'p-4', 'rounded-md', 'max-w-prose', 'bg-white', 'opacity-100', 'scale-100', 'overflow-y-auto');
    altTextForm.dataset.revealTarget = 'item';

    // Add a header with a dismiss button...
    const altTextFormHeader = document.createElement('div');
    altTextFormHeader.classList.add('flex', 'justify-between');
    const altTextFormH2 = document.createElement('h2');
    altTextFormH2.classList.add('text-xl', 'font-bolt', 'text-slate-900');
    altTextFormH2.innerHTML = 'Description';
    const altTextFormDismissButton = document.createElement('button');
    altTextFormDismissButton.classList.add('text-sm', 'py-0', 'px-2', 'rounded-sm', 'transition', 'active:transition-none', 'bg-slate-100', 'font-medium', 'hover:bg-pink-100', 'active:bg-slate-100', 'active:text-pink-900/60', 'link-primary');
    altTextFormDismissButton.dataset.action = 'click->reveal#hide:prevent';
    altTextFormDismissButton.innerHTML = 'Close';

    // ... render the image so we can see what we're describing...
    const altTextFormImagePreview = document.createElement('img');
    altTextFormImagePreview.classList.add('object-cover', 'rounded', 'w-full', 'shadow-md');
    altTextFormImagePreview.src = imageUrl;

    // ... and a text input for the alt text...
    const altTextInput = document.createElement('textarea');
    altTextInput.classList.add('border', 'border-slate-200', 'rounded', 'p-2', 'text-slate-900', 'focus:outline-none', 'focus:ring-2', 'focus:ring-pink-500', 'focus:border-transparent', 'placeholder:italic', 'min-h-[100px]', 'resize-none');
    altTextInput.placeholder = 'Describe the image';
    altTextInput.name = 'post[media_attachments][][description]';
    altTextInput.dataset.revealTarget = 'focus';

    // ... and finally, assemble the form.
    altTextFormHeader.appendChild(altTextFormH2);
    altTextFormHeader.appendChild(altTextFormDismissButton);
    altTextForm.appendChild(altTextFormHeader);
    altTextForm.appendChild(altTextFormImagePreview);
    altTextForm.appendChild(altTextInput);
    altTextModal.appendChild(altTextForm);
    previewElement.appendChild(altTextModal);

    // Add a button to remove the media attachment from the post. Like the alt
    // text button, this will start hidden and be shown when the upload's done.
    const removeButton = document.createElement('button');
    removeButton.classList.add('hidden', 'absolute', 'top-1', 'right-1', 'p-1', 'rounded-full', 'bg-black', 'bg-opacity-[.65]', 'hover:bg-black');
    removeButton.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 fill-white" viewBox="0 0 320 512"><path d="M310.6 150.6c12.5-12.5 12.5-32.8 0-45.3s-32.8-12.5-45.3 0L160 210.7 54.6 105.4c-12.5-12.5-32.8-12.5-45.3 0s-12.5 32.8 0 45.3L114.7 256 9.4 361.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0L160 301.3 265.4 406.6c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3L205.3 256 310.6 150.6z"/></svg>'
    removeButton.dataset.action = 'click->post-editor#removeMediaAttachment:prevent';
    previewElement.appendChild(removeButton);

    // Add a progress bar to show the upload's progress.
    const progressBar = document.createElement('div');
    progressBar.classList.add('absolute', 'top-0', 'left-0', 'w-full', 'h-1', 'bg-slate-200', 'bg-opacity-[.65]');
    progressBar.innerHTML = `
      <div class="bg-pink-500 h-1" style="width: 0%"></div>
    `;
    previewElement.appendChild(progressBar);

    // Create an "Uploader" object that can bind to the upload's progress
    // events and update the progress bar.
    const uploader = {
      directUploadWillStoreFileWithXHR: (request) => {
        request.upload.addEventListener('progress', (event) => {
          const progress = event.loaded / event.total * 100;
          progressBar.firstElementChild.style.width = `${progress}%`;
        });
      }
    }

    // Finally, append the preview element to the DOM and start the upload.
    this.mediaPreviewZoneTarget.appendChild(previewElement);
    const upload = new DirectUpload(file, this.directUploadUrlValue, uploader);
    upload.create((error, blob) => {
      if (error) {
        console.error(error);
        previewElement.remove();
      } else {
        // When the upload is done, get rid of the progress bar and show the
        // buttons to add alt text or remove the media attachment from the post
        progressBar.remove();
        altTextButton.classList.remove('hidden');
        removeButton.classList.remove('hidden');

        // Then, set the hidden input's value to the blob's signed ID.
        signedIdHiddenInput.value = blob.signed_id;
      }
    });
  };

  removeMediaAttachment(event) {
    const previewElement = event.target.closest('[data-post-editor-target="mediaPreview"]');
    previewElement.remove();
  };

  parseContent(rawContent) {
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

    var remaining = this.characterLimitValue - content.length;
    if (this.typeTarget.value === 'Link') {
      // Accommodate the fact that, when syndicating, the link will be added to
      // the end of the post after two line breaks and shortened to 23 characters
      remaining -= 25;
    }

    this.characterCounterTarget.innerHTML = remaining;

    if (remaining < 0) {
      this.characterCounterTarget.classList.remove('text-slate-500');
      this.characterCounterTarget.classList.remove('text-amber-500');
      this.characterCounterTarget.classList.add('text-pink-500');
    } else if (content.length > this.characterWarningValue) {
      this.characterCounterTarget.classList.remove('text-pink-500');
      this.characterCounterTarget.classList.remove('text-slate-500');
      this.characterCounterTarget.classList.add('text-amber-500');
    } else {
      this.characterCounterTarget.classList.remove('text-pink-500');
      this.characterCounterTarget.classList.remove('text-amber-500');
      this.characterCounterTarget.classList.add('text-slate-500');
    }
  };
}
