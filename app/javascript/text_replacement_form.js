function initializeTextReplacementForm() {
  const keyInput = document.querySelector(
    'input[name="text_replacement[i18n_key]"]',
  );
  const valueTextarea = document.querySelector(
    'textarea[name="text_replacement[value]"]',
  );

  if (!keyInput || !valueTextarea) {
    return;
  }

  let debounceTimeout;

  keyInput.addEventListener("input", function () {
    const selectedKey = this.value.trim();

    clearTimeout(debounceTimeout);

    if (!selectedKey) {
      valueTextarea.placeholder = "";
      return;
    }

    debounceTimeout = setTimeout(async () => {
      try {
        const response = await fetch(
          `/admin_text_replacements/i18n_value?key=${encodeURIComponent(selectedKey)}`,
        );
        const data = await response.json();

        if (data.value) {
          valueTextarea.placeholder = data.value;
        } else {
          valueTextarea.placeholder = "";
        }
      } catch (error) {
        console.error("Failed to fetch i18n value:", error);
        valueTextarea.placeholder = "";
      }
    }, 300);
  });
}

document.addEventListener("turbo:load", initializeTextReplacementForm);
document.addEventListener("turbo:frame-load", initializeTextReplacementForm);
