# kak-lsp is optional at startup so Kakoune still opens if it is not installed.
# Signature help stays manual, matching helix auto-signature-help = false.
# Word completion is Kakoune's <c-n> / <c-x>w, so simple-completion-language-server
# is not wired up.

declare-option bool kak_lsp_loaded false

hook global GlobalSetOption kak_lsp_loaded=true %|
    lsp-enable
    try %{ lsp-auto-signature-help-disable }
    try %{ lsp-inline-diagnostics-enable global }
    try %{ lsp-diagnostic-lines-enable global }
    try %{ lsp-inlay-diagnostics-enable global }
    try %{ set-option global lsp_hover_anchor true }
    try %{ set-option global lsp_insert_spaces true }
    set-option global modelinefmt '{{mode_info}} %opt{modeline_git} %val{bufname} %val{cursor_line}:%val{cursor_char_column} {{context_info}} %opt{lsp_modeline} {Error}%opt{lsp_diagnostic_error_count}{Default}/{Information}%opt{lsp_diagnostic_warning_count}'
    source "%val{config}/lsp-servers.kak"
    map global insert <tab> '<a-;>:try lsp-snippets-select-next-placeholders catch %{ execute-keys -with-hooks <lt>tab> }<ret>' -docstring 'next snippet placeholder'
|

try %{
    evaluate-commands %sh{ kak-lsp --kakoune -s "$kak_session" }
    set-option global kak_lsp_loaded true
} catch %{
    echo -debug 'kak-lsp is not installed; LSP, inline diagnostics, and gd/gr stay unavailable'
}
