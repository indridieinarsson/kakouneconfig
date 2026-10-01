# fzf pickers via andreyorst/fzf.kak, managed by plug.kak (both vendored in plugins/).
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

    # Outside tmux, split the current wezterm pane instead of letting
    # `terminal` open a separate OS window (which can land on another workspace).
    define-command -hidden fzf-wezterm-split -params 1 %{
        evaluate-commands %sh{
            if [ -n "${kak_client_env_WEZTERM_PANE:-}" ] && command -v wezterm >/dev/null 2>&1; then
                printf "nop %%sh{ wezterm cli split-pane --bottom --percent 45 --pane-id '%s' -- '%s' </dev/null >/dev/null 2>&1 & }\n" \
                    "$kak_client_env_WEZTERM_PANE" "$1"
            else
                printf 'terminal %s\n' "$1"
            fi
        }
    }
    set-option global fzf_terminal_command 'fzf-wezterm-split'

    map global user f ': fzf-file<ret>' -docstring 'fuzzy find file'
    map global user b ': fzf-buffer<ret>' -docstring 'fuzzy switch buffer'
    map global user F ': fzf-mode<ret>' -docstring 'fzf mode (all pickers)'
}
