// NaToggles - handles N/A radio button functionality for pass/fail fields
class NaToggles {
	constructor() {
		this.processedRadios = new WeakSet();
	}

	init() {
		this.attachListeners();
	}

	attachListeners() {
		// Find all enum radio buttons (pass/fail/na)
		const enumRadios = document.querySelectorAll(
			'input[type="radio"][value="pass"], input[type="radio"][value="fail"], input[type="radio"][value="na"]',
		);
		enumRadios.forEach((radio) => this.setupRadio(radio));
	}

	setupRadio(radio) {
		// Skip if already processed
		if (this.processedRadios.has(radio)) return;
		this.processedRadios.add(radio);

		// Set initial state
		this.updatePassFailState(radio);

		// Handle changes
		radio.addEventListener("change", () => this.updatePassFailState(radio));
	}

	updatePassFailState(changedRadio) {
		// Find all radio buttons with the same name (same field)
		const fieldName = changedRadio.name;
		const allRadios = document.querySelectorAll(
			`input[type="radio"][name="${fieldName}"]`,
		);

		// Check if N/A is selected
		const naRadio = Array.from(allRadios).find((radio) => radio.value === "na");
		const isNaSelected = naRadio && naRadio.checked;

		allRadios.forEach((radio) => {
			const label = radio.parentElement;

			if (isNaSelected && radio.value !== "na") {
				// N/A is selected - mute pass/fail options
				label.classList.add("muted");
			} else {
				// N/A is not selected - remove muted class
				label.classList.remove("muted");
			}
		});
	}

	cleanup() {
		// Re-process any new radios that appeared
		this.attachListeners();
	}
}

// Create singleton instance
const naToggles = new NaToggles();

// Initialize on first load
document.addEventListener("DOMContentLoaded", () => naToggles.init());

// Reinitialize after Turbo navigation
document.addEventListener("turbo:load", () => {
	naToggles.cleanup();
	naToggles.init();
});

// Handle dynamically loaded content
document.addEventListener("turbo:frame-load", () => {
	naToggles.attachListeners();
});
