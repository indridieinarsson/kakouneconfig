# Language servers corresponding to helix languages.toml.
# Loaded only after kak-lsp has declared lsp_servers.
# Defaults for other filetypes (rust, go, markdown/marksman, ...) stay in place.

try %{ remove-hooks global lsp-filetype-python }
try %{ remove-hooks global lsp-filetype-c-family }
try %{ remove-hooks global lsp-filetype-typst }

hook -group lsp-user-python global BufSetOption filetype=python %{
    set-option buffer lsp_language_id python
    set-option buffer lsp_servers %{
        [pylsp]
        root_globs = ["pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", "uv.lock", ".git", ".hg"]
        settings_section = "_"
        [pylsp.settings._]
        # ruff replaces pyflakes/pycodestyle. black stays available as a plugin;
        # format-on-write still uses the ruff CLI, as in helix.
        pylsp.plugins.ruff.enabled = true
        pylsp.plugins.pyflakes.enabled = false
        pylsp.plugins.pycodestyle.enabled = false
        pylsp.plugins.mccabe.enabled = false
        pylsp.plugins.black.enabled = true
        pylsp.plugins.jedi_completion.include_params = true
        pylsp.plugins.pylint.enabled = true
        pylsp.plugins.isort.enabled = true
        pylsp.plugins.rope_autoimport.enabled = true
        # pylsp-mypy 0.8 registers as pylsp_mypy, not the older pyls_mypy name.
        pylsp.plugins.pylsp_mypy.enabled = true
        pylsp.plugins.pylsp_mypy.live_mode = false
        # Installed via pylsp-rope; separate from rope_autoimport.
        pylsp.plugins.pylsp_rope.enabled = true
        # helix pointed jedi at a missing interpreter:
        # /home/indridi/.pyenv/versions/3.12.8/envs/antiroll/bin/python
        # pylsp.plugins.jedi.environment = "/path/to/python"
    }
}

hook -group lsp-user-c-family global BufSetOption filetype=(?:c|cpp|objc) %{
    set-option buffer lsp_language_id %sh{
        case "$kak_hook_param" in
            c) printf c ;;
            objc) printf objective-c ;;
            *) printf cpp ;;
        esac
    }
    set-option buffer lsp_servers %{
        [clangd]
        command = "clangd"
        args = ["--background-index", "--header-insertion=iwyu", "--completion-style=detailed", "--log=error"]
        root_globs = ["compile_commands.json", ".clangd", "compile_flags.txt", ".git", ".hg"]
    }
}

hook -group lsp-user-csharp global BufSetOption filetype=csharp %{
    set-option buffer lsp_language_id csharp
    set-option buffer lsp_servers %{
        [csharp]
        # roslyn-language-server 0.5.0 panics: it looks for a local /tmp/roslyn build.
        # csharp-language-server already has Microsoft.CodeAnalysis.LanguageServer cached
        # and speaks stdio, then sends solution/open from the workspace root.
        command = "csharp-language-server"
        root_globs = ["*.sln", "*.slnx", "*.csproj", "global.json", ".git", ".hg"]
    }
}

hook -group lsp-user-typst global BufSetOption filetype=typst %{
    set-option buffer lsp_language_id typst
    set-option buffer lsp_servers %{
        [tinymist]
        command = "tinymist"
        args = ["lsp"]
        root_globs = [".git", ".hg"]
        settings_section = "_"
        [tinymist.settings._]
        exportPdf = "onDocumentHasTitle"
        formatterMode = "typstyle"
        formatterPrintWidth = 120
        preview.background.enabled = false
    }
}
