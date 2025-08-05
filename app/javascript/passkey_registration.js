// Passkey registration functionality
window.registerPasskey = async function() {
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
        "Accept": "application/json",
        "X-CSRF-Token": csrfToken
      },
      credentials: "same-origin"
    });
    
    if (!response.ok) {
      throw new Error("Failed to get credential options");
    }
    
    const credentialOptions = await response.json();
    
    // Convert challenge and user.id from base64
    credentialOptions.challenge = base64ToArrayBuffer(credentialOptions.challenge);
    credentialOptions.user.id = base64ToArrayBuffer(credentialOptions.user.id);
    
    // Convert excludeCredentials
    if (credentialOptions.excludeCredentials) {
      credentialOptions.excludeCredentials = credentialOptions.excludeCredentials.map(cred => ({
        ...cred,
        id: base64ToArrayBuffer(cred.id)
      }));
    }
    
    // Create credential
    const credential = await navigator.credentials.create({
      publicKey: credentialOptions
    });
    
    // Send credential to server
    const credentialData = {
      id: credential.id,
      rawId: arrayBufferToBase64(credential.rawId),
      type: credential.type,
      response: {
        clientDataJSON: arrayBufferToBase64(credential.response.clientDataJSON),
        attestationObject: arrayBufferToBase64(credential.response.attestationObject)
      },
      credential_nickname: nickname
    };
    
    const callbackResponse = await fetch("/credentials/callback", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify(credentialData),
      credentials: "same-origin"
    });
    
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
}

// Helper functions for base64 conversion
function base64ToArrayBuffer(base64) {
  // Handle URL-safe base64 (convert to standard base64)
  const standardBase64 = base64.replace(/-/g, '+').replace(/_/g, '/');
  // Add padding if necessary
  const padding = (4 - standardBase64.length % 4) % 4;
  const paddedBase64 = standardBase64 + '='.repeat(padding);
  
  const binary = atob(paddedBase64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

function arrayBufferToBase64(buffer) {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  // Use URL-safe base64 encoding
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}