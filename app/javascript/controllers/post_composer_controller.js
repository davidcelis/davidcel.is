import { Controller } from '@hotwired/stimulus'
import { DirectUpload } from '@rails/activestorage'
import { defineOptions, ink } from 'ink-mde'

export default class extends Controller {
  static targets = [
    // Post fields
    'title',
    'content',
    'type',
    'latitude',
    'longitude',

    // Check-in fields
    'placeName',
    'placeCategory',
    'placeStreet',
    'placeCity',
    'placeState',
    'placeStateCode',
    'placePostalCode',
    'placeCountry',
    'placeCountryCode',
    'placeLatitude',
    'placeLongitude',
    'placeAppleMapsId',
    'placeAppleMapsUrl',

    // Utility targets
    'form',
    'editor',
    'linkData',
    'linkInput',
    'linkPreview',
    'linkIcon',
    'locationSearchInput',
    'locationResults',
    'locationIcon',
    'mediaPreviewZone',
    'mediaPreview',
    'characterCounter',
    'dummyFileField',

    // Debug info
    'debugIcon',
    'debugError',
    'debugPlaceName',
    'debugPlaceCategory',
    'debugPlaceStreet',
    'debugPlaceCity',
    'debugPlaceState',
    'debugPlacePostalCode',
    'debugPlaceCountry',
    'debugLatitude',
    'debugLongitude'
  ];

  static values = {
    characterWarning: { type: Number, default: 300 },
    characterLimit: { type: Number, default: 500 },
    fileLimit: { type: Number, default: 4 },
    directUploadUrl: String,

    iframelyKey: String,
    linkData: Object,

    initialMapKitToken: String,

    // Lifecycle-related values
    prepopulatedNearbyLocations: { type: Boolean, default: false },
    watchPositionId: Number,
    previousLatitude: Number,
    previousLongitude: Number
  };

  // TODO: Once Safari supports positive look-behinds, we can use these instead:
  // static mentionRegex = /(?<=^|[^\/\w])(?:(@[a-z0-9_]+)((?:@[\w.-]+\w+)?))/gi;
  // static urlRegex = /(?<=^|[^\/\w])https?:\/\/[\S]+\.[\S]{2,}/gi;
  static mentionRegex = /(?:^|[^\/\S])(?:(@[a-z0-9_]+)((?:@[\w.-]+\w+)?))/gi;
  static urlRegex = /(?:^|[^\/\S])https?:\/\/[\S]+\.[\S]{2,}/gi;
  static urlPlaceholder = 'xxxxxxxxxxxxxxxxxxxxxxx';

  connect () {
    // Load MapKit JS
    if (this.initialMapKitTokenValue && !window.mapkit) {
      window.initMapKit = () => {
        window.mapkit.init({
          authorizationCallback: (done) => {
            fetch('/mapkit/token')
              .then(response => response.text())
              .then(done)
              .catch(console.error);
          }
        });
      }

      const script = document.createElement('script');
      script.src = `https://cdn.apple-mapkit.com/mk/5.x.x/mapkit.js`;
      script.async = true;
      script.crossOrigin = 'anonymous';
      script.dataset.callback = 'initMapKit';
      script.dataset.initialToken = this.initialMapKitTokenValue;
      script.dataset.libraries = 'map,services,user-location';
      document.head.appendChild(script);
    }

    this.watchPosition();

    // Initialize the editor
    const options = defineOptions({
      placeholder: "What’s happening?",
      interface: {
        appearance: 'light',
        attribution: false,
      },
      hooks: {
        afterUpdate: (content) => {
          this.parseContent(content);
        }
      },
      files: {
        clipboard: true,
        dragAndDrop: true,
        injectMarkup: false,
        types: ['image/*', 'video/*'],
        handler: (files) => {
          this.addMediaAttachments(files);
        },
      },
    });

    ink(this.editorTarget, options);
  };

  disconnect() {
    window.navigator.geolocation.clearWatch(this.watchPositionIdValue);
  }

  logError(error) {
    this.debugIconTarget.classList.remove('fill-slate-400', 'group-hover:fill-slate-600');
    this.debugIconTarget.classList.add('fill-red-400', 'group-hover:fill-red-600');
    this.debugIconTarget.classList.add();
    this.debugErrorTarget.innerHTML = error.message;
  }

