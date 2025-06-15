// Self-contained decimal field enhancement
(function() {
  function initializeDecimalFields() {
    const decimalInputs = document.querySelectorAll('.decimal-input');
    
    decimalInputs.forEach(function(input) {
      // Skip if already initialized
      if (input.dataset.decimalInitialized) return;
      input.dataset.decimalInitialized = 'true';
      
      // Format and trim trailing zeros on blur
      input.addEventListener('blur', function() {
        let value = this.value.trim();
        if (value === '') return;
        
        const numValue = parseFloat(value);
        if (!isNaN(numValue)) {
          // Convert to string to remove trailing zeros
          this.value = numValue.toString();
        }
      });
      
      // Clean input as user types
      input.addEventListener('input', function() {
        const value = this.value;
        const min = parseFloat(this.dataset.min);
        const max = parseFloat(this.dataset.max);
        
        // Remove invalid characters (keep digits, one dot, one minus at start)
        let cleaned = value.replace(/[^0-9.-]/g, '');
        
        // Handle minus sign (only at start)
        const minusCount = (cleaned.match(/-/g) || []).length;
        if (minusCount > 1) {
          cleaned = (cleaned.charAt(0) === '-' ? '-' : '') + cleaned.replace(/-/g, '');
        } else if (cleaned.includes('-') && cleaned.charAt(0) !== '-') {
          cleaned = cleaned.replace(/-/g, '');
        }
        
        // Handle decimal point (only one allowed)
        const dotCount = (cleaned.match(/\./g) || []).length;
        if (dotCount > 1) {
          const firstDotIndex = cleaned.indexOf('.');
          cleaned = cleaned.substring(0, firstDotIndex + 1) + 
                   cleaned.substring(firstDotIndex + 1).replace(/\./g, '');
        }
        
        this.value = cleaned;
        
        // Validate range if specified
        const numValue = parseFloat(cleaned);
        if (!isNaN(numValue)) {
          if (!isNaN(min) && numValue < min) {
            this.setCustomValidity(`Value must be at least ${min}`);
          } else if (!isNaN(max) && numValue > max) {
            this.setCustomValidity(`Value must be at most ${max}`);
          } else {
            this.setCustomValidity('');
          }
        } else if (cleaned !== '' && cleaned !== '-') {
          this.setCustomValidity('Please enter a valid number');
        } else {
          this.setCustomValidity('');
        }
      });
    });
  }
  
  // Initialize on page load
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeDecimalFields);
  } else {
    initializeDecimalFields();
  }
  
  // Re-initialize after Turbo navigations
  document.addEventListener('turbo:load', initializeDecimalFields);
  document.addEventListener('turbo:frame-load', initializeDecimalFields);
})();