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
