// Prevent details element from closing when clicking links inside
class DetailsLinks {
	constructor() {
		this.setupEventListeners();
	}

	setupEventListeners() {
		// Find all links inside details elements
		document.querySelectorAll("details a").forEach((link) => {
			link.addEventListener("click", (e) => {
				// Stop the click from bubbling up to the details element
				e.stopPropagation();
			});
		});
	}

	static init() {
		new DetailsLinks();
	}
}

// Initialize on Turbo navigation
document.addEventListener("turbo:load", () => DetailsLinks.init());
document.addEventListener("turbo:frame-load", () => DetailsLinks.init());

// Export for importmap
export default DetailsLinks;