  clearError() {
    this.debugIconTarget.classList.remove('fill-red-400', 'group-hover:fill-red-600');
    this.debugIconTarget.classList.add('fill-slate-400', 'group-hover:fill-slate-600');
    this.debugErrorTarget.innerHTML = '';
  }

  watchPosition() {
    // Get my current location and store the coordinates in hidden fields.
    // Because this page might be open for a while, we'll do this using
    // watchPosition so that the fields stay up to date.
    this.watchPositionIdValue = window.navigator.geolocation.watchPosition((position) => {
      // If we're doing an explicit check in and have already selected a
      // location, return early so we don't overwrite anything.
      if (this.placeAppleMapsIdTarget.value) {
        return;
      }

      this.clearError();

      // Otherwise, save our coordinates and do a reverse geocode to get the
      // neighborhood, city, state, and country.
      const latitude = position.coords.latitude;
      const longitude = position.coords.longitude;

      this.latitudeTarget.value = latitude;
      this.longitudeTarget.value = longitude;
      this.prepopulatedNearbyLocationsValue = false;

      this.debugLatitudeTarget.innerHTML = position.coords.latitude;
      this.debugLongitudeTarget.innerHTML = position.coords.longitude;

      // If our coordinates haven't changed, return early.
      if (this.previousLatitudeValue === latitude && this.previousLongitudeValue === longitude) {
        return;
      } else {
        this.previousLatitudeValue = latitude;
        this.previousLongitudeValue = longitude;
      }

      const geocoder = new window.mapkit.Geocoder({});
      const coordinate = new window.mapkit.Coordinate(latitude, longitude);

      geocoder.reverseLookup(coordinate, (error, data) => {
        if (error) {
          this.logError(error)
        } else {
          // If we got a result, clear any previous errors.
          this.clearError();

          // Then, populate the hidden fields with the data we got back.
          const place = data.results[0];

          // For now we're only showing the neighborhood, city, state, and country,
          // but we'll populate pretty much everything we can just in case. However,
          // we won't populate the street address (we specifically don't want that
          // level of granularity), and Apple Maps IDs/URLs (we won't have any).
          this.placeNameTarget.value = place.subLocality || '';
          this.placeCityTarget.value = place.locality || '';
          this.placeStateTarget.value = place.administrativeArea || '';
          this.placeStateCodeTarget.value = place.administrativeAreaCode || '';
          this.placePostalCodeTarget.value = place.postCode || '';
          this.placeCountryTarget.value = place.country || '';
          this.placeCountryCodeTarget.value = place.countryCode || '';

          // Finally, make all of this visible in the debug pane.
          this.debugPlaceNameTarget.innerHTML = place.subLocality;
          this.debugPlaceCityTarget.innerHTML = place.locality;
          this.debugPlaceStateTarget.innerHTML = `${place.administrativeArea} (${place.administrativeAreaCode})`;
          this.debugPlacePostalCodeTarget.innerHTML = place.postCode;
          this.debugPlaceCountryTarget.innerHTML = `${place.country} (${place.countryCode})`;
        }
      });
    }, (error) => {
      this.logError(error)
    }, {
      enableHighAccuracy: true,
      maximumAge: 10000,
      timeout: 10000
    });
  }

  nearbyLocationSearch() {
    if (this.prepopulatedNearbyLocationsValue) {
      return;
    }

    // Search for nearby places using the most recent location data we have.
    const latitude = parseFloat(this.latitudeTarget.value);
    const longitude = parseFloat(this.longitudeTarget.value);

    const search = new window.mapkit.PointsOfInterestSearch({
      center: new window.mapkit.Coordinate(latitude, longitude),
      radius: 500,

      // Exclude certain types of places from the search results that just
      // clutter things up.
      pointOfInterestFilter: mapkit.PointOfInterestFilter.excluding([
        mapkit.PointOfInterestCategory.ATM,
        mapkit.PointOfInterestCategory.Bank,
        mapkit.PointOfInterestCategory.EVCharger,
        mapkit.PointOfInterestCategory.FireStation,
        mapkit.PointOfInterestCategory.GasStation,
        mapkit.PointOfInterestCategory.Hospital,
        mapkit.PointOfInterestCategory.Laundry,
        mapkit.PointOfInterestCategory.Parking,
        mapkit.PointOfInterestCategory.Pharmacy,
        mapkit.PointOfInterestCategory.Police,
        mapkit.PointOfInterestCategory.PostOffice,
        mapkit.PointOfInterestCategory.PublicTransport,
        mapkit.PointOfInterestCategory.Restroom,
        mapkit.PointOfInterestCategory.School,
      ])
    });

    search.search((error, data) => {
      if (error) {
        console.error(error);
      } else {
        this.prepopulatedNearbyLocationsValue = true;
        this.handleLocationSearchResults(data.places);
      }
    });
  }

