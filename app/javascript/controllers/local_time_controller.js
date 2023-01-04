import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['time']

  timeTargetConnected(element) {
    let date = new Date(element.dateTime)
    let now = new Date()

    let options = { month: 'short', day: 'numeric' }
    if (date.getFullYear() !== now.getFullYear()) {
      options.year = 'numeric'
    }

    let dateText = date.toLocaleDateString('en-us', options)

    // We'll only modify the element's inner text if the timestamp occurred
    // more than 24 hours ago. Anything sooner is already in a relative format.
    if (date.getTime() < (now - 86400000)) {
      element.innerText = dateText
    }

    let timeText = date.toLocaleTimeString('en-us', { timeZoneName: 'short' }).replace(/([\d]+:[\d]{2})(:[\d]{2})(.*)/, "$1$3")
    if (options.year !== 'numeric') {
      dateText += `, ${date.getFullYear()}`
    }

    element.title = `${timeText} • ${dateText}`
  }
}
