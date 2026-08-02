function syncNotApplicableValue(checkbox) {
  const label = checkbox.closest(".na-label");
  const numberInput = label?.previousElementSibling;

  if (!(numberInput instanceof HTMLInputElement)) return;

  let hiddenInput = label.querySelector(
    'input[type="hidden"][data-na-number-value]',
  );

  if (checkbox.checked) {
    if (!hiddenInput) {
      hiddenInput = document.createElement("input");
      hiddenInput.type = "hidden";
      hiddenInput.dataset.naNumberValue = "true";
      label.appendChild(hiddenInput);
    }

    hiddenInput.name = numberInput.name;
    hiddenInput.value = "0";
  } else {
    hiddenInput?.remove();
  }
}

function syncNotApplicableValues(root = document) {
  root
    .querySelectorAll('.na-label input[type="checkbox"]')
    .forEach(syncNotApplicableValue);
}

document.addEventListener("change", (event) => {
  if (event.target.matches('.na-label input[type="checkbox"]')) {
    syncNotApplicableValue(event.target);
  }
});

document.addEventListener("DOMContentLoaded", () => syncNotApplicableValues());
document.addEventListener("turbo:load", () => syncNotApplicableValues());
document.addEventListener("turbo:frame-load", (event) =>
  syncNotApplicableValues(event.target),
);
