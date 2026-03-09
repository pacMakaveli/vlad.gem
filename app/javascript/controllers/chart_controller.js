import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chart"
export default class extends Controller {
  static values = {
    type: String,
    data: Object,
    options: Object,
    url: String
  }

  connect() {
    if (this.hasUrlValue) {
      this.loadDataAndRender()
    } else {
      this.renderChart()
    }
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  async loadDataAndRender() {
    try {
      const response = await fetch(this.urlValue)
      const data = await response.json()
      this.dataValue = data
      this.renderChart()
    } catch (error) {
      console.error('Error loading chart data:', error)
      this.element.innerHTML = '<p class="text-red-500">Error loading chart data</p>'
    }
  }

  renderChart() {
    const ctx = this.element.getContext('2d')

    const defaultOptions = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: true,
          position: 'top'
        }
      }
    }

    const options = this.hasOptionsValue
      ? { ...defaultOptions, ...this.optionsValue }
      : defaultOptions

    // Chart.js UMD build exposes Chart on window
    this.chart = new window.Chart(ctx, {
      type: this.typeValue || 'line',
      data: this.dataValue,
      options: options
    })
  }
}
