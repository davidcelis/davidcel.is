import Lightbox from '@stimulus-components/lightbox'
import lightGallery from 'lightgallery'
import lgVideo from 'lg-video'

export default class extends Lightbox {
  connect() {
    const plugins = []
    if (this.optionsValue.video === true) {
      plugins.push(lgVideo)
    }

    this.lightGallery = lightGallery(this.element, {
      plugins: plugins,
      ...this.defaultOptions,
      ...this.optionsValue
    })
  }

  // You can set default options in this getter.
  get defaultOptions() {
    return {
      licenseKey: '4444-4444-4444-4444',
      selector: 'a',
      download: false,
      getCaptionFromTitleOrAlt: false,
      hideControlOnEnd: true,
      gotoNextSlideOnVideoEnd: false,
      loop: false,
    }
  }
}
