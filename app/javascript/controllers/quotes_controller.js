import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  refresh(event) {
    event.preventDefault()
    
    const topicId = window.location.pathname.split('/').pop()
    
    fetch(`/topics/${topicId}/refresh_quotes`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
      }
    })
    .then(response => {
      if (response.ok) {
        Turbo.visit(window.location.href)
      }
    })
  }
} 