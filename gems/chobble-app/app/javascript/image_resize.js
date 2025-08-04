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
		const fileInputs = document.querySelectorAll(
			'input[type="file"][accept*="image"]',
		);
		fileInputs.forEach((input) => this.setupInput(input));
	}

	setupInput(input) {
		// Skip if already processed
		if (this.processedInputs.has(input)) return;
		this.processedInputs.add(input);

		// Create a hidden canvas for this input
		const canvas = document.createElement("canvas");
		canvas.style.display = "none";
		document.body.appendChild(canvas);

		input.addEventListener("change", (event) => {
			const files = Array.from(event.target.files);
			if (files.length === 0) return;

			// Disable the input while processing
			input.disabled = true;

			// Process files synchronously to maintain user gesture
			this.processFiles(input, files, canvas)
				.then((processedFiles) => {
					// Re-enable input
					input.disabled = false;
				})
				.catch((error) => {
					console.error("Error processing files:", error);
					input.disabled = false;
				});
		});

		// Clean up canvas when input is removed
		const observer = new MutationObserver((mutations) => {
			if (!document.body.contains(input)) {
				canvas.remove();
				observer.disconnect();
			}
		});
		observer.observe(document.body, { childList: true, subtree: true });
	}

	async processFiles(input, files, canvas) {
		const processedFiles = [];

		for (const file of files) {
			const processed = await this.processFile(file, canvas);
			processedFiles.push(processed);
		}

		// Replace the input's files with processed versions
		this.replaceInputFiles(input, processedFiles);
		return processedFiles;
	}

	async processFile(file, canvas) {
		// Only process image files
		if (!file.type.startsWith("image/")) {
			return file;
		}

		try {
			// Check if file needs processing
			const needsProcessing = await this.shouldProcessFile(file);
			if (!needsProcessing) {
				return file;
			}

			const processedBlob = await this.resizeImage(file, canvas);
			// Create new File object with original name
			const processedFile = new File([processedBlob], file.name, {
				type: "image/jpeg",
				lastModified: Date.now(),
			});
			console.log(
				`Resized ${file.name}: ${file.size} bytes -> ${processedFile.size} bytes`,
			);
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

	async resizeImage(file, canvas) {
		return new Promise((resolve, reject) => {
			const img = new Image();
			const url = URL.createObjectURL(file);

			img.onload = () => {
				URL.revokeObjectURL(url);

				try {
					// Calculate new dimensions
					const { width, height } = this.calculateDimensions(
						img.width,
						img.height,
					);

					// Set canvas dimensions
					canvas.width = width;
					canvas.height = height;

					// Get context and draw
					const ctx = canvas.getContext("2d", { willReadFrequently: false });

					// Clear canvas first
					ctx.clearRect(0, 0, width, height);

					// Fill with white background for transparent images
					ctx.fillStyle = "#FFFFFF";
					ctx.fillRect(0, 0, width, height);

					// Draw image
					ctx.drawImage(img, 0, 0, width, height);

					// Convert to blob immediately
					canvas.toBlob(
						(blob) => {
							if (blob) {
								// Clear canvas after use
								ctx.clearRect(0, 0, width, height);
								resolve(blob);
							} else {
								reject(new Error("Failed to create blob"));
							}
						},
						"image/jpeg",
						this.jpegQuality,
					);
				} catch (error) {
					reject(error);
				}
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
