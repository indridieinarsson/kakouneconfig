# Kakoune config shaped after ~/.config/helix, without overriding Kakoune defaults.
#
# Leader is <space>, which already enters user mode. Helix keys that would
# clobber core motions live here instead:
#
#   goto (code travel)
#     gd definition     gr references      gy type      gI implementation
#     gs symbols        go source/header   gn/gp next/prev diagnostic
#     g[/g] prev/next symbol
#     ga alternate buffer          <c-o>/<c-i> jump back/forward
#   normal
#     <c-n>/<c-p> next/previous git hunk
#   user (<space>)
#     l LSP menu        h hover            = format
#     f or e open file  b pick buffer      ,/. prev/next buffer    q close
#     / or @ grep word  * / # search word  B git blame
#     i diagnostic display (c inline, e end-of-line, o gutter flags)
#     L external :lint
#
# Left alone on purpose: x and <a-x> (line bounds), <a-.> (repeat motion),
# <a-,> (drop main selection), @ (tabs to spaces), * (search from selection).

source "%val{config}/travel.kak"
source "%val{config}/format.kak"
source "%val{config}/lsp.kak"

# Relative numbers, cursor line number, column 120 ruler.
add-highlighter global/numbers number-lines -relative -hlcursor -separator ' ' -min-digits 2
add-highlighter global/ruler column 120 comment

set-option global grepcmd 'rg -n --column --hidden --glob !.git --glob !**/node_modules/**'

declare-option -hidden str modeline_git ''
set-option global modelinefmt '{{mode_info}} %opt{modeline_git} %val{bufname} %val{cursor_line}:%val{cursor_char_column} {{context_info}}'

define-command -override -hidden modeline-git-update %{
    evaluate-commands %sh{
        dir=${kak_buffile%/*}
        [ -n "$kak_buffile" ] || exit 0
        branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
        branch=$(printf '%s' "$branch" | sed "s/'/''/g")
        printf "set-option window modeline_git '%%{%s}'\n" "$branch"
    }
}

# C# is not detected by the runtime. Reuse the C++ highlighter until a real one exists.
hook global BufCreate .*\.cs$ %{
    set-option buffer filetype csharp
}
hook global WinSetOption filetype=csharp %{
    require-module cpp
    try %{ remove-highlighter window/csharp }
    add-highlighter window/csharp ref cpp
    hook -once -always window WinSetOption filetype=.* %{
        try %{ remove-highlighter window/csharp }
    }
}

define-command -override -hidden git-diff-if-repo -params 1 %{
    evaluate-commands %sh{
        dir=${kak_buffile%/*}
        [ -n "$kak_buffile" ] || exit 0
        git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
        printf 'try %%{ git %s }\n' "$1"
    }
}

hook global WinCreate .* %{
    modeline-git-update
    git-diff-if-repo show-diff
    hook window -group modeline-git FocusIn .* modeline-git-update
    hook window -group modeline-git BufWritePost .* %{
        modeline-git-update
        git-diff-if-repo update-diff
    }
}

# Markdown soft-wrap, matching helix text-width 80. Typst width is for the formatter only.
hook global WinSetOption filetype=markdown %{
    try %{ remove-highlighter window/softwrap }
    add-highlighter window/softwrap wrap -word -width 80 -indent
    set-option window autowrap_column 80
    hook -once -always window WinSetOption filetype=.* %{
        try %{ remove-highlighter window/softwrap }
    }
}
hook global WinSetOption filetype=typst %{
    set-option window autowrap_column 120
}