  locationSearch(event) {
    // Prevent the form from submitting
    event.preventDefault();

    // Grab the query from the input value and execute a search
    const query = this.locationSearchInputTarget.value.trim();
    const search = new window.mapkit.Search({ getsUserLocation: true });

    search.search(query, (error, data) => {
      if (error) {
        console.error(error);
      } else {
        this.handleLocationSearchResults(data.places);
      }
    });
  }

  handleLocationSearchResults(places) {
    // Populate the locationResults target
    this.locationResultsTarget.innerHTML = '';

    if (places.length === 0) {
      // If there are no results, show a message
      const noResults = document.createElement('li');
      noResults.classList.add('text-center', 'text-slate-500', 'text-sm', 'py-2');
      noResults.innerHTML = 'No results found';
      this.locationResultsTarget.appendChild(noResults);
    } else {
      // Otherwise, display each result as a list item that, when clicked,
      // will populate the hidden fields with the result's data.
      places.forEach(place => {
        const placeResult = document.createElement('li');
        placeResult.classList.add('py-2', 'px-4', 'hover:bg-slate-100', 'cursor-pointer');
        placeResult.dataset.action = 'click->reveal#hide';

        const placeResultName = document.createElement('div');
        placeResultName.classList.add('font-bold', 'text-slate-700');
        placeResultName.innerHTML = '📍 ' + place.name;
        placeResult.appendChild(placeResultName);

        const placeResultAddress = document.createElement('div');
        placeResultAddress.classList.add('text-slate-500', 'text-sm');
        placeResultAddress.innerHTML = place.formattedAddress;
        placeResult.appendChild(placeResultAddress);

        placeResult.addEventListener('click', () => {
          this.placeNameTarget.value = place.name || '';
          this.placeCategoryTarget.value = place.pointOfInterestCategory || '';
          this.placeStreetTarget.value = place.fullThoroughfare || '';
          this.placeCityTarget.value = place.locality || '';
          this.placeStateTarget.value = place.administrativeArea || '';
          this.placeStateCodeTarget.value = place.administrativeAreaCode || '';
          this.placePostalCodeTarget.value = place.postCode || '';
          this.placeCountryTarget.value = place.country || '';
          this.placeCountryCodeTarget.value = place.countryCode || '';
          this.placeLatitudeTarget.value = place.coordinate.latitude || '';
          this.placeLongitudeTarget.value = place.coordinate.longitude || '';
          this.placeAppleMapsIdTarget.value = place.muid || '';
          this.placeAppleMapsUrlTarget.value = place._wpURL || '';

          this.locationIconTarget.closest('button').title = place.name;
          this.locationIconTarget.classList.remove('fill-slate-400', 'group-hover:fill-slate-600');
          this.locationIconTarget.classList.add('fill-pink-400', 'group-hover:fill-pink-600');

          this.locationSearchInputTarget.value = '';

          // Finally, make all of this visible in the debug pane.
          this.debugPlaceNameTarget.innerHTML = place.name;
          this.debugPlaceCategoryTarget.innerHTML = place.pointOfInterestCategory;
          this.debugPlaceStreetTarget.innerHTML = place.fullThoroughfare;
          this.debugPlaceCityTarget.innerHTML = place.locality;
          this.debugPlaceStateTarget.innerHTML = `${place.administrativeArea} (${place.administrativeAreaCode})`;
          this.debugPlacePostalCodeTarget.innerHTML = place.postCode;
          this.debugPlaceCountryTarget.innerHTML = `${place.country} (${place.countryCode})`;
          this.debugLatitudeTarget.innerHTML = place.coordinate.latitude;
          this.debugLongitudeTarget.innerHTML = place.coordinate.longitude;
        });

        this.locationResultsTarget.appendChild(placeResult);
      });
    }
  }

