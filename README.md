# congif---I3-NVIM-ZSH-

# Instant Tiling Environment Bootstrapper

## Overview
This project provides a single-execution bootstrap payload designed to deploy a complete, hyper-focused, and keyboard-centric Linux desktop environment in seconds. It bypasses step-by-step configuration in favor of immediate deployment, prioritizing absolute time-to-efficiency over granular system configuration. 

## Core Architecture
The payload automates the installation and configuration of the following stack:
* **Window Manager:** `i3wm` (minimalist, tiling window management)
* **Terminal Environment:** `zsh` + `oh-my-zsh` + `powerlevel10k` + `starship`
* **Editor:** `neovim` (pre-configured with `lazy.nvim`, Treesitter, and LSP for C/Python)
* **System Utilities:** `rofi`, `feh`, `lsd`, `eza`, `fzf`

## Deployment
Copy and paste the execution block directly into your terminal. The script will automatically detect your host system's package manager (`apt`, `pacman`, or `dnf`), resolve all necessary binary dependencies, write the configurations to your local `~/.config` directories, and restart your shell instance.

## if nixos is dead : Ctrl + Alt + F3
```bash
rm /afs/cri.epita.fr/user/m/mo/morgan.pierrefeu/u/.confs/config/i3/config
```
```bash
if command -v apt &> /dev/null; then
    sudo apt update && sudo apt install -y zsh git curl fzf lsd eza neovim i3 i3status i3lock dex xss-lock network-manager-applet pulseaudio-utils rofi feh thunar gcc nodejs npm python3 python3-pip cargo figlet lolcat
elif command -v pacman &> /dev/null; then
    sudo pacman -Syu --noconfirm zsh git curl fzf lsd eza neovim i3-wm i3status i3lock dex xss-lock network-manager-applet libpulse rofi feh thunar gcc nodejs npm python python-pip rustup figlet lolcat
elif command -v dnf &> /dev/null; then
    sudo dnf install -y zsh git curl fzf lsd eza neovim i3 i3status i3lock dex xss-lock network-manager-applet pulseaudio-utils rofi feh thunar gcc nodejs npm python3 python3-pip cargo figlet lolcat
else
    exit 1
fi

mkdir -p ~/.config/nvim ~/.config/i3status ~/.config/i3
[ ! -d "$HOME/.oh-my-zsh" ] && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
curl -sS https://starship.rs/install.sh | sh -s -- -y

cat << 'EOF' > ~/.zshrc
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf)
source $ZSH/oh-my-zsh.sh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export PATH="$HOME/.cargo/bin:$PATH"
alias ls="lsd --group-directories-first --icon=auto --color=auto"
alias ll="eza -lh --icons --group-directories-first --color=always"
alias la="eza -lha --icons --group-directories-first --color=always"
alias sd="sudo shutdown now"
alias rb="sudo reboot"
alias lsh="lsd --group-directories-first --icon=always --color=auto --tree --depth=2"
eval "$(starship init zsh)"
if command -v fastfetch &>/dev/null; then
    fastfetch
elif command -v neofetch &>/dev/null; then
    neofetch
fi
if command -v figlet &>/dev/null && command -v lolcat &>/dev/null; then
    figlet -f slant "DEDSEC" | lolcat -a -d 5
fi
bindkey "^[[A" up-line-or-history
bindkey "^[[B" down-line-or-history
bindkey "^[[C" forward-char
bindkey "^[[D" backward-char
alias file="thunar > /dev/null 2>&1 &"
alias gdrive="thunar network:// > /dev/null 2>&1 &"
EOF

cat << 'EOF' > ~/.config/nvim/init.lua
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.clipboard = "unnamedplus"
local lzPt = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lzPt) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lzPt,
    })
end
vim.opt.rtp:prepend(lzPt)
require("lazy").setup({
    {
        "navarasu/onedark.nvim",
        priority = 1000,
        config = function()
            require("onedark").setup({ style = "darker" })
            require("onedark").load()
        end
    },
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        main = "nvim-treesitter.configs",
        opts = {
            ensure_installed = { "c", "python" },
            highlight = { enable = true },
        }
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-nvim-lsp",
            "L3MON4D3/LuaSnip"
        },
        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup({
                ensure_installed = { "clangd", "pyright" },
            })
            local ca = require("cmp")
            ca.setup({
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body)
                    end,
                },
                mapping = ca.mapping.preset.insert({
                    ['<C-n>'] = ca.mapping.select_next_item(),
                    ['<C-p>'] = ca.mapping.select_prev_item(),
                    ['<C-Space>'] = ca.mapping.complete(),
                    ['<CR>'] = ca.mapping.confirm({ select = true }),
                }),
                sources = ca.config.sources({
                    { name = 'nvim_lsp' },
                })
            })
            local lc = require("lspconfig")
            local cp = require('cmp_nvim_lsp').default_capabilities()
            lc.clangd.setup({ capabilities = cp })
            lc.pyright.setup({ capabilities = cp })
        end
    }
})
EOF

cat << 'EOF' > ~/.config/i3status/config
general {
        colors = true
        interval = 5
}
order += "cpu_usage"
order += "memory"
order += "wireless wlp0s20f3"
order += "battery BAT0"
order += "tztime local"
cpu_usage {
        format = "%usage"
}
memory {
        format = "%used"
        threshold_degraded = "10%"
}
wireless wlp0s20f3 {
        format_up = "W: %ip"
        format_down = "W: DOWN"
}
battery BAT0 {
        format = "%status %percentage"
}
tztime local {
        format = "%H:%M"
}
EOF

cat << 'EOF' > ~/.config/i3/config
set $m Mod4
font pango:monospace 10
exec --no-startup-id dex --autostart --environment i3
exec --no-startup-id xss-lock --transfer-sleep-lock -- i3lock --nofork
exec --no-startup-id nm-applet
set $ri killall -SIGUSR1 i3status
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10% && $ri
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10% && $ri
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && $ri
bindsym XF86AudioMicMute exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && $ri
floating_modifier $m
tiling_drag modifier titlebar
bindsym $m+Return exec gnome-terminal
bindsym $m+Shift+Q kill
bindsym $m+d exec --no-startup-id rofi -show drun -show-icons
bindsym $m+j focus left
bindsym $m+k focus down
bindsym $m+l focus up
bindsym $m+semicolon focus right
bindsym $m+Left focus left
bindsym $m+Down focus down
bindsym $m+Up focus up
bindsym $m+Right focus right
bindsym $m+Shift+j move left
bindsym $m+Shift+k move down
bindsym $m+Shift+l move up
bindsym $m+Shift+colon move right
bindsym $m+Shift+Left move left
bindsym $m+Shift+Down move down
bindsym $m+Shift+Up move up
bindsym $m+Shift+Right move right
bindsym $m+h split h
bindsym $m+v split v
bindsym $m+f fullscreen toggle
bindsym $m+s layout stacking
bindsym $m+w layout tabbed
bindsym $m+e layout toggle split
bindsym $m+Shift+space floating toggle
bindsym $m+space focus mode_toggle
bindsym $m+a focus parent
set $w1 "1"
set $w2 "2"
set $w3 "3"
set $w4 "4"
set $w5 "5"
set $w6 "6"
set $w7 "7"
set $w8 "8"
set $w9 "9"
set $w0 "10"
bindsym $m+1 workspace number $w1
bindsym $m+2 workspace number $w2
bindsym $m+3 workspace number $w3
bindsym $m+4 workspace number $w4
bindsym $m+5 workspace number $w5
bindsym $m+6 workspace number $w6
bindsym $m+7 workspace number $w7
bindsym $m+8 workspace number $w8
bindsym $m+9 workspace number $w9
bindsym $m+0 workspace number $w0
bindsym $m+Shift+1 move container to workspace number $w1
bindsym $m+Shift+2 move container to workspace number $w2
bindsym $m+Shift+3 move container to workspace number $w3
bindsym $m+Shift+4 move container to workspace number $w4
bindsym $m+Shift+5 move container to workspace number $w5
bindsym $m+Shift+6 move container to workspace number $w6
bindsym $m+Shift+7 move container to workspace number $w7
bindsym $m+Shift+8 move container to workspace number $w8
bindsym $m+Shift+9 move container to workspace number $w9
bindsym $m+Shift+0 move container to workspace number $w0
bindsym $m+Shift+c reload
bindsym $m+Shift+r restart
bindsym $m+Shift+e exec "i3-nagbar -t warning -m 'Exit i3?' -B 'Yes' 'i3-msg exit'"
mode "r" {
        bindsym j resize shrink width 10 px or 10 ppt
        bindsym k resize grow height 10 px or 10 ppt
        bindsym l resize shrink height 10 px or 10 ppt
        bindsym semicolon resize grow width 10 px or 10 ppt
        bindsym Left resize shrink width 10 px or 10 ppt
        bindsym Down resize grow height 10 px or 10 ppt
        bindsym Up resize shrink height 10 px or 10 ppt
        bindsym Right resize grow width 10 px or 10 ppt
        bindsym Return mode "default"
        bindsym Escape mode "default"
        bindsym $m+r mode "default"
}
bindsym $m+r mode "r"
set $bg #181a1f
set $ia #282c34
set $tx #d4d8e0
set $ac #61afef
set $ur #e06c75
default_border pixel 1
default_floating_border pixel 1
gaps inner 0
gaps outer 0
client.focused          $ac $ac $bg $ac $ac
client.focused_inactive $ia $ia $tx $ia $ia
client.unfocused        $ia $bg $tx $ia $ia
client.urgent           $ur $ur $tx $ur $ur
client.placeholder      $ia $ia $tx $ia $ia
client.background       $bg
bar {
        status_command i3status -c ~/.config/i3status/config
        position top
        colors {
                background $bg
                statusline $tx
                separator  $ia
                focused_workspace  $ac $ac $bg
                active_workspace   $ia $ia $tx
                inactive_workspace $bg $bg $tx
                urgent_workspace   $ur $ur $tx
                binding_mode       $ur $ur $tx
        }
}
exec_always feh --bg-fill ~/Pictures/wallpapers/wallpaper.png
bindsym $m+Shift+x exec i3lock -i ~/Pictures/wallpapers/wallpaperlock.jpg
assign [class="Google-chrome"] $w3
assign [class="Code"] $w1
for_window [class="Thunar"] floating enable
exec --no-startup-id ~/.config/i3/w1_init.sh
EOF

sudo chsh -s $(which zsh) $(whoami)
i3-msg restart && exec zsh

```




