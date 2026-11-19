fish_add_path -g ~/.local/bin
set -g fish_greeting

if status is-interactive
    starship init fish | source
end
