# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "stimulus-lightbox", to: "https://cdn.jsdelivr.net/npm/stimulus-lightbox@3.2.0/dist/stimulus-lightbox.mjs"
pin "lightgallery", to: "https://cdn.jsdelivr.net/npm/lightgallery@2.7.1/lightgallery.es5.js"
pin "lg-video", to: "https://cdn.jsdelivr.net/npm/lightgallery@2.7.1/plugins/video/lg-video.es5.js"
