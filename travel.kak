# Code-travel commands. Goto-mode maps follow Kakoune's gd/gr convention.
# User-mode maps are the Helix leader keys that would otherwise clash.

declare-user-mode diagnostics

define-command -override code-definition -docstring 'jump to definition' %{
    try %{ lsp-definition } catch %{ fail 'definition jump needs kak-lsp' }
}
define-command -override code-references -docstring 'list references' %{
    try %{ lsp-references } catch %{ fail 'references need kak-lsp' }
}
define-command -override code-type-definition -docstring 'jump to type definition' %{
    try %{ lsp-type-definition } catch %{ fail 'type definition needs kak-lsp' }
}
define-command -override code-implementation -docstring 'jump to implementation' %{
    try %{ lsp-implementation } catch %{ fail 'implementation jump needs kak-lsp' }
}
define-command -override code-symbols -docstring 'jump to a symbol in this buffer' %{
    try %{ lsp-goto-document-symbol } catch %{ fail 'document symbols need kak-lsp' }
}
define-command -override code-hover -docstring 'show hover and diagnostics at the cursor' %{
    try %{ lsp-hover } catch %{ fail 'hover needs kak-lsp' }
}
define-command -override next-diagnostic -docstring 'jump to the next diagnostic' %{
    try %{ lsp-find-error } catch %{
        try %{ lint-next-message } catch %{ fail 'no diagnostics' }
    }
}
define-command -override prev-diagnostic -docstring 'jump to the previous diagnostic' %{
    try %{ lsp-find-error --previous } catch %{
        try %{ lint-previous-message } catch %{ fail 'no diagnostics' }
    }
}
define-command -override next-symbol -docstring 'go to the next symbol' %{
    try %{ lsp-next-symbol } catch %{ fail 'symbol navigation needs kak-lsp' }
}
define-command -override prev-symbol -docstring 'go to the previous symbol' %{
    try %{ lsp-previous-symbol } catch %{ fail 'symbol navigation needs kak-lsp' }
}

define-command -override alternate-header -docstring 'switch C/C++ source and header' %{
    evaluate-commands %sh{
        case "$kak_opt_filetype" in
            c|cpp|objc) ;;
            *) echo "fail 'alternate-header is for C/C++'"; exit ;;
        esac
        # clangd's switchSourceHeader finds files outside this directory.
        # Until clangd is installed, fall back to a name search.
        if command -v clangd >/dev/null 2>&1 && command -v kak-lsp >/dev/null 2>&1; then
            echo 'try %{ clangd-switch-source-header } catch %{ alternate-header-by-name }'
        else
            echo alternate-header-by-name
        fi
    }
}

define-command -override -hidden alternate-header-by-name %{
    evaluate-commands %sh{
        tool="${kak_config}/tools/alternate-header"
        err=$(mktemp)
        alt=$("$tool" "$kak_buffile" 2>"$err") || {
            msg=$(sed "s/'/''/g" "$err")
            rm -f "$err"
            printf "fail '%s'\n" "$msg"
            exit
        }
        rm -f "$err"
        quoted=$(printf '%s' "$alt" | sed "s/'/''/g")
        printf "edit -existing '%s'\n" "$quoted"
    }
}

define-command -override search-word -params 1 -docstring 'search-word next|prev: search the word at the cursor' %{
    evaluate-commands -save-regs '/' %{
        evaluate-commands %sh{
            if [ "${#kak_selection}" -le 1 ]; then
                echo "try %{ execute-keys '<a-i>w' }"
            fi
        }
        execute-keys '*'
        evaluate-commands %sh{
            if [ "$1" = prev ]; then
                echo "execute-keys '<a-n>'"
            else
                echo "execute-keys n"
            fi
        }
    }
}

define-command -override grep-word -docstring 'project-search the selection, or the word at the cursor' %{
    evaluate-commands %sh{
        if [ "${#kak_selection}" -le 1 ]; then
            echo "try %{ execute-keys '<a-i>w' }"
        fi
        echo grep
    }
}

