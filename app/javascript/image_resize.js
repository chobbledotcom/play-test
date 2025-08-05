class ImageResize {
	constructor() {
		this.maxDimension = 1200;
		this.triggerDimension = 2400;
		this.triggerFileSize = 1024 * 1024;
		this.jpegQuality = 0.9;
		this.processedInputs = new WeakSet();
	}

	init() {
		this.clearAllFileInputs();
		this.attachListeners();
	}
	
	clearAllFileInputs() {
		const fileInputs = document.querySelectorAll(
			'input[type="file"][accept*="image"]',
		);
		fileInputs.forEach((input) => {
			const emptyDataTransfer = new DataTransfer();
			input.files = emptyDataTransfer.files;
			input.value = '';
		});
	}

	attachListeners() {
		const fileInputs = document.querySelectorAll(
			'input[type="file"][accept*="image"]',
		);
		fileInputs.forEach((input) => this.setupInput(input));
	}

	setupInput(input) {
		if (this.processedInputs.has(input)) return;
		this.processedInputs.add(input);

		const canvas = document.createElement("canvas");
		canvas.style.display = "none";
		document.body.appendChild(canvas);

		input.addEventListener("change", async (event) => {
			if (event.detail && event.detail.imageResizeProcessed) return;
			
			const files = Array.from(event.target.files);
			if (files.length === 0) return;

			input.disabled = true;

			try {
				const processedFiles = await this.processFiles(input, files, canvas);
				input.disabled = false;
			} catch (error) {
				console.error("Error processing images:", error);
				input.disabled = false;
			}
		});

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

		this.replaceInputFiles(input, processedFiles);
		return processedFiles;
	}

	async processFile(file, canvas) {
		if (!file.type.startsWith("image/")) {
			return file;
		}

		try {
			const needsProcessing = await this.shouldProcessFile(file);
			if (!needsProcessing)	return file;

			const processedBlob = await this.resizeImage(file, canvas);
			const newName = file.name.replace(/\.[^.]+$/, '.jpg');
			const processedFile = new File([processedBlob], newName, {
				type: "image/jpeg",
				lastModified: Date.now(),
			});
			console.log(
				`Resized ${file.name}: ${file.size} bytes -> ${processedFile.size} bytes`,
			);
			return processedFile;
		} catch (error) {
			console.error("Error processing image:", error);
			return file;
		}
	}

	async shouldProcessFile(file) {
		if (file.type !== 'image/jpeg' || file.size > this.triggerFileSize) {
			return true;
		}

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
					const { width, height } = this.calculateDimensions(
						img.width,
						img.height,
					);

					canvas.width = width;
					canvas.height = height;

					const ctx = canvas.getContext("2d", { willReadFrequently: false });
					ctx.clearRect(0, 0, width, height);

					ctx.fillStyle = "#FFFFFF";
					ctx.fillRect(0, 0, width, height);

					ctx.drawImage(img, 0, 0, width, height);

					canvas.toBlob(
						(blob) => {
							if (blob) {
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

		if (maxDimension <= this.maxDimension)
			return { width: originalWidth, height: originalHeight };

		const scale = this.maxDimension / maxDimension;

		return {
			width: Math.round(originalWidth * scale),
			height: Math.round(originalHeight * scale),
		};
	}

	replaceInputFiles(input, files) {
		const dataTransfer = new DataTransfer();
		files.forEach((file) => {
			dataTransfer.items.add(file);
		});
		input.files = dataTransfer.files;
	}

	cleanup() {
		this.attachListeners();
	}
}

const imageResize = new ImageResize();

document.addEventListener("DOMContentLoaded", () => imageResize.init());

// Initialize after Turbo navigation (page changes)
document.addEventListener("turbo:load", () => {
	imageResize.init();
});

// Use MutationObserver to catch any dynamically added inputs
// This is necessary because Turbo streams don't always trigger the events above
const observer = new MutationObserver((mutations) => {
	let hasNewInputs = false;
	
	mutations.forEach((mutation) => {
		mutation.addedNodes.forEach((node) => {
			if (node.nodeType === 1) { // Element node
				// Check if the node itself is a file input or contains file inputs
				if (node.matches && node.matches('input[type="file"][accept*="image"]')) {
					hasNewInputs = true;
				} else if (node.querySelectorAll) {
					const inputs = node.querySelectorAll('input[type="file"][accept*="image"]');
					if (inputs.length > 0) {
						hasNewInputs = true;
					}
				}
			}
		});
	});
	
	if (hasNewInputs) {
		// Small delay to ensure DOM is ready
		setTimeout(() => imageResize.attachListeners(), 100);
	}
});

// Start observing when DOM is ready
document.addEventListener("DOMContentLoaded", () => {
	observer.observe(document.body, {
		childList: true,
		subtree: true
	});
});
