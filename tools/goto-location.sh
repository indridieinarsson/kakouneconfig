# Sourced (not executed) by the goto preview and picker: parse a location
# list line ($line, as `file:line:col:text`) into $shown $lineno $col $snippet
# and $file (resolved to a path). Returns 1 if the line is not a location.
# Also defines q, which single-quotes its argument for Kakoune.
# Reads kak_opt_lsp_buffile and kak_opt_lsp_project_root from the environment.
q() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

case $line in
    *:*) ;;
    *) return 1 ;;
esac
shown=${line%%:*}
shown=${shown#"${shown%%[![:space:]]*}"}
rest=${line#*:}
lineno=${rest%%:*}
rest=${rest#*:}
col=${rest%%:*}
snippet=${rest#*:}
file=$shown
case $lineno in
    ''|*[!0-9]*) return 1 ;;
esac
case $col in
    *[!0-9]*) col=1 ;;
esac
[ -n "$col" ] || col=1

if [ "$file" = "%" ]; then
    file=$kak_opt_lsp_buffile
elif [ "${file#/}" = "$file" ] && [ -f "${kak_opt_lsp_project_root}${file}" ]; then
    file="${kak_opt_lsp_project_root}${file}"
fi
return 0
