class ShareButtons {
	constructor() {
		this.processedButtons = new WeakSet();
	}

	init() {
		this.attachListeners();
	}

	attachListeners() {
		const shareButtons = document.querySelectorAll("[data-share-url]");
		shareButtons.forEach((button) => this.setupButton(button));
	}

	setupButton(button) {
		if (this.processedButtons.has(button)) return;
		this.processedButtons.add(button);

		button.addEventListener("click", async (e) => {
			e.preventDefault();
			await this.handleShare(button);
		});
	}

	async handleShare(button) {
		const url = button.getAttribute("data-share-url");
		const title = button.getAttribute("data-share-title") || document.title;

		if (navigator.share) {
			try {
				await navigator.share({ title, url });
			} catch (err) {
				console.log("Share cancelled or failed", err);
			}
		} else {
			await this.copyToClipboard(button, url);
		}
	}

	async copyToClipboard(button, url) {
		try {
			await navigator.clipboard.writeText(url);
			this.showCopyFeedback(button);
		} catch (err) {
			console.error("Failed to copy URL", err);
			this.fallbackCopy(button, url);
		}
	}

	fallbackCopy(button, url) {
		const textArea = document.createElement("textarea");
		textArea.value = url;
		textArea.style.position = "fixed";
		textArea.style.left = "-999999px";
		document.body.appendChild(textArea);
		textArea.select();

		try {
			document.execCommand("copy");
			this.showCopyFeedback(button);
		} catch (err) {
			console.error("Fallback copy failed", err);
		}

		document.body.removeChild(textArea);
	}

	showCopyFeedback(button) {
		const originalText = button.textContent;
		const copiedText = button.getAttribute("data-copied-text") || "Copied!";

		button.textContent = copiedText;
		button.style.color = "#16a34a"; // green color

		setTimeout(() => {
			button.textContent = originalText;
			button.style.color = "";
		}, 2000);
	}

	cleanup() {
		this.attachListeners();
	}
}

const shareButtons = new ShareButtons();

document.addEventListener("DOMContentLoaded", () => shareButtons.init());

document.addEventListener("turbo:load", () => {
	shareButtons.cleanup();
	shareButtons.init();
});

document.addEventListener("turbo:frame-load", () => {
	shareButtons.attachListeners();
});