  async fetchLink(event) {
    // Prevent the form from submitting
    event.preventDefault();

    // Grab the URL from the input value and fetch the link's metadata via Iframely
    const url = this.linkInputTarget.value.trim();
    const response = await fetch(`https://iframe.ly/api/iframely?url=${encodeURIComponent(url)}&key=${this.iframelyKeyValue}`);
    const data = await response.json();

    // Keep track of the metadata so we can populate the right fields if we
    // confirm the link.
    this.linkDataValue = data;

    // Then, show Iframely's preview of the link so we can confirm it's right
    const script = document.createElement('script');
    script.async = true;
    script.src = `//cdn.iframe.ly/embed.js?key=${this.iframelyKeyValue}`;
    this.linkPreviewTarget.innerHTML = data.html;
    this.linkPreviewTarget.appendChild(script);

    // Finally, add a button that, when clicked, will confirm the link and
    // populate the right fields.
    const confirmButton = document.createElement('button');
    confirmButton.classList.add('p-2', 'mt-2', 'w-full', 'rounded-sm', 'transition', 'active:transition-none', 'bg-slate-100', 'font-medium', 'hover:bg-pink-100', 'active:bg-slate-100', 'active:text-pink-900/60', 'link-primary');
    confirmButton.innerHTML = 'Confirm';
    confirmButton.dataset.action = 'click->reveal#hide click->post-composer#confirmLink';
    this.linkPreviewTarget.appendChild(confirmButton);
  }

  confirmLink(event) {
    // Prevent the form from submitting
    event.preventDefault();

    // Store the final link URL in the hidden field, show the URL preview and
    // auto-detected title, and set the post type to "Link".
    this.linkDataTarget.value = JSON.stringify(this.linkDataValue);
    this.titleTarget.value = this.linkDataValue.meta.title;
    this.titleTarget.classList.remove('hidden');
    this.typeTarget.value = 'Link';

    this.linkIconTarget.closest('button').title = this.linkDataValue.url;
    this.linkIconTarget.classList.remove('fill-slate-400', 'group-hover:fill-slate-600');
    this.linkIconTarget.classList.add('fill-pink-400', 'group-hover:fill-pink-600');
  }

  selectFiles() {
    this.dummyFileFieldTarget.click();
  }

  dummyFileFieldChanged() {
    this.addMediaAttachments(this.dummyFileFieldTarget.files)

    this.dummyFileFieldTarget.value = null;
  }

  addMediaAttachments(files) {
    if (this.mediaPreviewTargets.length + files.length > this.fileLimitValue) {
      alert(`You can only attach ${this.fileLimitValue} images or videos to this post.`);
      return;
    }

    Array.from(files).forEach(file => this.uploadMediaAttachment(file))
  };

