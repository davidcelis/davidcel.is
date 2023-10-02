import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['button', 'item', 'focus']


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

    // Prevent scrolling outside of the modal
    document.body.classList.add('overflow-y-hidden')
    document.body.classList.add('scrolling-touch')
  }

  hide() {
    this.itemTargets.forEach(item => {
      item.classList.add('hidden')
    })

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute('aria-expanded', false)
    }

    // Allow scrolling outside of the modal
    document.body.classList.remove('overflow-y-hidden')
    document.body.classList.remove('scrolling-touch')
  }
}
