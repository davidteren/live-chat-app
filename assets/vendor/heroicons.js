const plugin = require("tailwindcss/plugin")

// Simplified heroicons plugin - icons are handled via Phoenix.Component
// This plugin is kept for compatibility but doesn't need to scan files
module.exports = plugin(function() {
  // No-op plugin - heroicons are used via <.icon> component in Phoenix
})