  uploadMediaAttachment(file) {
    // Make sure we haven't already uploaded this file
    if (this.mediaPreviewTargets.some(preview => {
      return preview.dataset.fileName === file.name &&
        preview.dataset.fileType === file.type &&
        preview.dataset.fileSize === String(file.size) &&
        preview.dataset.fileLastModified === String(file.lastModified);
    })) {
      return;
    }

    const imageUrl = URL.createObjectURL(file);

    const previewElement = document.createElement('div');
    previewElement.classList.add('relative', 'w-32', 'h-32', 'mb-2');
    previewElement.dataset.postComposerTarget = 'mediaPreview';
    previewElement.dataset.controller = 'reveal';

    // Add the file's metadata to the preview element so we can prevent duplicates
    previewElement.dataset.fileName = file.name;
    previewElement.dataset.fileSize = file.size;
    previewElement.dataset.fileType = file.type;
    previewElement.dataset.fileLastModified = file.lastModified;

    // Set up the preview element's content, starting with the media itself.
    let mediaPreview;
    if (file.type.startsWith('image/')) {
      mediaPreview = document.createElement('img');
    } else if (file.type.startsWith('video/')) {
      mediaPreview = document.createElement('video');
    }

    mediaPreview.src = imageUrl;
    mediaPreview.classList.add('object-cover', 'rounded', 'height-full', 'w-full', 'shadow-md');
    previewElement.appendChild(mediaPreview);

    // Add a hidden input to store the file's ID once it's uploaded.
    const signedIdHiddenInput = document.createElement('input');
    signedIdHiddenInput.type = 'hidden';
    signedIdHiddenInput.name = 'post[media_attachments][][signed_id]';
    previewElement.appendChild(signedIdHiddenInput);

    // Add a button that'll toggle a small modal with a form for alt text.
    // This will be hidden at first, and then shown when the upload completes.
    const altTextButton = document.createElement('button');
    altTextButton.classList.add('hidden', 'absolute', 'bottom-1', 'left-1', 'px-1', 'font-bold', 'font-ui-sans', 'rounded-[.25rem]', 'bg-black', 'bg-opacity-[.65]', 'hover:bg-black', 'text-white', 'select-none');
    altTextButton.innerHTML = '+ALT'
    altTextButton.dataset.action = 'click->reveal#show:prevent'
    altTextButton.dataset.revealTarget = 'button';
    previewElement.appendChild(altTextButton);

    // Then, start building the modal itself by creating a wrapper div.
    const altTextModal = document.createElement('div');
    altTextModal.classList.add('hidden');
    altTextModal.dataset.revealTarget = 'item';

    // Add a background blur that'll dismiss the modal when clicked.
    const altTextFormBackgroundBlur = document.createElement('div');
    altTextFormBackgroundBlur.classList.add('fixed', 'inset-0', 'z-[25]', 'height-screen', 'w-screen', 'bg-slate-800/40', 'backdrop-blur-sm', 'opacity-100');
    altTextFormBackgroundBlur.dataset.action = 'click->reveal#hide:prevent';
    altTextModal.appendChild(altTextFormBackgroundBlur);

    // Then, start building the form itself.
    const altTextForm = document.createElement('div');
    altTextForm.classList.add('fixed', 'top-8', 'max-h-[92vh]', 'inset-x-4', 'mx-auto', 'z-[50]', 'origin-top', 'flex', 'flex-col', 'gap-4', 'p-4', 'rounded-md', 'max-w-prose', 'bg-white', 'opacity-100', 'scale-100', 'overflow-y-auto');
    altTextForm.dataset.revealTarget = 'item';

    // Add a header with a dismiss button...
    const altTextFormHeader = document.createElement('div');
    altTextFormHeader.classList.add('flex', 'justify-between');
    const altTextFormH2 = document.createElement('h2');
    altTextFormH2.classList.add('text-xl', 'font-bolt', 'text-slate-900');
    altTextFormH2.innerHTML = 'Description';
    const altTextFormDismissButton = document.createElement('button');
    altTextFormDismissButton.classList.add('text-sm', 'py-0', 'px-2', 'rounded-sm', 'transition', 'active:transition-none', 'bg-slate-100', 'font-medium', 'hover:bg-pink-100', 'active:bg-slate-100', 'active:text-pink-900/60', 'link-primary');
    altTextFormDismissButton.dataset.action = 'click->reveal#hide:prevent';
    altTextFormDismissButton.innerHTML = 'Close';

    // ... render the image so we can see what we're describing...
    const altTextFormImagePreview = document.createElement('img');
    altTextFormImagePreview.classList.add('object-cover', 'rounded', 'w-full', 'shadow-md');
    altTextFormImagePreview.src = imageUrl;

    // ... and a text input for the alt text...
    const altTextInput = document.createElement('textarea');
    altTextInput.classList.add('border', 'border-slate-200', 'rounded', 'p-2', 'text-slate-900', 'focus:outline-none', 'focus:ring-2', 'focus:ring-pink-500', 'focus:border-transparent', 'placeholder:italic', 'min-h-[100px]', 'resize-none');
    altTextInput.placeholder = 'Describe the image';
    altTextInput.name = 'post[media_attachments][][description]';
    altTextInput.dataset.revealTarget = 'focus';

    // ... and finally, assemble the form.
    altTextFormHeader.appendChild(altTextFormH2);
    altTextFormHeader.appendChild(altTextFormDismissButton);
    altTextForm.appendChild(altTextFormHeader);
    altTextForm.appendChild(altTextFormImagePreview);
    altTextForm.appendChild(altTextInput);
    altTextModal.appendChild(altTextForm);
    previewElement.appendChild(altTextModal);

    // Add a button to remove the media attachment from the post. Like the alt
    // text button, this will start hidden and be shown when the upload's done.
    const removeButton = document.createElement('button');
    removeButton.classList.add('hidden', 'absolute', 'top-1', 'right-1', 'p-1', 'rounded-full', 'bg-black', 'bg-opacity-[.65]', 'hover:bg-black');
    removeButton.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 fill-white" viewBox="0 0 320 512"><path d="M310.6 150.6c12.5-12.5 12.5-32.8 0-45.3s-32.8-12.5-45.3 0L160 210.7 54.6 105.4c-12.5-12.5-32.8-12.5-45.3 0s-12.5 32.8 0 45.3L114.7 256 9.4 361.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0L160 301.3 265.4 406.6c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3L205.3 256 310.6 150.6z"/></svg>'
    removeButton.dataset.action = 'click->post-composer#removeMediaAttachment:prevent';
    previewElement.appendChild(removeButton);

    // Add a progress bar to show the upload's progress.
    const progressBar = document.createElement('div');
    progressBar.classList.add('absolute', 'top-0', 'left-0', 'w-full', 'h-1', 'bg-slate-200', 'bg-opacity-[.65]');
    progressBar.innerHTML = `
      <div class="bg-pink-500 h-1" style="width: 0%"></div>
    `;
    previewElement.appendChild(progressBar);

    // Create an "Uploader" object that can bind to the upload's progress
    // events and update the progress bar.
    const uploader = {
      directUploadWillStoreFileWithXHR: (request) => {
        request.upload.addEventListener('progress', (event) => {
          const progress = event.loaded / event.total * 100;
          progressBar.firstElementChild.style.width = `${progress}%`;
        });
      }
    }

    // Finally, append the preview element to the DOM and start the upload.
    this.mediaPreviewZoneTarget.appendChild(previewElement);
    const upload = new DirectUpload(file, this.directUploadUrlValue, uploader);
    upload.create((error, blob) => {
      if (error) {
        console.error(error);
        previewElement.remove();
      } else {
        // When the upload is done, get rid of the progress bar and show the
        // buttons to add alt text or remove the media attachment from the post
        progressBar.remove();
        altTextButton.classList.remove('hidden');
        removeButton.classList.remove('hidden');

        // Then, set the hidden input's value to the blob's signed ID.
        signedIdHiddenInput.value = blob.signed_id;
      }
    });
  };

