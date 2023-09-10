import TooltipController from "controllers/tooltip_controller"

export default class extends TooltipController {
  static targets = ['trigger', 'hide']

  static values = {
    appendTo: { type: String },
    content: { type: String },
    flip: { type: Boolean, default: true },
  }

  static template = `
    <div class="flex flex-col gap-4 p-4 max-w-prose" data-tooltip-target="content">
      <div class="flex justify-between">
        <h2 class="text-xl font-bold text-slate-900">Description</h2>

        <button class="text-sm py-0 px-2 ml-2 rounded-sm transition active:transition-none bg-slate-100 font-medium hover:bg-pink-100 active:bg-slate-100 active:text-pink-900/60 link-primary" data-action="click->tooltip#ignore:prevent" data-tooltip-target="hide">Dismiss</button>
      </div>
    </div>
  `

  static paragraphTemplate = `
    <p class="whitespace-pre-wrap text-base text-slate-700"></p>
  `

  connect() {
    const template = document.createElement('template');
    template.innerHTML = this.constructor.template;

    const paragraphs = this.contentValue.split(/(?:\r\n|\r|\n){2}/);
    paragraphs.forEach((paragraph) => {
      const paragraphTemplate = document.createElement('template');
      paragraphTemplate.innerHTML = this.constructor.paragraphTemplate;
      paragraphTemplate.content.querySelector('p').innerHTML = paragraph;

      template.content.querySelector('[data-tooltip-target="content"]').appendChild(paragraphTemplate.content);
    });

    template.content.querySelector('[data-tooltip-target="hide"]').addEventListener('click', () => {
      this.triggerTarget._tippy.hide();
    });

    this.show(template.content);
  }

  ignore(event) {
    event.stopPropagation();
  }

  hide() {
    this.triggerTarget._tippy.hide();
  }
}
