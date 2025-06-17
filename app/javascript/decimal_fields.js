// DecimalFields - handles decimal and number input formatting and validation
class DecimalFields {
  constructor() {
    this.initializedInputs = new WeakSet()
  }

  init() {
    this.initializeFields()
  }

  formatNumberValue(value) {
    if (value === '' || value === null || value === undefined) return value
    
    const numValue = parseFloat(value)
    if (isNaN(numValue)) return value
    
    return numValue.toString() // Automatically removes trailing zeros
  }

  initializeFields() {
    // Handle both decimal inputs and regular number inputs
    const numberInputs = document.querySelectorAll('.decimal-input, input[type="number"]')
    
    numberInputs.forEach(input => this.initializeInput(input))
  }

  initializeInput(input) {
    // Skip if already initialized
    if (this.initializedInputs.has(input)) return
    this.initializedInputs.add(input)
    
    // Format initial value on load to remove trailing zeros
    if (input.value) {
      input.value = this.formatNumberValue(input.value)
    }
    
    // Format and trim trailing zeros on blur
    input.addEventListener('blur', () => {
      const value = input.value.trim()
      if (value === '') return
      
      const numValue = parseFloat(value)
      if (!isNaN(numValue)) {
        // Convert to string to remove trailing zeros
        input.value = numValue.toString()
      }
    })
    
    // Clean input as user types (for decimal inputs only)
    if (input.classList.contains('decimal-input')) {
      input.addEventListener('input', () => this.handleDecimalInput(input))
    }
  }

  handleDecimalInput(input) {
    const value = input.value
    const min = parseFloat(input.dataset.min)
    const max = parseFloat(input.dataset.max)
    
    // Remove invalid characters (keep digits, one dot, one minus at start)
    let cleaned = value.replace(/[^0-9.-]/g, '')
    
    // Handle minus sign (only at start)
    const minusCount = (cleaned.match(/-/g) || []).length
    if (minusCount > 1) {
      const hasLeadingMinus = cleaned.charAt(0) === '-'
      cleaned = (hasLeadingMinus ? '-' : '') + cleaned.replace(/-/g, '')
    } else if (cleaned.includes('-') && cleaned.charAt(0) !== '-') {
      cleaned = cleaned.replace(/-/g, '')
    }
    
    // Handle decimal point (only one allowed)
    const dotCount = (cleaned.match(/\./g) || []).length
    if (dotCount > 1) {
      const firstDotIndex = cleaned.indexOf('.')
      const beforeDot = cleaned.substring(0, firstDotIndex + 1)
      const afterDot = cleaned.substring(firstDotIndex + 1).replace(/\./g, '')
      cleaned = beforeDot + afterDot
    }
    
    input.value = cleaned
    
    // Validate range if specified
    const numValue = parseFloat(cleaned)
    if (!isNaN(numValue)) {
      if (!isNaN(min) && numValue < min) {
        input.setCustomValidity(`Value must be at least ${min}`)
      } else if (!isNaN(max) && numValue > max) {
        input.setCustomValidity(`Value must be at most ${max}`)
      } else {
        input.setCustomValidity('')
      }
    } else if (cleaned !== '' && cleaned !== '-') {
      input.setCustomValidity('Please enter a valid number')
    } else {
      input.setCustomValidity('')
    }
  }

  cleanup() {
    // Clean up references to removed inputs
    const allInputs = new Set(document.querySelectorAll('.decimal-input, input[type="number"]'))
    
    // WeakSet automatically handles cleanup, but we can reinitialize new inputs
    allInputs.forEach(input => {
      if (!this.initializedInputs.has(input)) {
        this.initializeInput(input)
      }
    })
  }
}

// Create singleton instance
const decimalFields = new DecimalFields()

// Initialize on first load
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => decimalFields.init())
} else {
  decimalFields.init()
}

// Reinitialize after Turbo navigation
document.addEventListener('turbo:load', () => {
  decimalFields.cleanup()
  decimalFields.init()
})

// Handle dynamically loaded forms
document.addEventListener('turbo:frame-load', () => {
  decimalFields.initializeFields()
})