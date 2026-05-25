vim.g.copilot_no_tab_map = true

local ok, minuet = pcall(require, "minuet")
if not ok then
  return
end

if not os.getenv("GEMINI_API_KEY") then
  vim.fn.setenv("GEMINI_API_KEY", "dummy")
end

local project = os.getenv("PROJECT_ID") or os.getenv("GOOGLE_CLOUD_PROJECT") or os.getenv("GCLOUD_PROJECT")
local region = os.getenv("GOOGLE_CLOUD_REGION") or os.getenv("GCLOUD_REGION") or "us-central1"
local model_name = "gemini-3.5-flash"

if model_name == "gemini-3.5-flash" and not os.getenv("GOOGLE_CLOUD_REGION") and not os.getenv("GCLOUD_REGION") then
  region = "global"
end

local end_point = nil
if project then
  if region == "global" then
    end_point = string.format(
      "https://aiplatform.googleapis.com/v1/projects/%s/locations/global/publishers/google/models",
      project
    )
  else
    end_point = string.format(
      "https://%s-aiplatform.googleapis.com/v1/projects/%s/locations/%s/publishers/google/models",
      region,
      project,
      region
    )
  end
end

minuet.setup({
  throttle = 6000,
  debounce = 6000,
  provider = "gemini",
  provider_options = {
    gemini = {
      model = model_name,
      api_key = "GEMINI_API_KEY",
      stream = true,
      end_point = end_point,
      optional = {
        generationConfig = {
          maxOutputTokens = 512,
          thinkingConfig = {
            thinkingBudget = 0,
          },
        },
      },
      transform = {
        function(opts)
          local project = os.getenv("PROJECT_ID") or os.getenv("GOOGLE_CLOUD_PROJECT") or os.getenv("GCLOUD_PROJECT")
          local region = os.getenv("GOOGLE_CLOUD_REGION") or os.getenv("GCLOUD_REGION") or "us-central1"
          local model = (opts.body and opts.body.model) or model_name

          if model == "gemini-3.5-flash" and not os.getenv("GOOGLE_CLOUD_REGION") and not os.getenv("GCLOUD_REGION") then
            region = "global"
          end

          if project then
            if region == "global" then
              opts.url = string.format(
                "https://aiplatform.googleapis.com/v1/projects/%s/locations/global/publishers/google/models/%s:streamGenerateContent",
                project,
                model
              )
            else
              opts.url = string.format(
                "https://%s-aiplatform.googleapis.com/v1/projects/%s/locations/%s/publishers/google/models/%s:streamGenerateContent",
                region,
                project,
                region,
                model
              )
            end

            local token = vim.fn.system("gcloud auth print-access-token")
            if vim.v.shell_error == 0 then
              token = token:gsub("%s+", "")
              opts.headers = {
                ["Authorization"] = "Bearer " .. token,
                ["Content-Type"] = "application/json; charset=utf-8",
              }
            else
              vim.notify("Minuet: failed to get gcloud access token", vim.log.levels.ERROR)
            end
          else
            vim.notify("Minuet: GCLOUD_PROJECT/GOOGLE_CLOUD_PROJECT/PROJECT_ID env var is not set", vim.log.levels.WARN)
          end

          return opts
        end,
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
    keymap = {
      accept = "<Tab>",
    },
  },
})

vim.keymap.set("i", "<Esc>", function()
  local vt = require("minuet.virtualtext")
  if vt.action.is_visible() then
    vt.action.dismiss()
    return ""
  else
    return "<Esc>"
  end
end, { expr = true, replace_keycodes = true, desc = "Minuet: Dismiss suggestion or exit insert mode" })

vim.keymap.set("i", "<Left>", function()
  local vt = require("minuet.virtualtext")
  if vt.action.is_visible() then
    vt.action.prev()
    return ""
  else
    return "<Left>"
  end
end, { expr = true, replace_keycodes = true, desc = "Minuet: Cycle to previous suggestion or move cursor left" })

vim.keymap.set("i", "<Right>", function()
  local vt = require("minuet.virtualtext")
  if vt.action.is_visible() then
    vt.action.next()
    return ""
  else
    return "<Right>"
  end
end, { expr = true, replace_keycodes = true, desc = "Minuet: Cycle to next suggestion or move cursor right" })
