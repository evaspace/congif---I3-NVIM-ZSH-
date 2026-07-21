#!/usr/bin/env bash
# ==============================================================================
# Instant Tiling Desktop Environment & Terminal Bootstrapper
# Universal single-execution script for Linux (Root / Non-Root / EPITA CRI / AFS)
# ==============================================================================

set -e

echo "[+] Initializing Instant Desktop Environment Bootstrapper..."

# 1. Detect Sudo / Root privileges
HAS_SUDO=0
if command -v sudo >/dev/null 2>&1; then
    if sudo -n true 2>/dev/null || sudo -v 2>/dev/null; then
        HAS_SUDO=1
    fi
fi

PKGS_APT="zsh git curl fzf lsd eza neovim i3 i3status i3lock dex xss-lock network-manager-applet pulseaudio-utils rofi feh thunar gcc nodejs npm python3 python3-pip cargo alacritty maim xclip dunst"
PKGS_PACMAN="zsh git curl fzf lsd eza neovim i3-wm i3status i3lock dex xss-lock network-manager-applet libpulse rofi feh thunar gcc nodejs npm python python-pip rustup alacritty maim xclip dunst"
PKGS_DNF="zsh git curl fzf lsd eza neovim i3 i3status i3lock dex xss-lock network-manager-applet pulseaudio-utils rofi feh thunar gcc nodejs npm python3 python3-pip cargo alacritty maim xclip dunst"

if [ "$HAS_SUDO" -eq 1 ]; then
    echo "[+] Sudo privileges detected. Installing/updating system packages..."
    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y $PKGS_APT || true
    elif command -v pacman &>/dev/null; then
        sudo pacman -Syu --noconfirm $PKGS_PACMAN || true
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y $PKGS_DNF || true
    fi
else
    echo "[!] Sudo privileges not available. Proceeding in user-space dotfile mode..."
fi

# 2. Initialize Directory Hierarchy
mkdir -p "$HOME/.config/i3" "$HOME/.config/i3status" "$HOME/.config/nvim" "$HOME/.local/bin" "$HOME/Pictures/wallpapers"

# 3. Install Oh-My-Zsh & Zsh Plugins
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "[+] Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/themes" "$ZSH_CUSTOM/plugins"

if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    echo "[+] Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" || true
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "[+] Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" || true
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "[+] Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" || true
fi

# 4. Deploy Zsh Configuration (~/.zshrc)
cat << 'EOF' > "$HOME/.zshrc"
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf)

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
else
    PROMPT='%F{cyan}%n%f@%F{magenta}%m%f %F{blue}%~%f %F{yellow}❯%f '
fi

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

if command -v lsd &>/dev/null; then
    alias ls="lsd --group-directories-first --icon=auto --color=auto"
    alias lsh="lsd --group-directories-first --icon=always --color=auto --tree --depth=2"
else
    alias ls="ls --color=auto --group-directories-first"
fi

if command -v eza &>/dev/null; then
    alias ll="eza -lh --icons --group-directories-first --color=always"
    alias la="eza -lha --icons --group-directories-first --color=always"
else
    alias ll="ls -lh --color=auto"
    alias la="ls -la --color=auto"
fi

alias v="vim"
alias ..="cd .."
alias sd="sudo shutdown now 2>/dev/null || shutdown now"
alias rb="sudo reboot 2>/dev/null || reboot"

if command -v fastfetch &>/dev/null; then
    fastfetch
elif command -v neofetch &>/dev/null; then
    neofetch
fi

bindkey "^[[A" up-line-or-history
bindkey "^[[B" down-line-or-history
bindkey "^[[C" forward-char
bindkey "^[[D" backward-char
EOF

# 5. Deploy Vim & Neovim Configuration (~/.vimrc & ~/.config/nvim/init.lua)
cat << 'EOF' > "$HOME/.vimrc"
set number
set relativenumber
syntax on
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set mouse=a
set termguicolors
EOF

cat << 'EOF' > "$HOME/.config/nvim/init.lua"
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
            ensure_installed = { "c", "python", "lua" },
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

# 6. Deploy i3status Configuration (~/.config/i3status/config)
cat << 'EOF' > "$HOME/.config/i3status/config"
general {
    colors = true
    interval = 5
    color_good = "#5ccfe6"
    color_degraded = "#ffb000"
    color_bad = "#d32f2f"
    output_format = "i3bar"
}

order += "wireless _first_"
order += "ethernet _first_"
order += "cpu_usage"
order += "memory"
order += "volume master"
order += "tztime local"

wireless _first_ {
    format_up = " W: %ip (%essid) "
    format_down = " W: down "
}

ethernet _first_ {
    format_up = " E: %ip "
    format_down = " E: down "
}

cpu_usage {
    format = " CPU:%usage "
}

memory {
    format = " RAM:%used "
    threshold_degraded = "1G"
    format_degraded = " MEM:%free "
}

volume master {
    format = " VOL:%volume "
    format_muted = " VOL:muted "
    device = "default"
    mixer = "Master"
    mixer_idx = 0
}

tztime local {
    format = " %Y-%m-%d %H:%M:%S "
}
EOF

# 7. Deploy Status Wrapper Script (~/.config/i3/status_wrapper.py)
cat << 'EOF' > "$HOME/.config/i3/status_wrapper.py"
#!/usr/bin/env python3
import sys
import json
import os

def find_hwmon_by_name(name):
    try:
        hwmon_dir = '/sys/class/hwmon'
        if os.path.exists(hwmon_dir):
            for h in os.listdir(hwmon_dir):
                name_file = f'{hwmon_dir}/{h}/name'
                if os.path.isfile(name_file):
                    with open(name_file, 'r') as f:
                        if name in f.read():
                            return f'{hwmon_dir}/{h}'
    except Exception:
        pass
    return None

