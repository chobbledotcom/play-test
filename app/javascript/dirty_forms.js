// DirtyForms - tracks form changes and shows unsaved indicator
class DirtyForms {
  constructor() {
    // console.log("[DirtyForms] Constructor called");
    this.indicator = null;
    this.trackedForms = new WeakMap();
  }

  init() {
    // console.log("[DirtyForms] Init called");
    this.createIndicator();
    this.trackForms();
  }

  createIndicator() {
    // console.log("[DirtyForms] CreateIndicator called");
    // Check if indicator already exists
    const existingIndicator = document.getElementById("dirty-form-indicator");
    if (existingIndicator) {
      // console.log("[DirtyForms] Found existing indicator, reusing");
      this.indicator = existingIndicator;
      // Re-attach event listener in case it was lost
      const button = this.indicator.querySelector("button");
      button.replaceWith(button.cloneNode(true)); // Remove old listeners
      this.indicator.querySelector("button").addEventListener("click", () => {
        // console.log("[DirtyForms] Save button clicked");
        const dirtyForm = this.findDirtyForm();
        dirtyForm?.requestSubmit();
      });
      return;
    }

    // console.log("[DirtyForms] Creating new indicator");
    this.indicator = document.createElement("div");
    this.indicator.id = "dirty-form-indicator";
    this.indicator.innerHTML = `
      <div class="dirty-form-content">
        <span>Unsaved changes</span>
        <button type="button">Save</button>
      </div>
    `;
    this.indicator.style.display = "none";
    document.body.appendChild(this.indicator);

    // Handle save button click
    this.indicator.querySelector("button").addEventListener("click", () => {
      // console.log("[DirtyForms] Save button clicked");
      const dirtyForm = this.findDirtyForm();
      dirtyForm?.requestSubmit();
    });
  }

  trackForms() {
    const forms = document.querySelectorAll("form");
    // console.log(`[DirtyForms] TrackForms called, found ${forms.length} forms`);
    forms.forEach((form, index) => {
      // console.log(`[DirtyForms] Processing form ${index}`);
      this.trackForm(form);
    });
  }

  trackForm(form) {
    // Only track forms with save message element
    const hasSaveMessage = form.querySelector("#form_save_message");
    // console.log(
    //   `[DirtyForms] TrackForm: has save message? ${!!hasSaveMessage}`,
    // );
    if (!hasSaveMessage) {
      // console.log("[DirtyForms] Skipping form - no save message element");
      return;
    }

    // Skip if already tracking
    if (this.trackedForms.has(form)) {
      // console.log("[DirtyForms] Skipping form - already tracking");
      return;
    }

    // console.log("[DirtyForms] Tracking new form");
    const formData = {
      initialState: this.captureState(form),
    };

    // Track input changes
    const inputHandler = () => {
      // console.log("[DirtyForms] Input/change event fired");
      if (this.isDirty(form, formData.initialState)) {
        // console.log("[DirtyForms] Form is dirty, showing indicator");
        this.show();
      } else {
        // console.log("[DirtyForms] Form is clean, hiding indicator");
        this.hide();
      }
    };

    // Add listeners
    form.addEventListener("input", inputHandler);
    form.addEventListener("change", inputHandler);
    // console.log("[DirtyForms] Added input/change listeners");

    // Reset on submit
    form.addEventListener("submit", () => {
      // console.log("[DirtyForms] Form submitted, resetting state");
      this.hide();
      formData.initialState = this.captureState(form);
    });

    // Store form data
    this.trackedForms.set(form, formData);
    // console.log("[DirtyForms] Form tracking complete");
  }

  captureState(form) {
    const data = new FormData(form);
    const state = {};

    for (const [key, value] of data.entries()) {
      // Handle multiple values for same key (checkboxes, multi-select)
      if (key in state) {
        if (!Array.isArray(state[key])) {
          state[key] = [state[key]];
        }
        state[key].push(value);
      } else {
        state[key] = value;
      }
    }

    return JSON.stringify(state);
  }

  isDirty(form, initialState) {
    return this.captureState(form) !== initialState;
  }

  findDirtyForm() {
    for (const form of document.querySelectorAll("form")) {
      const formData = this.trackedForms.get(form);
      if (formData && this.isDirty(form, formData.initialState)) {
        return form;
      }
    }
    return null;
  }

  show() {
    if (this.indicator) {
      this.indicator.style.display = "block";
    }
  }

  hide() {
    if (this.indicator) {
      this.indicator.style.display = "none";
    }
  }

  cleanup() {
    // console.log("[DirtyForms] Cleanup called");
    // Clear all tracked forms for fresh start
    this.trackedForms = new WeakMap();
    // Hide indicator
    this.hide();
    // console.log("[DirtyForms] Cleanup complete");
  }

  hasDirtyForm() {
    return this.findDirtyForm() !== null;
  }
}

// Create singleton instance
const dirtyForms = new DirtyForms();

// Initialize on first load
document.addEventListener("DOMContentLoaded", () => {
  // console.log("[DirtyForms] DOMContentLoaded event fired");
  dirtyForms.init();
});

// Reinitialize after Turbo navigation
document.addEventListener("turbo:load", () => {
  // console.log("[DirtyForms] turbo:load event fired");
  dirtyForms.cleanup();
  dirtyForms.init();
});

// Track dynamically loaded forms
document.addEventListener("turbo:frame-load", () => {
  // console.log("[DirtyForms] turbo:frame-load event fired");
  dirtyForms.trackForms();
});

// Clean up before cache
document.addEventListener("turbo:before-cache", () => {
  // console.log("[DirtyForms] turbo:before-cache event fired");
  dirtyForms.hide();
});

// Intercept navigation when forms are dirty
document.addEventListener("turbo:before-visit", (event) => {
  // console.log("[DirtyForms] turbo:before-visit event fired");
  if (dirtyForms.hasDirtyForm()) {
    const message =
      "You have unsaved changes. Are you sure you want to leave this page?";
    if (!confirm(message)) {
      // console.log("[DirtyForms] Navigation cancelled - dirty form");
      event.preventDefault();
    } else {
      // console.log("[DirtyForms] Navigation allowed despite dirty form");
    }
  }
});

// Also handle browser back/forward buttons
window.addEventListener("beforeunload", (event) => {
  if (dirtyForms.hasDirtyForm()) {
    const message =
      "You have unsaved changes. Are you sure you want to leave this page?";
    event.returnValue = message;
    return message;
  }
});
