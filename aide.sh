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

# 3.1 Descarga del modelo específico para programación
echo "📥 Descargando el cerebro del entorno (Qwen3.5)..."

# Usamos pull para que sea una descarga no interactiva
ollama pull qwen3.5:latest

echo "✅ Modelo listo para usar localmente."

# 3.2 Configuración de parámetros del servicio Ollama
echo "⚙️ Ampliando el contexto de Ollama a 32,768 tokens..."

# Creamos el directorio de configuración si no existe
sudo mkdir -p /etc/systemd/system/ollama.service.d

# Creamos el archivo de override para inyectar la variable de entorno
cat <<EOF | sudo tee /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_NUM_CTX=32768"
EOF

# Recargamos systemd y reiniciamos el servicio para aplicar cambios
sudo systemctl daemon-reload
sudo systemctl restart ollama

echo "✅ Contexto ampliado y servicio reiniciado."

# 4. Instalación de OpenCode.ai
echo "🤖 Instalando OpenCode.ai (Software Libre de IA)..."
if curl -fsSL https://opencode.ai/install | bash; then
    echo "✅ OpenCode.ai instalado correctamente."
else
    echo "❌ Falló la instalación de OpenCode.ai."
    # No detenemos el script aquí por si el resto de herramientas son funcionales
fi

# 5. Configuración de Neovim para integrar OpenCode
echo "🧩 Vinculando OpenCode con Neovim..."
mkdir -p ~/.config/nvim

# Sobrescribimos o creamos el init.lua para que use el plugin oficial
cat <<EOF > ~/.config/nvim/init.lua
-- Instalación automática de Lazy.nvim (gestor de plugins)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "is0n/opencode.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("opencode").setup({
        provider = "ollama",
        model = "qwen2.5-coder", -- Recomendado para transformación digital sanitaria por su precisión
      })
    end
  },
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 }
})

-- Configuraciones básicas de UI
vim.cmd.colorscheme "catppuccin"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
EOF


# 6. Optimización de la experiencia en terminal (Bash History Search)
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

echo "✨ Proceso finalizado."
echo "Recarga tu terminal con: source ~/.bashrc"
