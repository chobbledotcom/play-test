// DirtyForms - tracks form changes and shows unsaved indicator
class DirtyForms {
	constructor() {
		this.indicator = null;
		this.trackedForms = new WeakMap();
		this.beforeUnloadHandler = null;
	}

	init() {
		this.createIndicator();
		this.trackForms();
	}

	createIndicator() {
		const existingIndicator = document.getElementById("dirty-form-indicator");
		if (existingIndicator) {
			this.indicator = existingIndicator;
			const button = this.indicator.querySelector("button");
			button.replaceWith(button.cloneNode(true)); // Remove old listeners
			this.indicator.querySelector("button").addEventListener("click", () => {
				const dirtyForm = this.findDirtyForm();
				dirtyForm?.requestSubmit();
			});
			return;
		}

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

		this.indicator.querySelector("button").addEventListener("click", () => {
			this.findDirtyForm()?.requestSubmit();
		});
	}

	trackForms() {
		const forms = document.querySelectorAll("form");
		forms.forEach((form, index) => {
			this.trackForm(form);
		});
	}

	trackForm(form) {
		const hasSaveMessage = form.querySelector("#form_save_message");
		if (!hasSaveMessage) {
			return;
		}

		const formAction = form.action || "";
		if (
			formAction.includes("/login") ||
			formAction.includes("/signup") ||
			formAction.includes("/safety_standards") ||
			formAction.includes("/search")
		) {
			return;
		}

		// If already tracking, just update the initial state
		if (this.trackedForms.has(form)) {
			const formData = this.trackedForms.get(form);
			formData.initialState = this.captureState(form);
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

		const handleFormSubmit = () => {
			// Just hide the indicator when submitting, don't update state yet
			// State will be updated when we get a successful response
			this.hide();
		};

		// Listen to both submit and formdata events to catch all submission methods
		form.addEventListener("submit", handleFormSubmit);
		form.addEventListener("formdata", handleFormSubmit);

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

	resetFormState(form = null) {
		if (form) {
			// Reset specific form
			const formData = this.trackedForms.get(form);
			if (formData) {
				formData.initialState = this.captureState(form);
			}
		} else {
			// Reset all forms
			const forms = document.querySelectorAll("form");
			forms.forEach((f) => {
				const formData = this.trackedForms.get(f);
				if (formData) {
					formData.initialState = this.captureState(f);
				}
			});
		}
		this.hide();
		this.unload();
	}

	unload() {
		// Remove the beforeunload event listener to prevent the browser warning
		if (this.beforeUnloadHandler) {
			window.removeEventListener("beforeunload", this.beforeUnloadHandler);
			// Re-add it after a short delay to handle new changes
			setTimeout(() => {
				window.addEventListener("beforeunload", this.beforeUnloadHandler);
			}, 100);
		}
	}
}

const dirtyForms = new DirtyForms();

// Expose resetFormState globally so it can be called from Turbo responses
window.resetFormState = () => dirtyForms.resetFormState();

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
	}
});

// Reset form state after successful Turbo submission
document.addEventListener("turbo:submit-end", (event) => {
	if (event.detail.success) {
		// Form submission succeeded, reset the form's tracked state
		const form = event.target;
		// Small delay to ensure Turbo streams have updated the DOM
		setTimeout(() => {
			dirtyForms.resetFormState(form);
		}, 100);
	}
});

// Store the handler so we can remove it later
dirtyForms.beforeUnloadHandler = (event) => {
	if (dirtyForms.hasDirtyForm()) {
		const message =
			"You have unsaved changes. Are you sure you want to leave this page?";
		event.returnValue = message;
		return message;
	}
};

window.addEventListener("beforeunload", dirtyForms.beforeUnloadHandler);
