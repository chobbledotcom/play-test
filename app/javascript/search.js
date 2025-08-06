// FederationSearch - handles searching across federated sites
class FederationSearch {
  constructor() {
    this.form = null;
    this.resultsContainer = null;
    this.resultsBody = null;
    this.isSearchPage = false;
  }

  init() {
    this.resultsContainer = document.getElementById("search-results");
    this.resultsBody = document.getElementById("results-body");
    this.isSearchPage = !!(this.resultsContainer && this.resultsBody);

    this.form = document.querySelector(".search-form");

    if (!this.form) return;

    if (this.isSearchPage) {
      this.form.addEventListener("submit", (e) => {
        e.preventDefault();
        this.performSearch();
      });

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
  }

  performSearch() {
    if (!this.isSearchPage) {
      console.error("performSearch called outside of search page");
      return;
    }

    const formData = new FormData(this.form);
    const id = formData.get("id").toUpperCase();

    this.resultsContainer.style.display = "block";

    const rows = this.resultsBody.querySelectorAll("tr");
    rows.forEach((row) => {
      const statusCell = row.querySelector(".status");
      const actionCell = row.querySelector(".action");
      statusCell.textContent = "Searching...";
      statusCell.className = "status searching";
      actionCell.textContent = "-";
    });

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
      const response = await fetch(checkUrl, {
        method: "HEAD",
        mode: "cors",
        credentials: "omit",
      });

      if (response.ok) {
        statusCell.textContent = "Found";
        statusCell.className = "status found";

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

document.addEventListener("DOMContentLoaded", () => {
  const search = new FederationSearch();
  search.init();
});

document.addEventListener("turbo:load", () => {
  const search = new FederationSearch();
  search.init();
});
