// ImageResize - handles image resizing before upload
class ImageResize {
	constructor() {
		this.maxDimension = 1200; // Maximum width or height after resize
		this.triggerDimension = 2400; // Resize if any dimension exceeds this
		this.triggerFileSize = 1024 * 1024; // 1MB in bytes
		this.jpegQuality = 0.9; // 90% JPEG quality
		this.processedInputs = new WeakSet();
	}

	init() {
		this.attachListeners();
	}

	attachListeners() {
		// Find all file inputs that accept images
		const fileInputs = document.querySelectorAll('input[type="file"][accept*="image"]');
		fileInputs.forEach((input) => this.setupInput(input));
	}

	setupInput(input) {
		// Skip if already processed
		if (this.processedInputs.has(input)) return;
		this.processedInputs.add(input);

		// Store original accept attribute for validation
		const acceptTypes = input.getAttribute("accept");

		input.addEventListener("change", async (event) => {
			const files = Array.from(event.target.files);
			if (files.length === 0) return;

			// Process each file
			const processedFiles = await Promise.all(
				files.map((file) => this.processFile(file))
			);

			// Replace the input's files with processed versions
			this.replaceInputFiles(input, processedFiles);
		});
	}

	async processFile(file) {
		// Only process image files
		if (!file.type.startsWith("image/")) {
			return file;
		}

		// Check if file needs processing
		const needsProcessing = await this.shouldProcessFile(file);
		if (!needsProcessing) {
			return file;
		}

		try {
			const processedBlob = await this.resizeImage(file);
			// Create new File object with original name
			const processedFile = new File([processedBlob], file.name, {
				type: "image/jpeg",
				lastModified: Date.now(),
			});
			return processedFile;
		} catch (error) {
			console.error("Error processing image:", error);
			// Return original file if processing fails
			return file;
		}
	}

	async shouldProcessFile(file) {
		// Check file size first (quick check)
		if (file.size > this.triggerFileSize) {
			return true;
		}

		// Check image dimensions
		return new Promise((resolve) => {
			const img = new Image();
			const url = URL.createObjectURL(file);

			img.onload = () => {
				URL.revokeObjectURL(url);
				const maxDimension = Math.max(img.width, img.height);
				resolve(maxDimension > this.triggerDimension);
			};

			img.onerror = () => {
				URL.revokeObjectURL(url);
				resolve(false);
			};

			img.src = url;
		});
	}

	async resizeImage(file) {
		return new Promise((resolve, reject) => {
			const img = new Image();
			const url = URL.createObjectURL(file);

			img.onload = () => {
				URL.revokeObjectURL(url);

				// Calculate new dimensions
				const { width, height } = this.calculateDimensions(
					img.width,
					img.height
				);

				// Create canvas and resize
				const canvas = document.createElement("canvas");
				canvas.width = width;
				canvas.height = height;

				const ctx = canvas.getContext("2d");
				ctx.drawImage(img, 0, 0, width, height);

				// Convert to blob
				canvas.toBlob(
					(blob) => {
						if (blob) {
							resolve(blob);
						} else {
							reject(new Error("Failed to create blob"));
						}
					},
					"image/jpeg",
					this.jpegQuality
				);
			};

			img.onerror = () => {
				URL.revokeObjectURL(url);
				reject(new Error("Failed to load image"));
			};

			img.src = url;
		});
	}

	calculateDimensions(originalWidth, originalHeight) {
		const maxDimension = Math.max(originalWidth, originalHeight);

		// No need to resize if already within limits
		if (maxDimension <= this.maxDimension) {
			return { width: originalWidth, height: originalHeight };
		}

		// Calculate scale factor
		const scale = this.maxDimension / maxDimension;

		return {
			width: Math.round(originalWidth * scale),
			height: Math.round(originalHeight * scale),
		};
	}

	replaceInputFiles(input, files) {
		// Create new DataTransfer to hold processed files
		const dataTransfer = new DataTransfer();

		files.forEach((file) => {
			dataTransfer.items.add(file);
		});

		// Replace input's files
		input.files = dataTransfer.files;

		// Trigger change event for any listeners
		const event = new Event("change", { bubbles: true });
		input.dispatchEvent(event);
	}

	cleanup() {
		// Re-process any new inputs that appeared
		this.attachListeners();
	}
}

// Create singleton instance
const imageResize = new ImageResize();

// Initialize on first load
document.addEventListener("DOMContentLoaded", () => imageResize.init());

// Reinitialize after Turbo navigation
document.addEventListener("turbo:load", () => {
	imageResize.cleanup();
	imageResize.init();
});

// Handle dynamically loaded content
document.addEventListener("turbo:frame-load", () => {
	imageResize.attachListeners();
});