# it was the old, here is the new one : 


```bash 
cat << 'EOF' > /afs/cri.epita.fr/user/m/mo/morgan.pierrefeu/u/.confs/config/i3/config
set $m Mod4
font pango:monospace 10

set $bg #0b101a
set $ia #1a2b3c
set $tx #e0e6ed
set $ac #ff8c00
set $ur #ff3300

set $w1 "1"
set $w2 "2"
set $w3 "3"
set $w4 "4"
set $w5 "5"
set $w6 "6"
set $w7 "7"
set $w8 "8"
set $w9 "9"
set $w0 "10"

set $ri killall -SIGUSR1 i3status

floating_modifier $m
tiling_drag modifier titlebar
default_border pixel 1
default_floating_border pixel 1
gaps inner 0
gaps outer 0

client.focused          $ac $ac $bg $ac $ac
client.focused_inactive $ia $ia $tx $ia $ia
client.unfocused        $ia $bg $tx $ia $ia
client.urgent           $ur $ur $tx $ur $ur
client.placeholder      $ia $ia $tx $ia $ia
client.background       $bg

for_window [class="Thunar"] floating enable

bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10% && $ri
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10% && $ri
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && $ri
bindsym XF86AudioMicMute exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && $ri

bindsym $m+Return exec i3-sensible-terminal
bindsym $m+Shift+Q kill
bindsym $m+d exec dmenu_run

bindsym $m+j focus left
bindsym $m+k focus down
bindsym $m+l focus up
bindsym $m+semicolon focus right
bindsym $m+Left focus left
bindsym $m+Down focus down
bindsym $m+Up focus up
bindsym $m+Right focus right

bindsym $m+Shift+j move left
bindsym $m+Shift+k move down
bindsym $m+Shift+l move up
bindsym $m+Shift+colon move right
bindsym $m+Shift+Left move left
bindsym $m+Shift+Down move down
bindsym $m+Shift+Up move up
bindsym $m+Shift+Right move right

bindsym $m+h split h
bindsym $m+v split v
bindsym $m+f fullscreen toggle
bindsym $m+s layout stacking
bindsym $m+w layout tabbed
bindsym $m+e layout toggle split
bindsym $m+Shift+space floating toggle
bindsym $m+space focus mode_toggle
bindsym $m+a focus parent

bindsym $m+1 workspace number $w1
bindsym $m+2 workspace number $w2
bindsym $m+3 workspace number $w3
bindsym $m+4 workspace number $w4
bindsym $m+5 workspace number $w5
bindsym $m+6 workspace number $w6
bindsym $m+7 workspace number $w7
bindsym $m+8 workspace number $w8
bindsym $m+9 workspace number $w9
bindsym $m+0 workspace number $w0

bindsym $m+Shift+1 move container to workspace number $w1
bindsym $m+Shift+2 move container to workspace number $w2
bindsym $m+Shift+3 move container to workspace number $w3
bindsym $m+Shift+4 move container to workspace number $w4
bindsym $m+Shift+5 move container to workspace number $w5
bindsym $m+Shift+6 move container to workspace number $w6
bindsym $m+Shift+7 move container to workspace number $w7
bindsym $m+Shift+8 move container to workspace number $w8
bindsym $m+Shift+9 move container to workspace number $w9
bindsym $m+Shift+0 move container to workspace number $w0

bindsym $m+Shift+c reload
bindsym $m+Shift+r restart
bindsym $m+Shift+e exec "i3-nagbar -t warning -m 'Exit i3?' -B 'Yes' 'i3-msg exit'"

mode "r" {
        bindsym j resize shrink width 10 px or 10 ppt
        bindsym k resize grow height 10 px or 10 ppt
        bindsym l resize shrink height 10 px or 10 ppt
        bindsym semicolon resize grow width 10 px or 10 ppt
        bindsym Left resize shrink width 10 px or 10 ppt
        bindsym Down resize grow height 10 px or 10 ppt
        bindsym Up resize shrink height 10 px or 10 ppt
        bindsym Right resize grow width 10 px or 10 ppt
        bindsym Return mode "default"
        bindsym Escape mode "default"
        bindsym $m+r mode "default"
}
bindsym $m+r mode "r"

exec_always --no-startup-id feh --bg-fill /afs/cri.epita.fr/user/m/mo/morgan.pierrefeu/u/Pictures/wallpapers/spacestatoinperfect.jpg
bindsym $m+Shift+x exec i3lock -i /afs/cri.epita.fr/user/m/mo/morgan.pierrefeu/u/Pictures/wallpapers/wallpaperlock.jpg

bar {
        status_command i3status -c ~/.confs/config/i3status/config
        position top
        colors {
                background $bg
                statusline $tx
                separator  $ia
                focused_workspace  $ac $ac $bg
                active_workspace   $ia $ia $tx
                inactive_workspace $bg $bg $tx
                urgent_workspace   $ur $ur $tx
                binding_mode       $ur $ur $tx
        }
}
EOF
#fix vim
unalias vim 2>/dev/null
sed -i '/alias vim=/d' ~/.bashrc ~/.bash_aliases 2>/dev/null
sed -i '/alias vi=/d' ~/.bashrc ~/.bash_aliases 2>/dev/null
echo 'export EDITOR="vim"' >> ~/.bashrc
source ~/.bashrc







