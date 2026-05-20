local ok, minuet = pcall(require, "minuet")
if not ok then
  return
end

minuet.setup({
  provider = "gemini",
  provider_options = {
    gemini = {
      model = "gemini-2.5-flash",
      api_key = "GEMINI_API_KEY",
      stream = true,
      optional = {
        generationConfig = {
          maxOutputTokens = 256,
          thinkingConfig = {
            thinkingBudget = 0,
          },
        },
      },
    },
  },
  virtualtext = {
    auto_trigger_ft = {
      "clojure",
      "fennel",
      "lua",
      "go",
      "python",
      "javascript",
      "typescript",
      "rust",
      "sh",
    },
  },
})
