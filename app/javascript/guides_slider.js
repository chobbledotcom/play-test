function initializeGuideSlider() {
  const slider = document.querySelector(".guide-slider");
  if (!slider) return;

  const slides = slider.querySelectorAll(".slide");
  const prevButtons = slider.querySelectorAll(".slider-prev");
  const nextButtons = slider.querySelectorAll(".slider-next");
  const selectDropdowns = slider.querySelectorAll(".slider-select");

  if (
    !slides.length ||
    !prevButtons.length ||
    !nextButtons.length ||
    !selectDropdowns.length
  )
    return;

  let currentIndex = 0;

  // Show specific slide
  function showSlide(index) {
    // Ensure index is within bounds
    if (index < 0) index = slides.length - 1;
    if (index >= slides.length) index = 0;

    // Hide all slides
    slides.forEach((slide) => {
      slide.style.display = "none";
    });

    // Show current slide
    slides[index].style.display = "block";

    // Update all dropdowns
    selectDropdowns.forEach((dropdown) => {
      dropdown.value = index.toString();
    });

    // Update current index
    currentIndex = index;

    // Update button states
    updateButtonStates();
  }

  // Update button visual states
  function updateButtonStates() {
    // Update all prev buttons
    prevButtons.forEach((button) => {
      button.disabled = currentIndex === 0;
      button.style.opacity = currentIndex === 0 ? "0.5" : "1";
    });

    // Update all next buttons
    nextButtons.forEach((button) => {
      button.disabled = currentIndex === slides.length - 1;
      button.style.opacity = currentIndex === slides.length - 1 ? "0.5" : "1";
    });
  }

  // Event listeners for all prev buttons
  prevButtons.forEach((button) => {
    button.addEventListener("click", () => {
      showSlide(currentIndex - 1);
    });
  });

  // Event listeners for all next buttons
  nextButtons.forEach((button) => {
    button.addEventListener("click", () => {
      showSlide(currentIndex + 1);
    });
  });

  // Event listeners for all dropdowns
  selectDropdowns.forEach((dropdown) => {
    dropdown.addEventListener("change", (e) => {
      const selectedIndex = parseInt(e.target.value, 10);
      showSlide(selectedIndex);
    });
  });

  // Keyboard navigation
  document.addEventListener("keydown", (e) => {
    // Only handle if slider is visible on page
    if (!slider.offsetParent) return;

    // Check if user is typing in an input field
    if (e.target.tagName === "INPUT" || e.target.tagName === "TEXTAREA") return;

    if (e.key === "ArrowLeft") {
      e.preventDefault();
      showSlide(currentIndex - 1);
    } else if (e.key === "ArrowRight") {
      e.preventDefault();
      showSlide(currentIndex + 1);
    }
  });

  // Initialize - show first slide
  showSlide(0);
}

// Initialize on various page load events for Turbo compatibility
document.addEventListener("DOMContentLoaded", initializeGuideSlider);
document.addEventListener("turbo:load", initializeGuideSlider);
document.addEventListener("turbo:render", initializeGuideSlider);
