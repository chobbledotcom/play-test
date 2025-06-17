// CommentToggles - handles comment field visibility toggling
class CommentToggles {
  constructor() {
    this.processedToggles = new WeakSet()
  }

  init() {
    this.attachListeners()
  }

  attachListeners() {
    // Find all comment toggle checkboxes
    const toggles = document.querySelectorAll('[data-comment-toggle]')
    toggles.forEach(toggle => this.setupToggle(toggle))
  }

  setupToggle(toggle) {
    // Skip if already processed
    if (this.processedToggles.has(toggle)) return
    this.processedToggles.add(toggle)

    // Set initial state
    this.updateVisibility(toggle)

    // Handle changes
    toggle.addEventListener('change', () => this.handleToggle(toggle))
  }

  handleToggle(toggle) {
    this.updateVisibility(toggle)
    
    const textareaId = toggle.getAttribute('data-comment-toggle')
    const textarea = document.getElementById(textareaId)
    
    if (!textarea) return

    if (toggle.checked) {
      // Focus the textarea when showing
      textarea.focus()
    } else {
      // Clear the textarea when hiding
      textarea.value = ''
    }
  }

  updateVisibility(toggle) {
    const containerId = toggle.getAttribute('data-comment-container')
    const container = document.getElementById(containerId)
    
    if (!container) return

    container.style.display = toggle.checked ? 'block' : 'none'
  }

  cleanup() {
    // Re-process any new toggles that appeared
    this.attachListeners()
  }
}

// Create singleton instance
const commentToggles = new CommentToggles()

// Initialize on first load
document.addEventListener('DOMContentLoaded', () => commentToggles.init())

// Reinitialize after Turbo navigation
document.addEventListener('turbo:load', () => {
  commentToggles.cleanup()
  commentToggles.init()
})

// Handle dynamically loaded content
document.addEventListener('turbo:frame-load', () => {
  commentToggles.attachListeners()
})