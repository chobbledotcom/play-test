// FederationSearch - handles searching across federated sites
class FederationSearch {
  constructor() {
    this.form = null;
    this.resultsContainer = null;
    this.resultsBody = null;
  }

  init() {
    // Find the form inside the search div or use the homepage search form
    const searchDiv = document.getElementById("search");
    this.form = searchDiv ? searchDiv.querySelector("form") : null;
    if (!this.form) {
      this.form = document.getElementById("homepage-search");
    }

    this.resultsContainer = document.getElementById("search-results");
    this.resultsBody = document.getElementById("results-body");

    if (!this.form) return;

    this.form.addEventListener("submit", (e) => {
      e.preventDefault();
      this.performSearch();
    });

    // Check URL params and auto-submit if id is present
    const urlParams = new URLSearchParams(window.location.search);
    const id = urlParams.get("id");
    if (id) {
      const idField = this.form.querySelector('input[name="id"]');
      if (idField) {
        idField.value = id;
        this.performSearch();
      }
    }
  }

  performSearch() {
    const formData = new FormData(this.form);
    const id = formData.get("id").toUpperCase();

    // Show results container
    this.resultsContainer.style.display = "block";

    // Reset all status cells
    const rows = this.resultsBody.querySelectorAll("tr");
    rows.forEach((row) => {
      const statusCell = row.querySelector(".status");
      const actionCell = row.querySelector(".action");
      statusCell.textContent = "Searching...";
      statusCell.className = "status searching";
      actionCell.textContent = "-";
    });

    // Check each site for both units and inspections
    rows.forEach((row) => {
      const siteUrl = row.dataset.siteUrl;
      const type = row.dataset.type;
      this.checkSite(row, siteUrl, type, id);
    });
  }

  async checkSite(row, siteUrl, type, id) {
    const statusCell = row.querySelector(".status");
    const actionCell = row.querySelector(".action");
    const baseUrl = siteUrl || "";
    const checkUrl = `${baseUrl}/${type}s/${id}`;

    try {
      // Use HEAD request to check if resource exists
      const response = await fetch(checkUrl, {
        method: "HEAD",
        mode: "cors",
        credentials: "omit",
      });

      if (response.ok) {
        statusCell.textContent = "Found";
        statusCell.className = "status found";

        // Create link to the resource
        const link = document.createElement("a");
        link.href = `${baseUrl}/${type}s/${id}`;
        link.textContent = "View";
        link.target = "_blank";
        link.rel = "noopener";
        actionCell.textContent = "";
        actionCell.appendChild(link);
      } else {
        statusCell.textContent = "Not found";
        statusCell.className = "status not-found";
        actionCell.textContent = "-";
      }
    } catch (error) {
      console.error(`Error checking ${checkUrl}:`, error);
      statusCell.textContent = "Error";
      statusCell.className = "status error";
      statusCell.title = error.message || "CORS or network error";
      actionCell.textContent = "-";
    }
  }
}

// Initialize on DOMContentLoaded
document.addEventListener("DOMContentLoaded", () => {
  const search = new FederationSearch();
  search.init();
});

// Re-initialize on Turbo load
document.addEventListener("turbo:load", () => {
  const search = new FederationSearch();
  search.init();
});