def get_cpu_temp():
    try:
        hwmon_dir = '/sys/class/hwmon'
        if os.path.exists(hwmon_dir):
            for h in os.listdir(hwmon_dir):
                temp_file = f'{hwmon_dir}/{h}/temp1_input'
                if os.path.isfile(temp_file):
                    with open(temp_file, 'r') as f:
                        return f"{int(f.read().strip()) // 1000}°C"
    except Exception:
        pass
    return None

def main():
    try:
        header = sys.stdin.readline()
        if header: sys.stdout.write(header)
        bracket = sys.stdin.readline()
        if bracket: sys.stdout.write(bracket)
    except Exception:
        return

    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                break
            prefix = ""
            if line.startswith(','):
                prefix = ','
                line = line[1:]
            
            data = json.loads(line)
            temp = get_cpu_temp()
            if temp:
                for block in data:
                    if block.get('name') == 'cpu_usage':
                        block['full_text'] = f" CPU:{block['full_text'].replace('CPU:','').strip()} {temp} "
            sys.stdout.write(prefix + json.dumps(data) + '\n')
            sys.stdout.flush()
        except Exception:
            try:
                sys.stdout.write(line)
                sys.stdout.flush()
            except Exception:
                break

if __name__ == "__main__":
    main()
EOF

# 8. Deploy Lock Script (~/.config/i3/lock.sh)
cat << 'EOF' > "$HOME/.config/i3/lock.sh"
#!/bin/bash
if command -v i3lock >/dev/null 2>&1; then
    WALLPAPER="$HOME/Pictures/wallpapers/wallpaperlock.jpg"
    if [ -f "$WALLPAPER" ]; then
        i3lock -i "$WALLPAPER" -c 1e1e24
    else
        i3lock -c 1e1e24
    fi
fi
EOF

chmod +x "$HOME/.config/i3/status_wrapper.py" "$HOME/.config/i3/lock.sh" 2>/dev/null || true

# 9. Deploy i3 Configuration (~/.config/i3/config)
cat << 'EOF' > "$HOME/.config/i3/config"
set $m Mod4
font pango:monospace 10

set $bg #1e1e24
set $ia #3a3a45
set $tx #eaeaea
set $ac #5ccfe6
set $ur #d32f2f

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

exec --no-startup-id command -v dex >/dev/null && dex --autostart --environment i3
exec --no-startup-id command -v nm-applet >/dev/null && nm-applet
exec_always --no-startup-id command -v picom >/dev/null && picom -b
exec_always --no-startup-id command -v autotiling >/dev/null && autotiling
exec --no-startup-id command -v dunst >/dev/null && dunst
exec --no-startup-id command -v numlockx >/dev/null && numlockx on

floating_modifier $m
tiling_drag modifier titlebar
default_border pixel 1
default_floating_border pixel 1
gaps inner 0
gaps outer 0

for_window [class="Thunar"] floating enable, resize set 1100 px 450 px, move position center
for_window [window_role="pop-up"] floating enable
for_window [window_role="task_dialog"] floating enable
for_window [window_type="dialog"] floating enable
for_window [window_type="menu"] floating enable
for_window [class="Pavucontrol"] floating enable, sticky enable, move position center
for_window [class="Lxappearance"] floating enable
for_window [class="SpeedCrunch"] floating enable

client.focused          $ac $ac $bg $ac $ac
client.focused_inactive $ia $ia $tx $ia $ia
client.unfocused        $ia $bg $tx $ia $ia
client.urgent           $ur $ur $tx $ur $ur
client.placeholder      $ia $ia $tx $ia $ia
client.background       $bg

bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10% && $ri
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10% && $ri
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && $ri
bindsym XF86AudioMicMute exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && $ri

bindsym XF86AudioPlay exec playerctl play-pause 2>/dev/null
bindsym XF86AudioNext exec playerctl next 2>/dev/null
bindsym XF86AudioPrev exec playerctl previous 2>/dev/null
bindsym XF86AudioStop exec playerctl stop 2>/dev/null

bindsym $m+Return exec alacritty || i3-sensible-terminal || gnome-terminal || xterm
bindsym $m+Shift+Q kill
bindsym $m+d exec --no-startup-id rofi -show drun -show-icons || dmenu_run
bindsym $m+Shift+x exec --no-startup-id ~/.config/i3/lock.sh

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

bindsym $m+Shift+u move scratchpad
bindsym $m+u scratchpad show

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

bar {
        status_command i3status -c ~/.config/i3status/config | python3 ~/.config/i3/status_wrapper.py 2>/dev/null || i3status -c ~/.config/i3status/config
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

bindsym Print exec --no-startup-id maim -s | xclip -selection clipboard -t image/png && dunstify 'Screenshot' 'Captured to clipboard' 2>/dev/null || true
bindsym Mod4+Print exec --no-startup-id maim ~/Pictures/$(date +%Y-%m-%d_%H-%M-%S).png && dunstify 'Screenshot' 'Saved to Pictures' 2>/dev/null || true
EOF

# 10. Switch Default Shell to Zsh
if [ "$SHELL" != "$(which zsh 2>/dev/null)" ] && command -v zsh >/dev/null 2>&1; then
    if [ "$HAS_SUDO" -eq 1 ]; then
        sudo chsh -s "$(which zsh)" "$(whoami)" 2>/dev/null || chsh -s "$(which zsh)" 2>/dev/null || true
    else
        chsh -s "$(which zsh)" 2>/dev/null || true
    fi
fi

echo "[+] Deployment complete! Reloading i3 / launching Zsh..."
if command -v i3-msg >/dev/null 2>&1; then
    i3-msg restart 2>/dev/null || true
fi
EOF
