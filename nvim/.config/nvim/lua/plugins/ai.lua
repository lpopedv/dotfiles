return {
  {
    enabled = true,
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false,
    opts = {
      provider = "openrouter",
      vendors = {
        openrouter = {
          __inherited_from = "openai",
          endpoint = "https://openrouter.ai/api/v1",
          model = "anthropic/claude-3.5-haiku",
          api_key_name = "OPENROUTER_API_KEY",
        },
      },
    },
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
          },
        },
      },
    },
  },
}
