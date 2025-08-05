function initializeTabs() {
  const tabLinks = document.querySelectorAll("#safety-standard-tabs a");
  const tabPanels = document.querySelectorAll(".tab-panel");

  // Exit if not on safety standards page
  if (tabLinks.length === 0 || tabPanels.length === 0) {
    return;
  }

  // Function to show a specific tab
  function showTab(targetId) {
    // Hide all panels
    tabPanels.forEach((panel) => {
      panel.style.display = "none";
    });

    // Show target panel
    const targetPanel = document.querySelector(targetId);
    if (targetPanel) {
      targetPanel.style.display = "block";
    }

    // Update active tab styling
    tabLinks.forEach((link) => {
      if (link.getAttribute("href") === targetId) {
        link.classList.add("active");
      } else {
        link.classList.remove("active");
      }
    });
  }

  // Check if browser supports :has()
  const supportsHas = CSS.supports && CSS.supports("selector(:has(*))");

  // Always use JavaScript fallback for consistent behavior
  if (true) {
    // !supportsHas
    // Fallback for browsers without :has() support
    tabLinks.forEach((link) => {
      link.addEventListener("click", function (e) {
        e.preventDefault();
        const targetId = this.getAttribute("href");
        showTab(targetId);

        // Update URL hash
        history.pushState(null, null, targetId);
      });
    });

    // Handle hash change
    window.addEventListener("hashchange", function () {
      if (window.location.hash) {
        showTab(window.location.hash);
      }
    });

    // Initialize based on current hash or show first tab
    if (window.location.hash && document.querySelector(window.location.hash)) {
      showTab(window.location.hash);
    } else {
      showTab("#anchorage");
    }
  } else {
    // For browsers with :has() support, just handle smooth scrolling
    tabLinks.forEach((link) => {
      link.addEventListener("click", function (e) {
        // Let the browser handle the hash change, but scroll smoothly
        setTimeout(() => {
          const target = document.querySelector(this.getAttribute("href"));
          if (target) {
            const navHeight = document.querySelector(
              "#safety-standard-tabs",
            ).offsetHeight;
            const targetPosition = target.offsetTop - navHeight - 20;

            window.scrollTo({
              top: targetPosition,
              behavior: "smooth",
            });
          }
        }, 10);
      });
    });

    // Handle direct navigation to a tab via URL hash
    if (window.location.hash) {
      const target = document.querySelector(window.location.hash);
      if (target && target.classList.contains("tab-panel")) {
        setTimeout(() => {
          const navHeight =
            document.querySelector(".tab-navigation").offsetHeight;
          const targetPosition = target.offsetTop - navHeight - 20;

          window.scrollTo({
            top: targetPosition,
            behavior: "instant",
          });
        }, 100);
      }
    }
  }
}

// Initialize on various page load events
document.addEventListener("DOMContentLoaded", initializeTabs);
document.addEventListener("turbo:load", initializeTabs);
document.addEventListener("turbo:render", initializeTabs);
