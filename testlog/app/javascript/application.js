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

// Dirty form tracking and navigation warnings
document.addEventListener("turbo:load", function() {
  // Run auto-fade for success messages after page load
  autoFadeSuccessMessages();
  const forms = document.querySelectorAll('form');
  
  forms.forEach(form => {
    let isDirty = false;
    
    // Mark form as dirty when any input changes
    form.addEventListener('input', function(e) {
      // Skip submit buttons
      if (e.target.type === 'submit') return;
      
      // Sanitize number inputs immediately
      if (e.target.type === 'number') {
        sanitizeNumberInput(e.target);
      }
      
      // Mark form as dirty
      isDirty = true;
      document.body.classList.add('form-dirty');
    });
    
    // Mark form as dirty on select/checkbox changes
    form.addEventListener('change', function(e) {
      if (e.target.type === 'submit') return;
      
      // Sanitize number inputs
      if (e.target.type === 'number') {
        sanitizeNumberInput(e.target);
      }
      
      // Mark form as dirty
      isDirty = true;
      document.body.classList.add('form-dirty');
    });
    
    // Clear dirty flag when form is submitted
    form.addEventListener('submit', function() {
      isDirty = false;
      document.body.classList.remove('form-dirty');
    });
    
    // Warn user before navigation if form is dirty
    function handleNavigation(e) {
      if (isDirty) {
        e.preventDefault();
        e.returnValue = ''; // Required for Chrome
        return 'You have unsaved changes. Are you sure you want to leave?';
      }
    }
    
    // Add beforeunload listener for browser navigation
    window.addEventListener('beforeunload', handleNavigation);
    
    // Add Turbo navigation listener
    document.addEventListener('turbo:before-visit', function(e) {
      if (isDirty) {
        if (!confirm('You have unsaved changes. Are you sure you want to leave?')) {
          e.preventDefault();
        } else {
          isDirty = false;
          document.body.classList.remove('form-dirty');
        }
      }
    });
  });

// Listen for Turbo stream updates to handle new success messages
document.addEventListener("turbo:before-stream-render", function() {
  // Run auto-fade after Turbo stream renders new content
  setTimeout(autoFadeSuccessMessages, 100);
});
  
// Handle auto-fade for success messages
  function autoFadeSuccessMessages() {
    const successMessages = document.querySelectorAll('.save-message .success-message');
    
    successMessages.forEach(message => {
      // Skip if already has fade timeout set
      if (message.dataset.fadeTimeout) return;
      
      // Set timeout to fade out after 10 seconds
      const timeoutId = setTimeout(() => {
        message.classList.add('fade-out');
        
        // Remove the element after fade animation completes
        setTimeout(() => {
          const saveMessageContainer = message.closest('.save-message');
          if (saveMessageContainer) {
            saveMessageContainer.innerHTML = '';
          }
        }, 500); // Match the CSS animation duration
      }, 10000);
      
      // Mark this message as having a timeout
      message.dataset.fadeTimeout = timeoutId;
    });
  }
  
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
        // Clear the comment when hiding and trigger change event for auto-save
        textarea.value = '';
        textarea.dispatchEvent(new Event('change', { bubbles: true }));
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
