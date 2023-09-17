import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['button', 'item', 'focus']

  toggle() {
    this.itemTargets.forEach(item => {
      item.classList.toggle('hidden')
    })

    if (this.hasButtonTarget) {
      const expanded = this.buttonTarget.getAttribute('aria-expanded') === 'true'
      this.buttonTarget.setAttribute('aria-expanded', !expanded)
    }
  }

  show() {
    this.itemTargets.forEach(item => {
      item.classList.remove('hidden')
    })

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute('aria-expanded', true)
    }

    if (this.hasFocusTarget) {
      this.focusTarget.focus()
    }
  }

  hide() {
    this.itemTargets.forEach(item => {
      item.classList.add('hidden')
    })

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute('aria-expanded', false)
    }
  }
}
