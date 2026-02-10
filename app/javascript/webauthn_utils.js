// Shared WebAuthn utility functions for base64 conversion

/**
 * Convert URL-safe base64 string to ArrayBuffer
 * @param {string} base64 - URL-safe base64 encoded string
 * @returns {ArrayBuffer} - Decoded array buffer
 */
export function base64ToArrayBuffer(base64) {
  // Handle URL-safe base64 (convert to standard base64)
  const standardBase64 = base64.replace(/-/g, "+").replace(/_/g, "/");
  // Add padding if necessary
  const padding = (4 - (standardBase64.length % 4)) % 4;
  const paddedBase64 = standardBase64 + "=".repeat(padding);

  const binary = atob(paddedBase64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

/**
 * Convert ArrayBuffer to URL-safe base64 string
 * @param {ArrayBuffer} buffer - Array buffer to encode
 * @returns {string} - URL-safe base64 encoded string
 */
export function arrayBufferToBase64(buffer) {
  const bytes = new Uint8Array(buffer);
  let binary = "";
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  // Use URL-safe base64 encoding
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

/**
 * POST JSON data with CSRF token and credentials
 * @param {string} url - The endpoint URL
 * @param {object} data - The data to send as JSON
 * @param {string} csrfToken - The CSRF token
 * @returns {Promise<Response>} - The fetch response
 */
export function postJson(url, data, csrfToken) {
  return fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-CSRF-Token": csrfToken,
    },
    body: JSON.stringify(data),
    credentials: "same-origin",
  });
}
