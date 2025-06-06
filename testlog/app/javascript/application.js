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
    
    const showStatus = (type) => {
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
        // Create a form submission using Turbo
        const formData = new FormData(form);
        
        const response = await fetch(form.action, {
          method: 'PATCH',
          body: formData,
          headers: {
            'Accept': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
          }
        });
        
        if (response.ok) {
          const data = await response.json();
          if (data.status === 'success') {
            showStatus('saved');
          } else {
            showStatus('error');
            console.error('Auto-save errors:', data.errors);
          }
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
      
      clearTimeout(saveTimeout);
      saveTimeout = setTimeout(saveForm, 2000); // Save after 2 seconds of inactivity
    });
    
    // Auto-save on select/checkbox change
    form.addEventListener('change', function(e) {
      if (e.target.type === 'submit') return;
      
      clearTimeout(saveTimeout);
      saveTimeout = setTimeout(saveForm, 500); // Save quickly for select/checkbox changes
    });
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