  removeMediaAttachment(event) {
    const previewElement = event.target.closest('[data-post-composer-target="mediaPreview"]');
    previewElement.remove();
  };

  parseContent(rawContent) {
    // First, update the hidden content field and trim the result.
    this.contentTarget.value = rawContent.trim();

    // Then, start counting characters, starting with parsing out the domain
    // fragment from any mentions; for mentions like @davidcelis@xoxo.zone,
    // the "@xoxo.zone" is not counted against the limit.
    //
    // TODO: Once we can use the positive lookbehind regex, we can just do this:
    // content = rawContent.replaceAll(this.constructor.mentionRegex, '$1');
    let content = rawContent.replaceAll(this.constructor.mentionRegex, (match) => {
      return match.replace(/(?:(@[a-z0-9_]+)((?:@[\w.-]+\w+)?))/i, '$1');
    });

    // Then, parse any URLs in the content and replace them with a placeholder
    // so that each one properly registers as 23 characters.
    //
    // TODO: Once we can use the positive lookbehind regex, we can just do this:
    // content = rawContent.replaceAll(this.constructor.urlRegex, '$1');
    content = content.replaceAll(this.constructor.urlRegex, (match) => {
      return match.replace(/https?:\/\/[\S]+\.[\S]{2,}/i, this.constructor.urlPlaceholder);
    });

    var remaining = this.characterLimitValue - content.length;
    if (this.typeTarget.value === 'Link') {
      // Accommodate the fact that, when syndicating, the link will be added to
      // the end of the post after two line breaks and shortened to 23 characters
      remaining -= 25;
    }

    this.characterCounterTarget.innerHTML = remaining;

    if (remaining < 0) {
      this.titleTarget.classList.remove('hidden');
      this.characterCounterTarget.classList.remove('text-slate-500', 'text-amber-500');
      this.characterCounterTarget.classList.add('text-pink-500');

      if (this.typeTarget.value === 'Note') {
        this.typeTarget.value = 'Article';
      }
    } else if (content.length > this.characterWarningValue) {
      this.characterCounterTarget.classList.remove('text-pink-500', 'text-slate-500');
      this.characterCounterTarget.classList.add('text-amber-500');

      if (this.typeTarget.value === 'Article') {
        this.titleTarget.classList.add('hidden');
        this.typeTarget.value = 'Note';
      }
    } else {
      this.characterCounterTarget.classList.remove('text-pink-500', 'text-amber-500');
      this.characterCounterTarget.classList.add('text-slate-500');

      if (this.typeTarget.value === 'Article') {
        this.titleTarget.classList.add('hidden');
        this.typeTarget.value = 'Note';
      }
    }
  };
}
