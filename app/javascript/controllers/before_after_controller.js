import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["afterImage", "divider", "slider", "stage"]
  static values = { initial: { type: Number, default: 50 } }

  connect() {
    const pct = this.initialValue || 50
    if (this.hasSliderTarget) this.sliderTarget.value = pct
    this.setPosition(pct)
    this.setZoom(1)
  }

  slide(event) {
    this.setPosition(parseFloat(event.target.value))
  }

  zoom(event) {
    const zoom = parseFloat(event.target.dataset.zoom)
    if (!Number.isFinite(zoom)) return
    this.setZoom(zoom)
  }

  setPosition(pct) {
    const clamped = Math.max(0, Math.min(100, pct))
    if (this.hasAfterImageTarget) {
      const rightInset = 100 - clamped
      const clip = `inset(0 ${rightInset}% 0 0)`
      this.afterImageTarget.style.clipPath = clip
      this.afterImageTarget.style.webkitClipPath = clip
    }
    if (this.hasDividerTarget) {
      this.dividerTarget.style.left = `${clamped}%`
    }
  }

  setZoom(zoom) {
    if (!this.hasStageTarget) return
    const clamped = [1, 2, 4].includes(zoom) ? zoom : 1
    this.stageTarget.style.width = `${clamped * 100}%`
  }
}
