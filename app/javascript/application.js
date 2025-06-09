// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

// Number input sanitization function
function sanitizeNumberInput(input) {
  const originalValue = input.value;
  
  if (originalValue === '') return; // Don't process empty values
  
  // Strip all non-numeric characters except decimal points and minus signs
  let sanitized = originalValue.replace(/[^0-9.-]/g, '');
  
  // Handle multiple minus signs - keep only first one if at beginning
  const isNegative = sanitized.startsWith('-');
  sanitized = sanitized.replace(/-/g, '');
  if (isNegative) sanitized = '-' + sanitized;
  
  // Handle multiple decimal points - keep only the first one
  const decimalParts = sanitized.split('.');
  if (decimalParts.length > 2) {
    sanitized = decimalParts[0] + '.' + decimalParts.slice(1).join('');
  }
  
  // Update the input if the value changed
  if (originalValue !== sanitized) {
    input.value = sanitized;
    
    // Add visual feedback
    input.style.borderColor = '#8b5cf6';
    input.style.outline = '2px solid rgba(139, 92, 246, 0.5)';
    
    // Remove visual feedback after a short delay
    setTimeout(() => {
      input.style.borderColor = '';
      input.style.outline = '';
    }, 1000);
    
    return true; // Indicate that sanitization occurred
  }
  
  return false; // No sanitization needed
}

document.addEventListener("turbo:load", function() {
  const forms = document.querySelectorAll('form');
  
  forms.forEach(form => {
    // Sanitize number inputs on change
    form.addEventListener('input', function(e) {
      if (e.target.type === 'number') {
        sanitizeNumberInput(e.target);
      }
    });
    
    form.addEventListener('change', function(e) {
      if (e.target.type === 'number') {
        sanitizeNumberInput(e.target);
      }
    });
  });
  
  // Handle comment field toggles
  document.addEventListener('change', function(e) {
    if (e.target.hasAttribute('data-comment-toggle')) {
      const textareaId = e.target.getAttribute('data-comment-toggle');
      const containerId = e.target.getAttribute('data-comment-container');
      const textarea = document.getElementById(textareaId);
      const container = document.getElementById(containerId);
      
      if (e.target.checked) {
        container.style.display = 'block';
        textarea.focus();
      } else {
        container.style.display = 'none';
        // Clear the comment when hiding
        textarea.value = '';
      }
    }
  });
  
  // Handle unit selection in inspection form
  const unitSelect = document.querySelector('select[name="inspection[unit_id]"]');
  if (unitSelect) {
    // Handle changes to show unit details
    unitSelect.addEventListener('change', function() {
      const selectedUnitId = this.value;
      
      if (selectedUnitId) {
        // Trigger form refresh to show unit details
        // This could be enhanced with AJAX to avoid page refresh
        const form = this.closest('form');
        const currentUrl = new URL(window.location);
        currentUrl.searchParams.set('unit_id', selectedUnitId);
        window.location.href = currentUrl.toString();
      }
    });
  }
});
