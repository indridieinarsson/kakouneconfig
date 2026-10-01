# kak-tree-sitter is optional at startup so Kakoune still opens if it is not installed.
# It supplies syntax highlighting and tree-sitter text objects.

declare-option bool kts_loaded false

try %{
    evaluate-commands %sh{
        command -v kak-tree-sitter >/dev/null 2>&1 || { echo fail; exit 0; }
        kak-tree-sitter --daemonize \
            --server \
            --kakoune \
            --init "${kak_session}" \
            --with-highlighting \
            --with-text-objects
    }
    set-option global kts_loaded true
    map global user t ':enter-user-mode tree-sitter<ret>' -docstring 'tree-sitter menu'
} catch %{
    echo -debug 'kak-tree-sitter is not installed; falling back to built-in highlighters'
}
