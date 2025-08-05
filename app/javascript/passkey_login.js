// Passkey login functionality
document.addEventListener("turbo:load", () => {
  const loginButtons = document.querySelectorAll('[data-controller="passkey-login"]');
  
  loginButtons.forEach(button => {
    button.addEventListener("click", async (event) => {
      event.preventDefault();
      
      // Show loading state
      const buttonText = document.getElementById('passkey-button-text');
      const buttonSpinner = document.getElementById('passkey-button-spinner');
      if (buttonText && buttonSpinner) {
        buttonText.textContent = 'Authenticating...';
        buttonSpinner.style.display = 'inline-block';
        button.disabled = true;
      }
      
      try {
        // Get CSRF token
        const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
        
        // Request authentication options from server
        const response = await fetch("/passkey_login.json", {
          method: "GET",
          headers: {
            "Accept": "application/json",
            "X-CSRF-Token": csrfToken
          },
          credentials: "same-origin"
        });
        
        if (!response.ok) {
          throw new Error("Failed to get authentication options");
        }
        
        const credentialOptions = await response.json();
        
        // Debug logging in development
        if (window.location.hostname === 'localhost') {
          console.log("=== WebAuthn Debug Info ===");
          console.log("Credential options from server:", credentialOptions);
          console.log("RP ID:", credentialOptions.rpId);
          console.log("Timeout:", credentialOptions.timeout);
          console.log("User Verification:", credentialOptions.userVerification);
          
          if (credentialOptions.allowCredentials) {
            console.log("Allow Credentials Count:", credentialOptions.allowCredentials.length);
            credentialOptions.allowCredentials.forEach((cred, index) => {
              console.log(`Credential ${index + 1}:`, {
                id: cred.id,
                type: cred.type,
                transports: cred.transports
              });
            });
          } else {
            console.log("No allowCredentials specified - will use any available credential");
          }
          
          // Update debug info on page
          const debugInfo = document.getElementById('passkey-debug-info');
          if (debugInfo) {
            debugInfo.innerHTML = `
              <h4>Credential Request Details:</h4>
              <pre>${JSON.stringify(credentialOptions, null, 2)}</pre>
            `;
          }
        }
        
        // Convert challenge from base64
        credentialOptions.challenge = base64ToArrayBuffer(credentialOptions.challenge);
        
        // Convert allowCredentials if present
        if (credentialOptions.allowCredentials) {
          credentialOptions.allowCredentials = credentialOptions.allowCredentials.map(cred => ({
            ...cred,
            id: base64ToArrayBuffer(cred.id)
          }));
        }
        
        // Get credential
        const credential = await navigator.credentials.get({
          publicKey: credentialOptions
        });
        
        // Send credential to server
        const credentialData = {
          id: credential.id,
          rawId: arrayBufferToBase64(credential.rawId),
          type: credential.type,
          response: {
            clientDataJSON: arrayBufferToBase64(credential.response.clientDataJSON),
            authenticatorData: arrayBufferToBase64(credential.response.authenticatorData),
            signature: arrayBufferToBase64(credential.response.signature),
            userHandle: credential.response.userHandle ? 
              arrayBufferToBase64(credential.response.userHandle) : null
          }
        };
        
        const callbackResponse = await fetch("/passkey_callback", {
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
          window.location.href = "/inspections";
        } else {
          const error = await callbackResponse.text();
          alert(`Error: ${error}`);
        }
      } catch (error) {
        console.error("Passkey authentication error:", error);
        alert(`Failed to authenticate with passkey: ${error.message}`);
        
        // Reset button state
        const buttonText = document.getElementById('passkey-button-text');
        const buttonSpinner = document.getElementById('passkey-button-spinner');
        if (buttonText && buttonSpinner) {
          buttonText.textContent = 'Login with passkey';
          buttonSpinner.style.display = 'none';
          button.disabled = false;
        }
      }
    });
  });
});

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