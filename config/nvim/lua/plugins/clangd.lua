local gpp = vim.fn.exepath("g++")
if gpp == "" then
  gpp = "g++"
end

return {
  {
    "mason-org/mason.nvim",
    opts = { PATH = "append" },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders=true",
            "--fallback-style=llvm",
            "--query-driver=" .. gpp,
          },
          init_options = {
            fallbackFlags = { "-std=c++20", "-Wall", "-Wextra", "-Wpedantic" },
          },
        },
      },
    },
  },
}
