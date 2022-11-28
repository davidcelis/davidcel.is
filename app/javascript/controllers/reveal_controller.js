import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['button', 'item']

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
