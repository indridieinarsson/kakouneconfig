# Kakoune config

A Helix-shaped setup for LSP, diagnostics, format-on-write, and code travel.
Shortcuts that would override Kakoune motions were moved onto goto mode (`g`)
or user mode (`<space>`). Kakoune still starts if `kak-lsp` is missing; LSP
features then fail with a short message.

Do not create `autoload/` in this directory. An empty autoload directory
shadows the system runtime.

## Dependencies

Put these on `PATH`:

- `~/.local/bin` (pipx)
- `~/.cargo/bin`
- `~/.dotnet/tools`

### Base

| Tool | Used for |
| --- | --- |
| Kakoune | editor |
| `kak-lsp` | language servers, diagnostics, hover, rename |
| `git` | branch in the modeline, diff gutter, hunks, blame, project root |
| `rg` | `:grep`, project file picker |
| `fzf` | fuzzy pickers (`<space>f`, `<space>b`, `<space>F`) |
| `kak-tree-sitter` + `ktsctl` | optional; syntax highlighting and tree-sitter text objects |
| `cc` (gcc/clang) and `git` | `ktsctl` uses them to build tree-sitter grammars |

```sh
# openSUSE, if any of these are missing
sudo zypper install kak-lsp ripgrep git
```

### Syntax highlighting (kak-tree-sitter)

Highlighting and text objects come from `kak-tree-sitter` (`treesitter.kak`),
which starts a daemon from the Kakoune session. Kakoune still starts without
it; C# then falls back to the C++ highlighter and other languages use
Kakoune's built-in ones.

Installing the binaries is not enough. Each language needs a grammar and
highlight queries, which `ktsctl` downloads and compiles. Without them the
buffer is uncoloured (all white), with no error. Needs network access, `git`
and a C compiler.

```sh
cargo install kak-tree-sitter ktsctl   # puts both in ~/.cargo/bin

# once per language; re-run to update. `ktsctl query -a` lists all languages.
ktsctl sync python csharp markdown rust c cpp bash json toml
ktsctl query python                    # check "Install stats" at the bottom
```

The `kak-tree-sitter` daemon is shared by all sessions and reads grammars
only when it starts. After installing or changing a grammar, stop it, or
the buffer stays uncoloured even in a freshly started Kakoune:

```sh
pkill kak-tree-sitter   # the next Kakoune start launches a new one
```

Per-language overrides live in `~/.config/kak-tree-sitter/config.toml`, which
is outside this directory. It sets `remove_default_highlighter = true` for
Python and registers the C# grammar under the name `c-sharp`, because the
default entry symbol lookup fails for `csharp`. Copy it to a new machine
along with this directory. After editing it, run `ktsctl sync <lang>` again.

The colorscheme is `modus-vivendi`, loaded from the `colors/` symlink
(kakoune-themes). A scheme that defines no `ts_*` faces shows no colour even
when tree-sitter works.

### Python

Format-on-write and `<space>L` use `ruff` on `PATH`, then `ruff` inside the
pylsp venv. Completion and diagnostics use `pylsp`.

```sh
pipx install python-lsp-server
pipx inject python-lsp-server \
    python-lsp-ruff python-lsp-black pylint pylsp-mypy \
    pylsp-rope python-lsp-isort
pipx install ruff
```

`jedi.environment` is unset. pylsp uses its own interpreter, not the missing
Helix path `~/.pyenv/versions/3.12.8/envs/antiroll/bin/python`. Set
`pylsp.plugins.jedi.environment` in `lsp-servers.kak` if a project venv should
win.

### C and C++

`clangd` is the language server and the preferred source/header switch.
Without it, `go` searches by filename.

```sh
sudo zypper install clang
```

C and C++ are not auto-formatted.

### C\#

```sh
dotnet tool install --global csharpier
cargo install --git https://github.com/SofusA/csharp-language-server
```

Needs a .NET SDK. The server is `csharp-language-server` (stdio). Do not use
the older `roslyn-language-server` wrapper: it panics looking for a
`/tmp/roslyn` build and never finishes initializing. The filetype is detected
here; highlighting reuses the C++ highlighter. Roslyn can take several seconds
on first open. `gd` before that is parked and retried once the server is up.

### Typst

```sh
cargo install typstyle
cargo install --git https://github.com/Myriad-Dreamin/tinymist tinymist-cli
```

`tinymist` is the language server. Format-on-write still calls `typstyle`
directly (`--wrap-text --line-width 120`).

### Markdown

```sh
# https://docs.deno.com/runtime/getting_started/installation/
curl -fsSL https://deno.land/install.sh | sh
```

`deno fmt` is the formatter. Markdown LSP is kak-lsp's default (`marksman`),
not configured in `lsp-servers.kak`.

### Left unwired

`simple-completion-language-server` is not used. Word completion stays on
Kakoune's `<c-n>` and `<c-x>w`. Signature help is manual: `:lsp-signature-help`.

Other filetypes keep kak-lsp's defaults (`rust-analyzer`, and so on) when
those servers are installed.

## What starts automatically

