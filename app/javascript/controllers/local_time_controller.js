import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['time']

  timeTargetConnected(element) {
    const date = new Date(element.dateTime)
    const now = new Date()
    const showFullTimestamp = (element.dataset.localTimeFull === "true");

    let options = { month: 'short', day: 'numeric' }
    if (date.getFullYear() !== now.getFullYear() || showFullTimestamp) {
      options.year = 'numeric'
    }

    let dateText = date.toLocaleDateString('en-us', options)

    let timeText = date.toLocaleTimeString('en-us', { timeZoneName: 'short' }).replace(/([\d]+:[\d]{2})(:[\d]{2})(.*)/, "$1$3")
    if (options.year !== 'numeric') {
      dateText += `, ${date.getFullYear()}`
    }

    element.title = `${timeText} • ${dateText}`

    // We'll only modify the element's inner text if the timestamp occurred
    // more than 24 hours ago. Anything sooner is in a relative format.
    if (date.getTime() < (now - 86400000) || showFullTimestamp) {
      if (showFullTimestamp) {
        // I stole this from a code golfing exercise 😬 It uses unicode hackery to
        // generate a clock emoji from a date object.
        let d = ~~(date.getHours() % 12 * 2 + date.getMinutes() / 30 + .5);
        d += d < 2 ? 24 : 0;
        const emoji = String.fromCharCode(55357, 56655 +( d % 2 ? 23 + d : d) / 2);

        dateText = `${emoji} ${dateText} at ${timeText}`
      }

      element.innerText = dateText
    }
  }
}
