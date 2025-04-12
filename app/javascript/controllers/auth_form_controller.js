import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="auth-form"
export default class extends Controller {
  // Define targets for the fields we want to show/hide
  static targets = [ "fieldsContainer", "endpointUrlField", "clientIdField", "clientSecretField" ]

  connect() {
    // Call toggleFields initially to set the correct state when the form loads
    this.toggleFields()
  }

  toggleFields() {
    // Get the selected authentication type value
    const authType = this.element.querySelector("#service_authentication_configuration_auth_type").value;

    // Hide all fields initially
    this.hide(this.endpointUrlFieldTarget)
    this.hide(this.clientIdFieldTarget)
    this.hide(this.clientSecretFieldTarget)

    // Show fields based on the selected auth type
    switch(authType) {
      case 'Basic':
        // Basic auth typically needs a username (client_id) and password (client_secret)
        this.show(this.endpointUrlFieldTarget)
        this.updateLabel(this.clientIdFieldTarget, "Username")
        this.show(this.clientIdFieldTarget)
        this.updateLabel(this.clientSecretFieldTarget, "Password")
        this.show(this.clientSecretFieldTarget)
        this.hide(this.endpointUrlFieldTarget)
        break;
      case 'ESRIToken':
        this.show(this.endpointUrlFieldTarget)
        this.updateLabel(this.clientIdFieldTarget, "Username")
        this.show(this.clientIdFieldTarget)
        this.updateLabel(this.clientSecretFieldTarget, "Password")
        this.show(this.clientSecretFieldTarget)
        break;
      case 'OAuth2 Client':
        // ESRI OAuth needs an endpoint (e.g., portal URL), client ID, and client secret
        this.show(this.endpointUrlFieldTarget)
        this.updateLabel(this.clientIdFieldTarget, "Client ID")
        this.show(this.clientIdFieldTarget)
        this.updateLabel(this.clientSecretFieldTarget, "Client Secret")
        this.show(this.clientSecretFieldTarget)
        break;
      default:
        // Default case or if no type is selected, potentially show all or none
        // Currently hides all as per the initial state
        break;
    }
  }

  // Helper function to hide an element
  hide(element) {
    element.style.display = 'none';
  }

  // Helper function to show an element
  show(element) {
    element.style.display = ''; // Use empty string to revert to default display (usually block or inline-block for form elements)
  }

  // Helper function to update the label of a form input group
  updateLabel(element, newLabelText) {
    const label = element.querySelector("label");
    if (label) {
      label.textContent = newLabelText;
    }
  }
}