- Relative line numbers, a ruler at column 120.
- Modeline: mode, git branch, buffer, cursor, then LSP status and
  error/warning counts once `kak-lsp` is loaded.
- Git diff gutter in a work tree. Writes refresh the branch and the diff.
- Format before write for Python, C#, Typst, and Markdown. A formatter
  failure leaves the buffer unchanged.
- LSP diagnostics: inline highlights, end-of-line text, and gutter flags.
- Markdown soft-wrap at 80 columns. Typst wrap column is 120.
- In insert mode, `<tab>` jumps to the next LSP snippet placeholder, or
  inserts a tab if there is none.

## Shortcuts

`<space>` enters user mode. `<space>h` shows the keys. Goto keys are `g`
followed by the key.

### Code travel

| Keys | Action |
| --- | --- |
| `gd` | definition |
| `gr` | references. In the list, pause on a line for a preview: a split pane client when inside tmux or wezterm, else an info popup. The same preview works in `:grep` results (`<space>/`, `<space>@`). Under zellij, both open two centred floating panes instead: the plain list on the left (j/k, Enter jumps, q/Esc closes) and the preview on the right |
| `gy` | type definition |
| `gI` | implementation |
| `gs` | fuzzy document symbols (fzf; same as `<space>lS`). Falls back to kak-lsp's prompt without `fzf`. Type to filter, Enter jumps, `<c-o>` returns |
| `go` | C/C++ source or header |
| `gn` / `gp` | next / previous diagnostic |
| `g]` / `g[` | next / previous symbol |
| `<c-o>` / `<c-i>` | jump back / forward (Kakoune default) |
| `ga` | last buffer (Kakoune default) |

### Normal mode

| Keys | Action |
| --- | --- |
| `<c-n>` / `<c-p>` | next / previous git hunk |

Insert mode keeps `<c-n>` for completion.

### User mode (`<space>`)

| Keys | Action |
| --- | --- |
| `l` | kak-lsp menu |
| `h` | hover |
| `=` | format (`formatcmd`, otherwise the language server) |
| `f` | fzf: fuzzy-find a project file |
| `e` | open a project file |
| `b` | fzf: fuzzy-switch buffer |
| `,` / `.` | previous / next buffer |
| `q` | close buffer |
| `/` or `@` | project-search the selection, or the word at the cursor |
| `*` / `#` | search that word forward / backward |
| `B` | toggle git blame |
| `L` | external `:lint` (Python: `ruff check`) |
| `i` | diagnostic display menu |
| `t` | tree-sitter menu (see below) |
| `F` | fzf mode, every picker |

`<space>ic`, `<space>ie`, and `<space>io` toggle inline highlights,
end-of-line text, and gutter flags.

### kak-lsp menu (`<space>l`)

These keys belong to kak-lsp. The prompt lists them too.

| Keys | Action |
| --- | --- |
| `a` | code actions |
| `R` | rename |
| `e` | list diagnostics |
| `o` | workspace symbol |
| `S` | fuzzy document symbols (fzf, same as `gs`). Remapped from kak-lsp's plain list, which is still `:lsp-document-symbol` |
| `f` / `=` | format buffer / format selections |
| `d` `r` `y` `i` | definition, references, type, implementation |
| `n` / `p` | next / previous diagnostic |
| `h` / `H` | hover / hover in a scratch buffer |
| `&` | highlight references |
| `j` / `k` | outgoing / incoming calls |
| `v` | widen or narrow the selection by syntax node |

### Text objects

Use them like other objects: `if` is inner, `af` is around.

| Object | Selects |
| --- | --- |
| `f` | function (tree-sitter) |
| `t` | class or type (tree-sitter) |
| `a` | argument or parameter (tree-sitter) |
| `T` | test (tree-sitter) |
| `l` | LSP symbol |
| `d` | LSP error or warning |
| `D` | LSP error |

kak-tree-sitter loads after `travel.kak`, so when it is running its `f` and
`t` replace the LSP versions (functions and methods; classes, interfaces,
modules, namespaces, structs). Without it the LSP versions stay.

### Tree-sitter menu (`<space>t`)

Needs `kak-tree-sitter` and an installed grammar for the language.

| Keys | Action |
| --- | --- |
| `s` | select parent node |
| `t` / `<c-t>` | select first / last child |
| `c` / `r` | select previous / next sibling |
| `C` / `R` | previous / next sibling, crossing parents (cousin) |
| `(` / `)` | first / last sibling |
| `T` | sticky navigation: stay in the mode while moving |
| `k` | select the nearest function, parameter, class, or test |
| `f` / `<a-f>` | jump to next / previous function, parameter, class, or test; `F` / `<a-F>` extend the selection |
| `/` / `<a-/>` | search next / previous object; `?` / `<a-?>` extend |

After `f`, `/` and so on, a second key picks the kind: `f` function,
`a` parameter, `t` class, `T` test (`c` comment for `/`).

## Not remapped

These Helix habits were left alone because the Kakoune keys already do
something else:

`x` and `<a-x>` select to line bounds. `<a-.>` repeats a motion. `<a-,>`
drops the main selection. `*` searches the current selection. `@` converts
tabs to spaces.
