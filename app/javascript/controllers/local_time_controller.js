import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['time', 'emoji']
  static values = {
    full: { type: Boolean, default: false }
  }

  connect() {
    const date = new Date(this.timeTarget.dateTime);
    const now = new Date();

    let options = { month: 'short', day: 'numeric' };
    if (date.getFullYear() !== now.getFullYear() || this.fullValue) {
      options.year = 'numeric';
    }

    let dateText = date.toLocaleDateString('en-us', options);
    let timeText = date.toLocaleTimeString('en-us', { timeZoneName: 'short' }).replace(/([\d]+:[\d]{2})(:[\d]{2})(.*)/, "$1$3");

    let titleTime = timeText;
    let titleDate = dateText;
    if (options.year !== 'numeric') {
      titleDate = `${titleDate}, ${date.getFullYear()}`;
    }

    this.timeTarget.title = `${titleTime} • ${titleDate}`;

    // We'll only modify the element's inner text if the timestamp occurred
    // more than 24 hours ago. Anything sooner is in a relative format.
    if (date.getTime() < (now - 86400000) || this.fullValue) {
      if (this.fullValue) {
        dateText = `${dateText} at ${timeText}`;
      }

      this.timeTarget.innerText = dateText;
    }

    // We'll also change the emoji (if there is one) to match the time of day.
    // I stole this from a code golfing exercise 😬 It uses unicode hackery to
    // generate a clock emoji from a date object.
    if (this.hasEmojiTarget) {
      let d = ~~(date.getHours() % 12 * 2 + date.getMinutes() / 30 + .5);
      d += d < 2 ? 24 : 0;
      const emoji = String.fromCharCode(55357, 56655 +( d % 2 ? 23 + d : d) / 2);

      this.emojiTarget.innerText = `${emoji} `
    }
  }
}
