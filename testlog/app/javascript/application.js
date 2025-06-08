// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

// Auto-save functionality for inspection forms
document.addEventListener("turbo:load", function() {
  const autoSaveForms = document.querySelectorAll('form[data-autosave="true"]');
  
  autoSaveForms.forEach(form => {
    let saveTimeout;
    const statusElement = form.querySelector('[data-autosave-status]');
    const savingElement = statusElement?.querySelector('.saving');
    const savedElement = statusElement?.querySelector('.saved');
    const errorElement = statusElement?.querySelector('.error');
    
    let currentField = null;
    let fieldErrorTimeout = null;
    
    const showFieldStatus = (field, type, errorMessage = null) => {
      if (!field) return;
      
      // Remove any existing status classes
      field.classList.remove('autosave-saving', 'autosave-saved', 'autosave-error');
      
      // Remove any existing error message
      const existingError = field.parentElement.querySelector('.autosave-field-error');
      if (existingError) {
        existingError.remove();
      }
      
      // Clear any existing timeout
      if (fieldErrorTimeout) {
        clearTimeout(fieldErrorTimeout);
      }
      
      // Add the new status class
      field.classList.add(`autosave-${type}`);
      
      // Handle different status types
      switch(type) {
        case 'saved':
          // Remove the saved status after 2 seconds
          setTimeout(() => {
            field.classList.remove('autosave-saved');
          }, 2000);
          break;
        case 'error':
          // Add error message if provided
          if (errorMessage) {
            const errorDiv = document.createElement('div');
            errorDiv.className = 'autosave-field-error';
            errorDiv.textContent = errorMessage;
            field.parentElement.appendChild(errorDiv);
          }
          // Keep error status until user interacts with the field again
          break;
      }
    };
    
    const showStatus = (type, errorMessage = null) => {
      // Show field-level status
      if (currentField) {
        showFieldStatus(currentField, type, errorMessage);
      }
      
      // Show global status (existing code)
      if (!statusElement) return;
      
      // Remove all status classes and hide all status elements
      statusElement.classList.remove('saving', 'saved', 'error');
      savingElement?.style && (savingElement.style.display = 'none');
      savedElement?.style && (savedElement.style.display = 'none');
      errorElement?.style && (errorElement.style.display = 'none');
      
      // Show the container and add the appropriate class and text
      statusElement.classList.add('visible', type);
      
      switch(type) {
        case 'saving':
          savingElement?.style && (savingElement.style.display = 'inline');
          break;
        case 'saved':
          savedElement?.style && (savedElement.style.display = 'inline');
          setTimeout(() => {
            savedElement?.style && (savedElement.style.display = 'none');
            statusElement.classList.remove('visible', 'saved');
          }, 3000);
          break;
        case 'error':
          errorElement?.style && (errorElement.style.display = 'inline');
          if (errorMessage) {
            errorElement.textContent = errorMessage;
          }
          setTimeout(() => {
            errorElement?.style && (errorElement.style.display = 'none');
            statusElement.classList.remove('visible', 'error');
          }, 5000);
          break;
      }
    };
    
    const saveForm = async () => {
      showStatus('saving');
      
      try {
        // Create a form submission using Turbo Streams
        const formData = new FormData(form);
        
        const response = await fetch(form.action, {
          method: 'PATCH',
          body: formData,
          headers: {
            'Accept': 'text/vnd.turbo-stream.html',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
          }
        });
        
        if (response.ok) {
          const turboStreamContent = await response.text();
          if (turboStreamContent.trim()) {
            // Let Turbo handle the stream response
            Turbo.renderStreamMessage(turboStreamContent);
          }
          showStatus('saved');
        } else {
          showStatus('error');
          console.error('Auto-save failed with status:', response.status);
        }
      } catch (error) {
        showStatus('error');
        console.error('Auto-save error:', error);
      }
    };
    
    // Auto-save on input change with debouncing
    form.addEventListener('input', function(e) {
      // Skip auto-save for submit buttons
      if (e.target.type === 'submit') return;
      
      // Track the current field
      currentField = e.target;
      
      // Remove error status when user starts typing again
      if (currentField.classList.contains('autosave-error')) {
        currentField.classList.remove('autosave-error');
        const existingError = currentField.parentElement.querySelector('.autosave-field-error');
        if (existingError) {
          existingError.remove();
        }
      }
      
      clearTimeout(saveTimeout);
      saveTimeout = setTimeout(saveForm, 2000); // Save after 2 seconds of inactivity
    });
    
    // Auto-save on select/checkbox change
    form.addEventListener('change', function(e) {
      if (e.target.type === 'submit') return;
      
      // Track the current field
      currentField = e.target;
      
      // Remove error status when user changes value
      if (currentField.classList.contains('autosave-error')) {
        currentField.classList.remove('autosave-error');
        const existingError = currentField.parentElement.querySelector('.autosave-field-error');
        if (existingError) {
          existingError.remove();
        }
      }
      
      clearTimeout(saveTimeout);
      saveTimeout = setTimeout(saveForm, 500); // Save quickly for select/checkbox changes
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
