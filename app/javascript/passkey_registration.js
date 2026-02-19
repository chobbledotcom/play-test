// Passkey registration functionality
import {
  base64ToArrayBuffer,
  arrayBufferToBase64,
  postJson,
} from "webauthn_utils";

window.registerPasskey = async function () {
  const nickname = prompt("Enter a nickname for this passkey:");
  if (!nickname) return;

  try {
    // Get CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

    // Request credential creation options from server
    const response = await fetch("/credentials", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": csrfToken,
      },
      credentials: "same-origin",
    });

    if (!response.ok) {
      throw new Error("Failed to get credential options");
    }

    const credentialOptions = await response.json();

    // Debug logging in development
    if (window.location.hostname === "localhost") {
      console.log("=== WebAuthn Registration Debug Info ===");
      console.log("Credential creation options:", credentialOptions);
      console.log("RP:", credentialOptions.rp);
      console.log("User:", credentialOptions.user);
      console.log("Current origin:", window.location.origin);
    }

    // Convert challenge and user.id from base64
    credentialOptions.challenge = base64ToArrayBuffer(
      credentialOptions.challenge,
    );
    credentialOptions.user.id = base64ToArrayBuffer(credentialOptions.user.id);

    // Convert excludeCredentials
    if (credentialOptions.excludeCredentials) {
      credentialOptions.excludeCredentials =
        credentialOptions.excludeCredentials.map((cred) => ({
          ...cred,
          id: base64ToArrayBuffer(cred.id),
        }));
    }

    // Create credential
    const credential = await navigator.credentials.create({
      publicKey: credentialOptions,
    });

    // Debug log the created credential
    if (window.location.hostname === "localhost") {
      console.log("Created credential:", credential);
      console.log("Credential ID:", credential.id);
    }

    // Send credential to server
    const credentialData = {
      id: credential.id,
      rawId: arrayBufferToBase64(credential.rawId),
      type: credential.type,
      response: {
        clientDataJSON: arrayBufferToBase64(credential.response.clientDataJSON),
        attestationObject: arrayBufferToBase64(
          credential.response.attestationObject,
        ),
      },
      credential_nickname: nickname,
    };

    const callbackResponse = await postJson(
      "/credentials/callback",
      credentialData,
      csrfToken,
    );

    if (callbackResponse.ok) {
      window.location.reload();
    } else {
      const error = await callbackResponse.text();
      alert(`Error: ${error}`);
    }
  } catch (error) {
    console.error("Passkey registration error:", error);
    alert(`Failed to register passkey: ${error.message}`);
  }
};
