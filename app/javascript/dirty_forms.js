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
    const hasSaveMessage = form.querySelector("#form_save_message");
    if (!hasSaveMessage) {
      return;
    }

    const formAction = form.action || "";
    if (formAction.includes("/login") || formAction.includes("/users/new")) {
      return;
    }

    if (this.trackedForms.has(form)) {
      return;
    }

    const formData = {
      initialState: this.captureState(form),
    };

    const inputHandler = () => {
      if (this.isDirty(form, formData.initialState)) {
        this.show();
      } else {
        this.hide();
      }
    };

    form.addEventListener("input", inputHandler);
    form.addEventListener("change", inputHandler);
    form.addEventListener("submit", () => {
      this.hide();
      formData.initialState = this.captureState(form);
    });

    this.trackedForms.set(form, formData);
  }

  captureState(form) {
    const data = new FormData(form);
    const state = {};

    for (const [key, value] of data.entries()) {
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
    this.trackedForms = new WeakMap();
    this.hide();
  }

  hasDirtyForm() {
    return this.findDirtyForm() !== null;
  }
}

const dirtyForms = new DirtyForms();

document.addEventListener("DOMContentLoaded", () => {
  dirtyForms.init();
});

document.addEventListener("turbo:load", () => {
  dirtyForms.cleanup();
  dirtyForms.init();
});

document.addEventListener("turbo:frame-load", () => {
  dirtyForms.trackForms();
});

document.addEventListener("turbo:before-cache", () => {
  dirtyForms.hide();
});

document.addEventListener("turbo:before-visit", (event) => {
  if (dirtyForms.hasDirtyForm()) {
    const message =
      "You have unsaved changes. Are you sure you want to leave this page?";
    if (!confirm(message)) {
      event.preventDefault();
    } 
});

window.addEventListener("beforeunload", (event) => {
  if (dirtyForms.hasDirtyForm()) {
    const message =
      "You have unsaved changes. Are you sure you want to leave this page?";
    event.returnValue = message;
    return message;
  }
});
