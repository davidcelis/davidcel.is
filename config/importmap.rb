# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "lightgallery", to: "https://cdn.jsdelivr.net/npm/lightgallery@2.7.1/lightgallery.es5.js"
pin "lg-video", to: "https://cdn.jsdelivr.net/npm/lightgallery@2.7.1/plugins/video/lg-video.es5.js"
pin "stimulus-lightbox", to: "https://cdn.jsdelivr.net/npm/stimulus-lightbox@3.2.0/dist/stimulus-lightbox.mjs"
pin "@popperjs/core", to: "https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.6/dist/umd/popper.min.js"
pin "tippy.js", to: "https://cdn.jsdelivr.net/npm/tippy.js@6.3.7/dist/tippy.umd.min.js"

pin "ink-mde", to: "https://cdn.jsdelivr.net/npm/ink-mde@0.18.1/+esm"
pin "remark", to: "https://cdn.jsdelivr.net/npm/remark@14.0.2/+esm"
pin "remark-gfm", to: "https://cdn.jsdelivr.net/npm/remark-gfm@3.0.1/+esm"
pin "@davidcelis/remark-smartypants", to: "https://cdn.jsdelivr.net/npm/@davidcelis/remark-smartypants@2.1.0/+esm"
