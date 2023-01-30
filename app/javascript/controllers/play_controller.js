import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['button', 'item']

  play() {
    this.buttonTarget.classList.add('hidden');

    this.itemTarget.play();
  }

  pause() {
    if (this.itemTarget.paused) {
      return;
    }

    this.itemTarget.pause();

    this.buttonTarget.classList.remove('hidden');
  }

  playOrPause(event) {
    event.stopPropagation();

    if (this.itemTarget.paused) {
      this.play();
    } else {
      this.pause();
    }
  }
}
