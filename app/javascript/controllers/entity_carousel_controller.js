import { Controller } from "@hotwired/stimulus"

// Cycles entity-related uploads in-place without leaving the page.
export default class extends Controller {
  static targets = ["display", "openLink", "caption", "thumb"]

  connect() {
    // Initialize with the first thumbnail if present
    if (this.thumbTargets.length > 0) {
      this.selectFrom(this.thumbTargets[0])
    }
  }

  select(event) {
    event.preventDefault()
    this.selectFrom(event.currentTarget)
  }

  selectFrom(el) {
    const fullUrl = el.dataset.fullUrl
    const uploadUrl = el.dataset.uploadUrl
    const filename = el.dataset.filename || "View upload"
    const alt = el.dataset.alt || filename

    if (fullUrl && this.hasDisplayTarget) {
      this.displayTarget.src = fullUrl
      this.displayTarget.alt = alt
    }
    if (uploadUrl && this.hasOpenLinkTarget) {
      this.openLinkTarget.href = uploadUrl
    }
    if (this.hasCaptionTarget) {
      this.captionTarget.textContent = filename
    }
  }
}
