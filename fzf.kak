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

# Two topologies are supported:
#
#   * zellij running natively in Linux -- the script runs directly in the pane.
#
#   * zellij running on the Windows side with panes that re-enter WSL (a
#     default_shell of ubuntu.cmd, i.e. wsl.exe). There the Linux `zellij`
#     binary is a *different installation* that cannot see or control the
#     Windows sessions at all, so `zellij.exe` has to be driven instead, and
#     the pane command must go back through wsl.exe to reach the script.
#     That also needs ubuntu.cmd to forward ZELLIJ_SESSION_NAME via WSLENV,
#     otherwise nothing in WSL can tell which session it belongs to.
#
# Whichever binary actually knows the session wins, so this self-configures.
define-command -hidden -params 1 fzf-zellij-terminal %{
    evaluate-commands %sh{
        script="$1"                 # save before the helper shadows $1
        session="${kak_opt_fzf_zellij_session}"
        case "$session" in
            off|'') session= ;;
            auto)   session="${kak_client_env_ZELLIJ_SESSION_NAME:-}" ;;
        esac

        # Does zellij binary $1 report $2 as a live (non-exited) session?
        knows() {
            command -v "$1" >/dev/null 2>&1 || return 1
            "$1" list-sessions --no-formatting 2>/dev/null \
                | grep -v '(EXITED' | awk 'NF {print $1}' | grep -qxF "$2"
        }

        if [ -z "$session" ]; then
            printf 'fzf-wezterm-split %%{%s}\n' "$script"
        elif knows zellij "$session"; then
            zellij --session "$session" run \
                --floating --close-on-exit --name fzf \
                --width "${kak_opt_fzf_zellij_width}" \
                --height "${kak_opt_fzf_zellij_height}" \
                -- "$script" </dev/null >/dev/null 2>&1
        elif knows zellij.exe "$session"; then
            zellij.exe --session "$session" run \
                --floating --close-on-exit --name fzf \
                --width "${kak_opt_fzf_zellij_width}" \
                --height "${kak_opt_fzf_zellij_height}" \
                -- wsl.exe -d "${WSL_DISTRO_NAME:-Ubuntu}" -- "$script" \
                </dev/null >/dev/null 2>&1
        else
            # No zellij session we can address (and not tmux, which fzf.kak
            # handles itself): wezterm split if in wezterm, else a separate terminal window.
            printf 'fzf-wezterm-split %%{%s}\n' "$script"
        fi
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
