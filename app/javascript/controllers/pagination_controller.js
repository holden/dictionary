import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "pageButton", "nextButton", "prevButton"]
  static values = { 
    perPage: { type: Number, default: 20 },
    currentPage: { type: Number, default: 1 }
  }

  connect() {
    console.log("Pagination controller connected")
    console.log(`Found ${this.itemTargets.length} items`)
    this.showCurrentPage()
    this.updateButtons()
  }

  showCurrentPage() {
    console.log(`Showing page ${this.currentPageValue}`)
    const start = (this.currentPageValue - 1) * this.perPageValue
    const end = start + this.perPageValue

    this.itemTargets.forEach((item, index) => {
      // Hide items not in current page range
      if (index >= start && index < end) {
        item.classList.remove('hidden')
      } else {
        item.classList.add('hidden')
      }
    })
  }

  next() {
    console.log("Next clicked")
    if (this.hasNextPage) {
      this.currentPageValue++
      this.showCurrentPage()
      this.updateButtons()
    }
  }

  prev() {
    console.log("Previous clicked")
    if (this.currentPageValue > 1) {
      this.currentPageValue--
      this.showCurrentPage()
      this.updateButtons()
    }
  }

  goToPage(event) {
    const page = parseInt(event.currentTarget.dataset.page)
    console.log(`Going to page ${page}`)
    if (page !== this.currentPageValue) {
      this.currentPageValue = page
      this.showCurrentPage()
      this.updateButtons()
    }
  }

  updateButtons() {
    // Update page buttons
    this.pageButtonTargets.forEach(button => {
      const page = parseInt(button.dataset.page)
      if (page === this.currentPageValue) {
        button.classList.add('bg-blue-50', 'text-blue-600', 'border-blue-500')
        button.classList.remove('text-gray-700', 'hover:bg-gray-50')
      } else {
        button.classList.remove('bg-blue-50', 'text-blue-600', 'border-blue-500')
        button.classList.add('text-gray-700', 'hover:bg-gray-50')
      }
    })

    // Update prev/next buttons
    if (this.hasPrevButtonTarget) {
      this.prevButtonTarget.disabled = this.currentPageValue === 1
    }
    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.disabled = !this.hasNextPage
    }
  }

  get totalPages() {
    return Math.ceil(this.itemTargets.length / this.perPageValue)
  }

  get hasNextPage() {
    return this.currentPageValue < this.totalPages
  }
} 