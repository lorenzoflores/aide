#!/bin/bash

# Detener el script si ocurre un error
set -e

echo "🚀 Iniciando la configuración del entorno de desarrollo en Debian 12..."

# 1. Actualización del sistema
echo "📦 Actualizando repositorios..."
sudo apt update && sudo apt upgrade -y

# 2. Instalación de dependencias básicas
echo "🛠️ Instalando dependencias de compilación y herramientas base..."
sudo apt install -y curl git build-essential unzip gettext lua5.1 liblua5.1-0-dev python3-pip neovim

# 3. Instalación de Ollama (IA Local)
echo "🧠 Instalando Ollama..."
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
    echo "✅ Ollama instalado correctamente."
else
    echo "✔ Ollama ya está instalado."
fi

# 4. Configuración de OpenCode.nvim
# OpenCode.nvim requiere un gestor de plugins. Usaremos 'lazy.nvim' por ser el estándar actual.
echo "🧩 Configurando Neovim con OpenCode.nvim..."
mkdir -p ~/.config/nvim

cat <<EOF > ~/.config/nvim/init.lua
-- Instalación automática de Lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Configuración de plugins
require("lazy").setup({
  {
    "is0n/opencode.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("opencode").setup({
        -- Aquí puedes personalizar la conexión con Ollama
        provider = "ollama",
        model = "codellama", -- Asegúrate de descargar este modelo luego
      })
    end
  },
  -- Tema visual para consola
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
})

vim.cmd.colorscheme "catppuccin"
vim.opt.number = true
vim.opt.relativenumber = true
EOF

echo "✨ Proceso finalizado."
echo "⚠️  RECUERDA: Ejecuta 'ollama run codellama' en otra terminal para descargar el modelo de IA."
echo "Recarga tu terminal con: source ~/.bashrc"

# 5. Optimización de la experiencia en terminal (Bash History Search)
echo "⌨️ Configurando búsqueda rápida en el historial..."
if [ ! -f ~/.inputrc ]; then
    touch ~/.inputrc
fi

# Evitar duplicar líneas si se ejecuta el script varias veces
if ! grep -q "history-search-backward" ~/.inputrc; then
    cat <<EOF >> ~/.inputrc
"\e[A": history-search-backward
"\e[B": history-search-forward
set show-all-if-ambiguous on
set completion-ignore-case on
EOF
    bind -f ~/.inputrc
    echo "✅ Búsqueda de historial activada."
else
    echo "✔ La configuración de historial ya existe."
fi
