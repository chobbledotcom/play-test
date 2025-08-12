// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "comment_toggles";
import "na_toggles";
import "na_number_toggles";
import "details_links";
import "dirty_forms";
import "share_buttons";
import "safety_standards_tabs";
import "guides_slider";
import "search";
import "image_resize";
import "passkey_registration";
import "passkey_login";

// external libs
import "highlight.js";

// Initialize features on Turbo navigation
function initializeFeatures() {
  // Initialize highlight.js for code blocks
  if (window.hljs) {
    window.hljs.highlightAll();
  }
  // Handle unit selection in inspection form
  const unitSelect = document.querySelector(
    'select[name="inspection[unit_id]"]',
  );
  if (unitSelect) {
    // Handle changes to show unit details
    unitSelect.addEventListener("change", function () {
      const selectedUnitId = this.value;

      if (selectedUnitId) {
        // Trigger form refresh to show unit details
        // This could be enhanced with AJAX to avoid page refresh
        const form = this.closest("form");
        const currentUrl = new URL(window.location);
        currentUrl.searchParams.set("unit_id", selectedUnitId);
        window.location.href = currentUrl.toString();
      }
    });
  }
}

// Initialize on first load
document.addEventListener("turbo:load", initializeFeatures);

// Also initialize for frame loads
document.addEventListener("turbo:frame-load", initializeFeatures);
