# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "@rails/activestorage", to: "activestorage.esm.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "lightgallery", to: "https://cdn.jsdelivr.net/npm/lightgallery@2.7.2/lightgallery.es5.js"
pin "lg-video", to: "https://cdn.jsdelivr.net/npm/lightgallery@2.7.2/plugins/video/lg-video.es5.js"
pin "stimulus-use", to: "https://cdn.jsdelivr.net/npm/stimulus-use@0.52.2/dist/index.min.js"
pin "@stimulus-components/lightbox", to: "https://cdn.jsdelivr.net/npm/@stimulus-components/lightbox@4.0.0/dist/stimulus-lightbox.mjs"
pin "@stimulus-components/notification", to: "https://cdn.jsdelivr.net/npm/@stimulus-components/notification@3.0.0/dist/stimulus-notification.mjs"
pin "@popperjs/core", to: "https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/dist/umd/popper.min.js"
pin "tippy.js", to: "https://cdn.jsdelivr.net/npm/tippy.js@6.3.7/dist/tippy.umd.min.js"
pin "ink-mde", to: "https://esm.sh/ink-mde@0.33.0?bundle"