define-command -override project-file -docstring 'open a project file' %{
    prompt -shell-script-candidates %{
        dir=${kak_buffile:-$PWD}
        dir=${dir%/*}
        [ -d "$dir" ] || dir=$PWD
        root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$dir")
        cd "$root" || exit 0
        rg --files --hidden --glob '!.git/**' --glob '!**/node_modules/**' --sortr modified \
            | sed "s|^|${root}/|"
    } 'edit %val{text}'
}

define-command -override pick-buffer -docstring 'switch buffer' %{
    prompt -buffer-completion 'buffer %val{text}'
}

define-command -override next-change -docstring 'jump to the next git hunk' %{
    try %{ git-diff-if-repo update-diff }
    git next-hunk
}
define-command -override prev-change -docstring 'jump to the previous git hunk' %{
    try %{ git-diff-if-repo update-diff }
    git prev-hunk
}

declare-option bool diag_inline true
declare-option bool diag_eol true
declare-option bool diag_flags true

define-command -override diagnostics-toggle-inline -docstring 'toggle inline diagnostic highlights' %{
    evaluate-commands %sh{
        if [ "$kak_opt_diag_inline" = true ]; then
            printf '%s\n' 'set-option global diag_inline false' \
                'try %{ lsp-inline-diagnostics-disable }' \
                "echo -markup '{Information}inline diagnostics off'"
        else
            printf '%s\n' 'set-option global diag_inline true' \
                'try %{ lsp-inline-diagnostics-enable }' \
                "echo -markup '{Information}inline diagnostics on'"
        fi
    }
}
define-command -override diagnostics-toggle-eol -docstring 'toggle end-of-line diagnostic text' %{
    evaluate-commands %sh{
        if [ "$kak_opt_diag_eol" = true ]; then
            printf '%s\n' 'set-option global diag_eol false' \
                'try %{ lsp-inlay-diagnostics-disable }' \
                "echo -markup '{Information}end-of-line diagnostics off'"
        else
            printf '%s\n' 'set-option global diag_eol true' \
                'try %{ lsp-inlay-diagnostics-enable }' \
                "echo -markup '{Information}end-of-line diagnostics on'"
        fi
    }
}
define-command -override diagnostics-toggle-flags -docstring 'toggle gutter diagnostic flags' %{
    evaluate-commands %sh{
        if [ "$kak_opt_diag_flags" = true ]; then
            printf '%s\n' 'set-option global diag_flags false' \
                'try %{ lsp-diagnostic-lines-disable }' \
                "echo -markup '{Information}diagnostic flags off'"
        else
            printf '%s\n' 'set-option global diag_flags true' \
                'try %{ lsp-diagnostic-lines-enable }' \
                "echo -markup '{Information}diagnostic flags on'"
        fi
    }
}

# Goto mode. gi, ga, gf, gh and the other built-in goto keys are not touched.
map global goto d '<esc>:code-definition<ret>' -docstring 'definition'
map global goto r '<esc>:code-references<ret>' -docstring 'references'
map global goto y '<esc>:code-type-definition<ret>' -docstring 'type definition'
map global goto I '<esc>:code-implementation<ret>' -docstring 'implementation'
map global goto s '<esc>:code-symbols<ret>' -docstring 'document symbol'
map global goto o '<esc>:alternate-header<ret>' -docstring 'source/header'
map global goto n '<esc>:next-diagnostic<ret>' -docstring 'next diagnostic'
map global goto p '<esc>:prev-diagnostic<ret>' -docstring 'previous diagnostic'
map global goto '[' '<esc>:prev-symbol<ret>' -docstring 'previous symbol'
map global goto ']' '<esc>:next-symbol<ret>' -docstring 'next symbol'

# Git hunks. <c-n>/<c-p> are free in normal mode (insert mode keeps completion).
map global normal <c-n> ':next-change<ret>' -docstring 'next git hunk'
map global normal <c-p> ':prev-change<ret>' -docstring 'previous git hunk'

# User mode. These do not override normal-mode *, @, <a-,>, <a-.>, or <a-w>.
map global user l ':try %{ enter-user-mode lsp } catch %{ fail "kak-lsp is not installed" }<ret>' -docstring 'LSP mode'
map global user h ':code-hover<ret>' -docstring 'hover'
map global user '=' ':format-smart<ret>' -docstring 'format buffer'
map global user f ':project-file<ret>' -docstring 'open project file'
map global user e ':project-file<ret>' -docstring 'open project file'
map global user b ':pick-buffer<ret>' -docstring 'pick buffer'
map global user ',' ':buffer-previous<ret>' -docstring 'previous buffer'
map global user '.' ':buffer-next<ret>' -docstring 'next buffer'
map global user q ':delete-buffer<ret>' -docstring 'close buffer'
map global user '/' ':grep-word<ret>' -docstring 'grep word'
map global user '@' ':grep-word<ret>' -docstring 'grep word'
map global user '*' ':search-word next<ret>' -docstring 'search word forward'
map global user '#' ':search-word prev<ret>' -docstring 'search word backward'
map global user B ':git blame<ret>' -docstring 'toggle git blame'
map global user L ':lint-buffer<ret>' -docstring 'external lint'
map global user i ':enter-user-mode diagnostics<ret>' -docstring 'diagnostic display'

map global diagnostics c ':diagnostics-toggle-inline<ret>' -docstring 'inline highlights'
map global diagnostics e ':diagnostics-toggle-eol<ret>' -docstring 'end-of-line text'
map global diagnostics o ':diagnostics-toggle-flags<ret>' -docstring 'gutter flags'

# LSP text objects on keys that are not already objects (a is <> , s is sentence).
map global object l '<a-semicolon>try %{ lsp-object }<ret>' -docstring 'LSP symbol'
map global object f '<a-semicolon>try %{ lsp-object Function Method }<ret>' -docstring 'LSP function'
map global object t '<a-semicolon>try %{ lsp-object Class Interface Module Namespace Struct }<ret>' -docstring 'LSP type'
map global object d '<a-semicolon>try %{ lsp-diagnostic-object error warning }<ret>' -docstring 'LSP diagnostic'
map global object D '<a-semicolon>try %{ lsp-diagnostic-object error }<ret>' -docstring 'LSP error'
