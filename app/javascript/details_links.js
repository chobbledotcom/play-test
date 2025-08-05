class DetailsLinks {
  constructor() {
    this.setupEventListeners();
  }

  setupEventListeners() {
    document.addEventListener(
      "click",
      (e) => {
        const link = e.target.closest("a");
        if (link) {
          const details = link.closest("details");
          if (details) {
            e.stopPropagation();
          }
        }
      },
      true,
    );
  }

  static init() {
    new DetailsLinks();
  }
}

document.addEventListener("turbo:load", () => DetailsLinks.init());
document.addEventListener("turbo:frame-load", () => DetailsLinks.init());

export default DetailsLinks;
