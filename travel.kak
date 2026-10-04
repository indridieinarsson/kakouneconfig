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
map global user e ':project-file<ret>' -docstring 'open project file'
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

# Filetypes of buffers whose lines are `file:line:col:text` locations: the LSP
# location lists and the *grep* buffer (grep-word and friends).
declare-option -hidden str goto_preview_filetypes 'lsp-goto|lsp-document-symbol|grep'
declare-option -hidden bool goto_preview_paused false

# Preview the location under the cursor in such a list: in a split client
# (zellij, tmux, wezterm) when there is one, else an info popup.
define-command -override -hidden goto-preview -docstring 'preview the location list entry under the cursor' %@
    evaluate-commands %sh{ [ "$kak_opt_goto_preview_paused" = true ] && echo "fail 'preview paused'" }
    evaluate-commands -save-regs a %{
        set-register a ''
        try %{ execute-keys -draft %{%s<space>┈+$<ret>d} }
        evaluate-commands -draft %{
            try %{
                execute-keys x
                set-register a %val{selection}
            }
        }
        evaluate-commands %sh{
            line=$(printf '%s' "$kak_reg_a" | tr -d '\r')
            line=${line%$'\n'}
            style=above
            [ "${kak_cursor_line:-1}" -le 8 ] && style=below
            split=
            if [ -n "$kak_client_env_ZELLIJ_SESSION_NAME" ] && [ "$kak_opt_fzf_zellij_session" != off ]; then split=zellij
            elif [ -n "$TMUX" ] && command -v tmux >/dev/null 2>&1; then split=tmux
            elif [ -n "$WEZTERM_PANE" ] && command -v wezterm >/dev/null 2>&1; then split=wezterm
            fi
            clear() { [ -n "$split" ] || printf 'info\n'; exit 0; }

            . "$kak_config/tools/goto-location.sh" || clear

            title="$shown:$lineno:$col"
            obrace=$(printf '\173')
            title=$(printf '%s' "$title" | sed -e 's/\\/\\\\/g' -e "s/$obrace/\\\\$obrace/g")

            if [ -n "$split" ]; then
                [ -f "$file" ] || exit 0
                kcmd="edit -existing $(q "$file") $lineno $col; execute-keys xvc"
                case " $kak_client_list " in
                    *" preview "*)
                        printf 'evaluate-commands -client preview %s\n' "$(q "$kcmd")"
                        ;;
                    *)
                        init="rename-client preview; $kcmd"
                        if [ "$split" = zellij ]; then
                            printf 'try %%{ zellij-pane -b -n preview -x 45%% -y 15%% -w 45%% -h 70%% -- kak -c %s -e %s }\n' \
                                "$(q "$kak_session")" "$(q "$init")"
                        elif [ "$split" = tmux ]; then
                            tmux split-window -d -h -l 45% kak -c "$kak_session" -e "$init" >/dev/null 2>&1
                        else
                            wezterm cli split-pane --right --percent 45 -- kak -c "$kak_session" -e "$init" >/dev/null 2>&1
                            wezterm cli activate-pane --pane-id "$WEZTERM_PANE" >/dev/null 2>&1
                        fi
                        ;;
                esac
                exit 0
            fi

            # Dotted leader from the end of the line to the right edge; the popup
            # anchors at its last cell, so Kakoune shifts it flush right.
            bytes=$(printf '%s' "$line" | LC_ALL=C wc -c)
            chars=$(printf '%s' "$line" | LC_ALL=C.UTF-8 wc -m)
            n=$(( ${kak_window_width:-80} - chars - 20 ))
            anchorcol=$bytes
            if [ "$n" -ge 3 ]; then
                leader=$(printf '%*s' "$n" '' | sed 's/ /┈/g')
                printf "execute-keys -draft 'gla<space>%s<esc>'\n" "$leader"
                anchorcol=$(( bytes + 2 + (n - 1) * 3 ))
            fi

            if [ ! -f "$file" ]; then
                body="{Information}not on disk
{\}$snippet"
                printf 'info -markup -anchor %s.%s -style %s -title %s -- %s\n' \
                    "$kak_cursor_line" "$anchorcol" "$style" "$(q "$title")" "$(q "$body")"
                exit 0
            fi

            body=$("$kak_config/tools/goto-context" "$file" "$lineno" 2 5)
            [ -n "$body" ] || body="{Information}line $lineno is past the end of the file{\}"
            printf 'info -markup -anchor %s.%s -style %s -title %s -- %s\n' \
                "$kak_cursor_line" "$anchorcol" "$style" "$(q "$title")" "$(q "$body")"
        }
    }
