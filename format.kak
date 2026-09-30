# External formatters, same tools as helix languages.toml.
# Format-on-write uses Kakoune's formatcmd, not the language server, so ruff /
# csharpier / typstyle / deno stay in charge. C++ is not auto-formatted.

define-command -override -hidden format-on-write -docstring 'format before write when a formatter is configured' %{
    evaluate-commands %sh{
        [ -n "$kak_opt_formatcmd" ] || exit 0
        printf '%s\n' 'try %{ format-buffer } catch %{ echo -markup "{Error}formatter failed; buffer left unchanged" }'
    }
}

define-command -override -hidden format-enable -params 1 %{
    # Store the buffer path in formatcmd. The formatter shell does not
    # otherwise see kak_buffile, so ruff/csharpier cannot find project config.
    evaluate-commands %sh{
        script=$1
        file=$kak_buffile
        q() { printf '%s' "$1" | sed -e "s/'/'\\\\''/g" -e 's/%/%%/g'; }
        # One string value: the shell command format-buffer evals.
        printf "set-option window formatcmd \"'%s' '%s'\"\n" "$(q "$script")" "$(q "$file")"
    }
    hook window -group autoformat BufWritePre .* format-on-write
    hook -once -always window WinSetOption filetype=.* %{
        remove-hooks window autoformat
        unset-option window formatcmd
    }
}

hook global WinSetOption filetype=python %{
    format-enable "%val{config}/tools/format-python"
    set-option window lintcmd "%val{config}/tools/lint-python"
}
hook global WinSetOption filetype=csharp %{
    format-enable "%val{config}/tools/format-csharp"
}
hook global WinSetOption filetype=typst %{
    format-enable "%val{config}/tools/format-typst"
}
hook global WinSetOption filetype=markdown %{
    format-enable "%val{config}/tools/format-markdown"
}

define-command -override format-smart -docstring 'format with formatcmd, or the language server if none is set' %{
    evaluate-commands %sh{
        if [ -n "$kak_opt_formatcmd" ]; then
            echo format-buffer
        else
            echo 'try %{ lsp-formatting } catch %{ fail "no formatter for this filetype" }'
        fi
    }
}
