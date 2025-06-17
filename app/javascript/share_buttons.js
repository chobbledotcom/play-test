// ShareButtons - handles share functionality with Web Share API fallback to clipboard
class ShareButtons {
  constructor() {
    this.processedButtons = new WeakSet()
  }

  init() {
    this.attachListeners()
  }

  attachListeners() {
    const shareButtons = document.querySelectorAll('[data-share-url]')
    shareButtons.forEach(button => this.setupButton(button))
  }

  setupButton(button) {
    // Skip if already processed
    if (this.processedButtons.has(button)) return
    this.processedButtons.add(button)

    button.addEventListener('click', async (e) => {
      e.preventDefault()
      await this.handleShare(button)
    })
  }

  async handleShare(button) {
    const url = button.getAttribute('data-share-url')
    const title = button.getAttribute('data-share-title') || document.title

    // Check if Web Share API is available (mobile)
    if (navigator.share) {
      try {
        await navigator.share({ title, url })
      } catch (err) {
        console.log('Share cancelled or failed', err)
      }
    } else {
      // Fallback to clipboard copy (desktop)
      await this.copyToClipboard(button, url)
    }
  }

  async copyToClipboard(button, url) {
    try {
      await navigator.clipboard.writeText(url)
      this.showCopyFeedback(button)
    } catch (err) {
      console.error('Failed to copy URL', err)
      // Fallback for older browsers
      this.fallbackCopy(button, url)
    }
  }

  fallbackCopy(button, url) {
    const textArea = document.createElement('textarea')
    textArea.value = url
    textArea.style.position = 'fixed'
    textArea.style.left = '-999999px'
    document.body.appendChild(textArea)
    textArea.select()
    
    try {
      document.execCommand('copy')
      this.showCopyFeedback(button)
    } catch (err) {
      console.error('Fallback copy failed', err)
    }
    
    document.body.removeChild(textArea)
  }

  showCopyFeedback(button) {
    const originalText = button.textContent
    const copiedText = button.getAttribute('data-copied-text') || 'Copied!'
    
    button.textContent = copiedText
    button.style.color = '#16a34a' // green color

    setTimeout(() => {
      button.textContent = originalText
      button.style.color = ''
    }, 2000)
  }

  cleanup() {
    // Re-process any new buttons that appeared
    this.attachListeners()
  }
}

// Create singleton instance
const shareButtons = new ShareButtons()

// Initialize on first load
document.addEventListener('DOMContentLoaded', () => shareButtons.init())

// Reinitialize after Turbo navigation
document.addEventListener('turbo:load', () => {
  shareButtons.cleanup()
  shareButtons.init()
})

// Handle dynamically loaded content
document.addEventListener('turbo:frame-load', () => {
  shareButtons.attachListeners()
})