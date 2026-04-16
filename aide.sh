#!/bin/bash

# Detener el script si ocurre un error
set -e

echo "🚀 Iniciando la configuración del entorno de desarrollo en Debian 12..."

# 1. Actualización del sistema
echo "📦 Actualizando repositorios..."
sudo apt update && sudo apt upgrade -y

# 2. Instalación de dependencias básicas
echo "🛠️ Instalando dependencias de compilación y herramientas base..."
sudo apt install -y curl git build-essential unzip gettext lua5.1 liblua5.1-0-dev python3-pip

# 3. Instalación de Ollama (IA Local)
echo "🧠 Instalando Ollama..."
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
    echo "✅ Ollama instalado correctamente."
else
    echo "✔ Ollama ya está instalado."
fi

# 4. Instalación de Neovim (Versión estable con manejo de errores)
echo "🌑 Instalando Neovim..."
# Usamos -L para seguir redirecciones y nos aseguramos de la URL exacta
curl -sSL -O https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz

# Verificamos si el archivo se descargó correctamente antes de descomprimir
if file nvim-linux64.tar.gz | grep -q 'gzip compressed data'; then
    sudo rm -rf /opt/nvim-linux64
    sudo tar -C /opt -xzf nvim-linux64.tar.gz
    
    # Actualizamos el PATH solo si no está ya presente
    if ! grep -q "/opt/nvim-linux64/bin" ~/.bashrc; then
        echo 'export PATH="$PATH:/opt/nvim-linux64/bin"' >> ~/.bashrc
    fi
    export PATH="$PATH:/opt/nvim-linux64/bin"
    rm nvim-linux64.tar.gz
    echo "✅ Neovim instalado correctamente."
else
    echo "❌ Error: El archivo descargado no es un gzip válido. Revisa la conexión o la URL."
    exit 1
fi


# 5. Configuración de OpenCode.nvim
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

i# 6. Optimización de la experiencia en terminal (Bash History Search)
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
