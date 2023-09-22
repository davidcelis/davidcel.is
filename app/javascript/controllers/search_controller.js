import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

export default class extends Controller {
  static targets = ['query', 'clear']
  static values = { url: String }

  submit() {
    this.search(this.queryTarget.value)
  }

  clear() {
    this.search('');
  }

  search(query) {
    const url = new URL(this.urlValue || window.location.href);

    url.searchParams.delete('page');

    if (query.length == 0) {
      url.searchParams.delete('q');
    } else {
      url.searchParams.set('q', query);
    }

    const newUrl = url.toString();

    if (newUrl != window.location.href) {
      Turbo.visit(newUrl);
    } else {
      this.queryTarget.value = query;
      this.clearTarget.classList.toggle('hidden', this.queryTarget.value.length == 0);
    }
  }

  toggleClear() {
    const url = new URL(window.location.href);

    this.clearTarget.classList.toggle('hidden', this.queryTarget.value.length == 0);
  }
}
