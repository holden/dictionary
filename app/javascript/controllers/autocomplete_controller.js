import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = { url: { type: String, default: "/topics/search" } }

  connect() {
    this.timeout = null
    this.boundHideResults = this.hideResults.bind(this)
    document.addEventListener("click", this.boundHideResults)
  }

  disconnect() {
    document.removeEventListener("click", this.boundHideResults)
  }

  search(event) {
    event.stopPropagation()
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = this.inputTarget.value.trim()
      
      if (query.length < 2) {
        this.hideResults()
        return
      }

      this.fetchResults(query)
    }, 300)
  }

  async fetchResults(query) {
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      
      const response = await fetch(`/topics/search?query=${encodeURIComponent(query)}`, {
        headers: {
          "Accept": "application/json",
          "X-Requested-With": "XMLHttpRequest",
          "X-CSRF-Token": csrfToken
        }
      })
      
      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || `HTTP error! status: ${response.status}`)
      }
      
      const data = await response.json()
      this.showResults(data)
    } catch (error) {
      console.error("Error fetching results:", error)
      this.resultsTarget.innerHTML = `
        <div class="px-4 py-2 text-sm text-red-500">
          Error searching topics. Please try again.
        </div>
      `
      this.resultsTarget.classList.remove('hidden')
    }
  }

  showResults(data) {
    if (data.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="px-4 py-2 text-sm text-gray-500">
          No results found
        </div>
      `
    } else {
      this.resultsTarget.innerHTML = this.buildResultsHTML(data)
    }
    this.resultsTarget.classList.remove('hidden')
  }

  hideResults(event) {
    if (event && (this.element.contains(event.target) || event.target === this.element)) return
    this.resultsTarget.classList.add('hidden')
  }

  buildResultsHTML(topics) {
    return `
      <ul class="max-h-60 overflow-auto rounded-md py-1 text-base sm:text-sm" role="listbox">
        ${topics.map(topic => `
          <li class="relative cursor-pointer select-none py-2 pl-3 pr-9 hover:bg-gray-100">
            <a href="${topic.url}" class="block">
              <div class="flex items-center">
                <span class="font-normal block truncate">${topic.title}</span>
                <span class="ml-2 text-sm text-gray-500">
                  (${topic.part_of_speech})
                </span>
              </div>
              ${topic.definition ? `
                <p class="mt-1 text-sm text-gray-500 truncate">
                  ${topic.definition}
                </p>
              ` : ''}
            </a>
          </li>
        `).join('')}
      </ul>
    `
  }
} 