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
    'editor',
    'locationSearchInput',
    'locationResults',
    'locationPreview',
    'mediaPreviewZone',
    'mediaPreview',
    'characterCounter',
    'dummyFileField'
  ];

  static values = {
    characterWarning: { type: Number, default: 300 },
    characterLimit: { type: Number, default: 500 },
    fileLimit: { type: Number, default: 4 },
    directUploadUrl: String,
    initialMapKitToken: String,

    // Lifecycle-related values
    prepopulatedNearbyLocations: { type: Boolean, default: false },
    watchPositionId: Number,
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

    // Get my current location and store the coordinates in hidden fields.
    // Because this page might be open for a while, we'll do this using
    // watchPosition so that the fields stay up to date.
    this.watchPositionIdValue = window.navigator.geolocation.watchPosition((position) => {
      this.latitudeTarget.value = position.coords.latitude;
      this.longitudeTarget.value = position.coords.longitude;
      this.prepopulatedNearbyLocationsValue = false;
    }, (error) => {
      console.error(error);
    }, {
      enableHighAccuracy: true,
      timeout: 10000
    });

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
        placeResult.dataset.action = 'click->tooltip#hide';

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

          this.locationPreviewTarget.innerText = place.name;

          this.locationSearchInputTarget.value = '';
        });

        this.locationResultsTarget.appendChild(placeResult);
      });
    }
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

    const previewElement = document.createElement('div');
    previewElement.classList.add('relative', 'w-32', 'h-32', 'mb-2');
    previewElement.dataset.postComposerTarget = 'mediaPreview';
    previewElement.dataset.controller = 'tooltip';

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

    mediaPreview.src = URL.createObjectURL(file);
    mediaPreview.classList.add('object-cover', 'rounded', 'height-full', 'w-full', 'shadow-md');
    previewElement.appendChild(mediaPreview);

    // Add a hidden input to store the file's ID once it's uploaded.
    const signedIdHiddenInput = document.createElement('input');
    signedIdHiddenInput.type = 'hidden';
    signedIdHiddenInput.name = 'post[media_attachments][][signed_id]';
    previewElement.appendChild(signedIdHiddenInput);

    // Add a button that'll toggle a small, tooltip-enabled form for alt text.
    // This will be hidden at first, and then shown when the upload completes.
    const altTextButton = document.createElement('button');
    altTextButton.classList.add('hidden', 'absolute', 'bottom-1', 'left-1', 'px-1', 'font-bold', 'font-ui-sans', 'rounded-[.25rem]', 'bg-black', 'bg-opacity-[.65]', 'hover:bg-black', 'text-white', 'select-none');
    altTextButton.innerHTML = '+ALT'
    altTextButton.dataset.action = 'click->tooltip#ignore:prevent'
    altTextButton.dataset.tooltipTarget = 'trigger';
    previewElement.appendChild(altTextButton);

    // Add a hidden input that will sync with the form's alt text field. This
    // is necessary because the form is in a tooltip, which is appended to the
    // document body, so it's not a child of the form.
    const altTextHiddenInput = document.createElement('input');
    altTextHiddenInput.type = 'hidden';
    altTextHiddenInput.name = 'post[media_attachments][][description]';
    altTextHiddenInput.value = '';
    previewElement.appendChild(altTextHiddenInput);

    // Then, start building the tooltip form by creating a wrapper div...
    const altTextForm = document.createElement('div');
    altTextForm.classList.add('hidden', 'flex', 'flex-col', 'gap-4', 'p-4', 'max-w-prose')
    altTextForm.dataset.tooltipTarget = 'content';

    // ... add a header with a dismiss button...
    const altTextFormHeader = document.createElement('div');
    altTextFormHeader.classList.add('flex', 'justify-between');
    const altTextFormH2 = document.createElement('h2');
    altTextFormH2.classList.add('text-xl', 'font-bolt', 'text-slate-900');
    altTextFormH2.innerHTML = 'Description';
    const altTextFormDismissButton = document.createElement('button');
    altTextFormDismissButton.classList.add('text-sm', 'py-0', 'px-2', 'rounded-sm', 'transition', 'active:transition-none', 'bg-slate-100', 'font-medium', 'hover:bg-pink-100', 'active:bg-slate-100', 'active:text-pink-900/60', 'link-primary');
    altTextFormDismissButton.dataset.action = 'click->tooltip#ignore:prevent';
    altTextFormDismissButton.innerHTML = 'Close';

    // ... and a text input for the alt text...
    const altTextInput = document.createElement('textarea');
    altTextInput.classList.add('border', 'border-slate-200', 'rounded', 'p-2', 'text-slate-900', 'focus:outline-none', 'focus:ring-2', 'focus:ring-pink-500', 'focus:border-transparent', 'placeholder:italic', 'h-32', 'w-64', 'sm:w-96', 'md:w-120');
    altTextInput.placeholder = 'Describe the image';

    // ... and finally, set up an event listener that will sync the alt text
    // input's value with the hidden input's value.
    altTextInput.addEventListener('input', (event) => {
      altTextHiddenInput.value = event.target.value;
    });

    altTextFormHeader.appendChild(altTextFormH2);
    altTextFormHeader.appendChild(altTextFormDismissButton);
    altTextForm.appendChild(altTextFormHeader);
    altTextForm.appendChild(altTextInput);
    previewElement.appendChild(altTextForm);

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

    const remaining = this.characterLimitValue - content.length;

    this.characterCounterTarget.innerHTML = remaining;

    if (remaining < 0) {
      this.titleTarget.classList.remove('hidden');
      this.characterCounterTarget.classList.remove('text-slate-500');
      this.characterCounterTarget.classList.remove('text-amber-500');
      this.characterCounterTarget.classList.add('text-pink-500');
      this.typeTarget.value = 'Article';
    } else if (content.length > this.characterWarningValue) {
      this.titleTarget.classList.add('hidden');
      this.characterCounterTarget.classList.remove('text-pink-500');
      this.characterCounterTarget.classList.remove('text-slate-500');
      this.characterCounterTarget.classList.add('text-amber-500');
      this.typeTarget.value = 'Note';
    } else {
      this.titleTarget.classList.add('hidden');
      this.characterCounterTarget.classList.remove('text-pink-500');
      this.characterCounterTarget.classList.remove('text-amber-500');
      this.characterCounterTarget.classList.add('text-slate-500');
      this.typeTarget.value = 'Note';
    }
  };
}
