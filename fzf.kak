# fzf pickers via andreyorst/fzf.kak, managed by plug.kak (both vendored in plugins/).

# Where the picker is drawn.
#
# fzf.kak only special-cases tmux: inside tmux it shells out to `tmux popup`,
# and otherwise it falls back to fzf_terminal_command -- of which it uses only
# the FIRST WORD, appending the path of the script it generated. So pointing
# that option at a one-word command of our own is the whole integration point;
# the plugin itself needs no patching.
#
# Declared before `plug` below, because the plug config block runs while the
# plugin loads and could not otherwise see these.
declare-option -docstring 'width of the zellij floating pane used for fzf pickers' \
    str fzf_zellij_width '80%'
declare-option -docstring 'height of the zellij floating pane used for fzf pickers' \
    str fzf_zellij_height '70%'

# Which zellij session the picker opens in:
#   auto     the session named by $ZELLIJ_SESSION_NAME (default)
#   off      never use zellij; use the wezterm split or a separate terminal window
#   <name>   always use the named session
declare-option -docstring 'zellij session for fzf pickers: auto, off, or a session name' \
    str fzf_zellij_session 'auto'

# Outside zellij and tmux, split the current wezterm pane instead of letting
# `terminal` open a separate OS window (which can land on another workspace).
# Falls back to `terminal` when not running in wezterm.
define-command -hidden -params 1 fzf-wezterm-split %{
    evaluate-commands %sh{
        if [ -n "${kak_client_env_WEZTERM_PANE:-}" ] && command -v wezterm >/dev/null 2>&1; then
            printf "nop %%sh{ wezterm cli split-pane --bottom --percent 45 --pane-id '%s' -- '%s' </dev/null >/dev/null 2>&1 & }\n" \
                "$kak_client_env_WEZTERM_PANE" "$1"
        else
            printf 'terminal %%{%s}\n' "$1"
        fi
    }
}

# Open a command in a floating zellij pane; arguments as for tools/zellij-pane
# (`zellij-pane --check` just tests that zellij is usable). Fails if it is not.
# The shell refers to the variables the script reads, so Kakoune exports them.
define-command -hidden -params 1.. zellij-pane %{
    evaluate-commands %sh{
        : "$kak_client_env_ZELLIJ_SESSION_NAME" "$kak_opt_fzf_zellij_session"
        "$kak_config/tools/zellij-pane" "$@" || echo "fail 'no usable zellij session'"
    }
}

define-command -hidden -params 1 fzf-zellij-terminal %{
    try %{
        zellij-pane -n fzf -w %opt{fzf_zellij_width} -h %opt{fzf_zellij_height} -- %arg{1}
    } catch %{
        fzf-wezterm-split %arg{1}
    }
}

source "%val{config}/plugins/plug.kak/rc/plug.kak"
plug "andreyorst/plug.kak" noload
plug "andreyorst/fzf.kak" config %{
    require-module fzf
    require-module fzf-file
    require-module fzf-grep
    require-module fzf-buffer

    # The built-in "rg" preset walks .git/, so spell the command out.
    set-option global fzf_file_command "rg -L --hidden --files --glob '!.git/'"
    set-option global fzf_grep_command "rg"
    set-option global fzf_highlight_command "cat {}"
    set-option global fzf_grep_preview_command "cat"
    set-option global fzf_default_opts "--layout=reverse --info=inline"

    # Centred popup inside tmux.
    set-option global fzf_tmux_popup true
    set-option global fzf_tmux_height '70%'
    set-option global fzf_tmux_popup_width '80%'

    # Zellij floating pane under zellij, else wezterm split, else a terminal window.
    set-option global fzf_terminal_command 'fzf-zellij-terminal'

    map global user f ': fzf-file<ret>' -docstring 'fuzzy find file'
    map global user b ': fzf-buffer<ret>' -docstring 'fuzzy switch buffer'
    map global user F ': fzf-mode<ret>' -docstring 'fzf mode (all pickers)'
}