@

# Hook up the in-buffer preview for the current list window.
define-command -override -hidden goto-preview-enable -docstring 'preview list entries as the cursor pauses on them' %{
    remove-hooks window goto-preview
    hook window -group goto-preview NormalIdle .* %{ try goto-preview }
    hook -once -always window WinSetOption filetype=.* %{
        remove-hooks window goto-preview
        info
    }
}

# Under zellij the list moves into two floating panes: the list itself on the
# left (a Kakoune client named "picker") and the preview on the right (the
# "preview" client that goto-preview drives). Jumps still land in this client.
define-command -override -hidden goto-picker -docstring 'show the location list in a zellij popup' %{
    zellij-pane -n picker -x 5% -y 15% -w 38% -h 70% -- kak -c %val{session} -e "
        rename-client picker
        buffer %val{bufname}
        set-option window jumpclient %val{client}
        goto-picker-setup
    "
    try %{ buffer %opt{goto_return_buffer} }
}

define-command -override -hidden goto-picker-setup -docstring 'configure the picker client' %{
    set-option window goto_preview_paused false
    goto-preview-enable
    map window normal q ': goto-picker-close<ret>' -docstring 'close picker'
    map window normal <esc> ': goto-picker-close<ret>' -docstring 'close picker'
    # Entering a result jumps (the list's own hook); then the popup is done.
    hook window NormalKey <ret> %{ set-option window goto_preview_paused true; hook -once window NormalIdle .* goto-picker-close }
}

define-command -override -hidden goto-picker-close -docstring 'close the picker and its preview' %{
    set-option window goto_preview_paused true
    try %{ evaluate-commands -client preview quit }
    quit!
}

# The buffer a list was opened from, so the picker can put it back on screen.
declare-option -hidden str goto_return_buffer
hook global WinDisplay '[^*].*' %{
    evaluate-commands %sh{
        case $kak_client in preview|picker) exit 0 ;; esac
        echo 'set-option global goto_return_buffer %val{bufname}'
    }
}

define-command -override -hidden goto-picker-arm -docstring 'open the picker once the grep fifo is complete' %{
    remove-hooks buffer goto-picker-arm
    hook -once -group goto-picker-arm buffer BufCloseFifo .* %{
        evaluate-commands %sh{
            for c in $kak_client_list; do
                case $c in preview|picker) ;; *) { echo "evaluate-commands -client $c %{ try %{ zellij-pane --check; goto-picker } }"; break; } ;; esac
            done
        }
    }
}

# Re-running grep reuses the buffer without changing its filetype, so arm again here.
hook global BufOpenFifo '\*grep\*' goto-picker-arm

hook global WinSetOption "filetype=(?:%opt{goto_preview_filetypes})" %{
    remove-hooks window goto-preview
    # Under zellij, use the picker instead of navigating the list buffer;
    # zellij-pane --check fails otherwise, falling back to the in-buffer preview.
    try %{
        zellij-pane --check
        # *grep* fills asynchronously from a fifo; other lists are ready once idle.
        try %{
            evaluate-commands %sh{ [ "$kak_opt_filetype" = grep ] || echo fail }
            goto-picker-arm
        } catch %{
            hook -once window NormalIdle .* goto-picker
        }
    } catch %{
        goto-preview-enable
    }
}

# The window hook above dies with the list's window, so close the split
# preview whenever any non-preview client shows a buffer that is not a list.
hook global WinDisplay .* %{
    evaluate-commands %sh{
        case $kak_client in preview|picker) exit 0 ;; esac
        printf '%s' "$kak_opt_filetype" | grep -qxE "$kak_opt_goto_preview_filetypes" && exit 0
        case " $kak_client_list " in
            *" preview "*) printf 'evaluate-commands -client preview quit\n' ;;
        esac
    }
}
