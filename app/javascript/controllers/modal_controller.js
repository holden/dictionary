import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "overlay", "content"]

  connect() {
    // Ensure modal starts hidden
    this.close()
  }

  open() {
    this.containerTarget.classList.remove("hidden")
  }

  close() {
    this.containerTarget.classList.add("hidden")
  }
} 