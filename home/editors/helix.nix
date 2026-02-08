# Helix Editor Configuration
# Modal editor with vim-like keybinds, LSP integration, and tree-sitter
# Based on: https://rushter.com/blog/helix-editor/

{ pkgs, ... }:

{
  programs.helix = {
    enable = true;
    defaultEditor = true;

    settings = {
      theme = "catppuccin_mocha";

      editor = {
        line-number = "relative";
        mouse = true;
        rulers = [ 120 ];
        true-color = true;
        completion-replace = true;
        trim-trailing-whitespace = true;
        end-of-line-diagnostics = "hint";
        color-modes = true;
        rainbow-brackets = true;

        inline-diagnostics.cursor-line = "warning";

        lsp.display-inlay-hints = false;

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        file-picker.hidden = false;

        indent-guides = {
          render = true;
          character = "╎";
          skip-levels = 0;
        };

        soft-wrap.enable = false;

        auto-save = {
          focus-lost = true;
          after-delay.enable = true;
          after-delay.timeout = 300000;
        };

        statusline = {
          left = [
            "mode"
            "spinner"
            "version-control"
            "spacer"
            "separator"
            "file-name"
            "read-only-indicator"
            "file-modification-indicator"
          ];
          center = [];
          right = [
            "diagnostics"
            "workspace-diagnostics"
            "position"
            "total-line-numbers"
            "position-percentage"
            "file-encoding"
            "file-line-ending"
            "file-type"
            "register"
            "selections"
          ];
          separator = "│";
          mode.normal = "NOR";
          mode.insert = "INS";
          mode.select = "SEL";
        };
      };

      # Vim-like normal mode keybinds
      keys.normal = {
        D = [ "ensure_selections_forward" "extend_to_line_end" "delete_selection" ];
        "0" = "goto_line_start";
        "$" = "goto_line_end";
        "^" = "goto_first_nonwhitespace";
        G = "goto_file_end";
        V = [ "select_mode" "extend_to_line_bounds" ];
        esc = [ "collapse_selection" "keep_primary_selection" ];

        # Quick actions
        "+" = {
          f = ":format";
          w = ":toggle whitespace.render all";
          W = ":set whitespace.render none";
          s = ":toggle soft-wrap.enable";
        };

        "=" = {
          "=" = ":format";
        };

        # Space menu
        space = {
          e = { w = ":write"; c = ":bc"; x = ":bco"; l = ":toggle lsp.display-inlay-hints"; };
          q = ":quit";
          f = {
            f = "file_picker_in_current_directory";
            F = "file_picker";
            b = "file_picker_in_current_buffer_directory";
            "." = ":toggle-option file-picker.git-ignore";
            g = "global_search";
            e = "file_explorer";
            r = ":reload-all";
            x = ":reset-diff-change";
            d = [ ":vsplit-new" ":lang diff" ":insert-output git diff" ];
          };
        };
      };

      # Vim-like select mode keybinds
      keys.select = {
        "0" = "goto_line_start";
        "$" = "goto_line_end";
        "^" = "goto_first_nonwhitespace";
        G = "goto_file_end";
        D = [ "extend_to_line_bounds" "delete_selection" "normal_mode" ];
        k = [ "extend_line_up" "extend_to_line_bounds" ];
        j = [ "extend_line_down" "extend_to_line_bounds" ];
        up = [ "extend_line_up" "extend_to_line_bounds" ];
        down = [ "extend_line_down" "extend_to_line_bounds" ];

        space.f.s = ":reflow 100";
      };
    };

    # Language server configuration
    languages = {
      language-server = {
        harper-ls = {
          command = "harper-ls";
          args = [ "--stdio" ];
        };
        ruff = {
          command = "ruff";
          args = [ "server" ];
          config = {
            documentFormatting = true;
            settings.run = "onSave";
          };
        };
        rust-analyzer.config = {
          cargo.features = "all";
          check.command = "clippy";
        };
        yaml-language-server.config.yaml = {
          completion = true;
          validate = true;
          hover = true;
          format = { enable = true; bracketSpacing = true; };
          schemas = [];
          schemaStore = { enable = false; };
        };
      };

      language = [
        {
          name = "markdown";
          language-servers = [ "marksman" "harper-ls" ];
        }
        {
          name = "python";
          auto-format = true;
          language-servers = [
            { name = "ruff"; }
            { name = "pyright"; }
            { name = "harper-ls"; }
          ];
          roots = [ "pyproject.toml" "setup.py" "poetry.lock" ".git" ".venv/" ];
        }
        {
          name = "rust";
          language-servers = [ "rust-analyzer" "harper-ls" ];
        }
        {
          name = "nix";
          language-servers = [ "nil" ];
          auto-format = true;
        }
      ];
    };

    # Language servers and tools
    extraPackages = with pkgs; [
      # LSPs
      marksman            # Markdown
      harper              # Grammar checking (provides harper-ls)
      nil                 # Nix
      rust-analyzer       # Rust
      pyright             # Python
      ruff                # Python linter/formatter
      yaml-language-server

      # Formatters
      nixfmt-rfc-style    # Nix formatter
    ];
  };

  # Tree-sitter injection queries (SQL highlighting in Python/Go, YAML frontmatter in Markdown)
  home.file.".config/helix/runtime/queries/python/injections.scm".text = ''
    (call
      function: (attribute
        object: (identifier) @py_object
        attribute: (identifier) @py_function)
      (#match? @py_function "^execute")
      (#match? @py_object ".*(cur|conn)(ection)?$")
      arguments: (argument_list
        (string
          (string_content) @injection.content))
      (#set! injection.language "sql")) @python_highlight_sqlite

    (call
      function: (attribute
        object: (identifier) @py_object
        attribute: (identifier) @py_function)
      (#eq? @py_object "shlex")
      (#eq? @py_function "split")
      arguments: (argument_list
        (string
          (string_content) @injection.content))
      (#set! injection.language "bash")) @python_highlight_shlex

    ((string_content) @injection.content
      (#match? @injection.content
        "(?ism)^(SELECT|INSERT|UPDATE|DELETE).*?(FROM|INTO|VALUES|SET)(.|\n)*?(WHERE|GROUP BY)?")
      (#set! injection.language "sql"))
  '';

  home.file.".config/helix/runtime/queries/go/injections.scm".text = ''
    (([
       (interpreted_string_literal_content)
       (raw_string_literal_content)
     ] @injection.content
     (#match? @injection.content "(?ism)(SELECT|select|INSERT|insert|UPDATE|update|DELETE|delete).+(FROM|from|INTO|into|VALUES|values|SET|set).*(WHERE|where|GROUP BY|group by)?")
     )
    (#set! injection.language "sql")
    )
  '';

  home.file.".config/helix/runtime/queries/markdown/injections.scm".text = ''
    (fenced_code_block
      (info_string
        (language) @injection.language)
      (code_fence_content) @injection.content)

    ((html_block) @injection.content (#set! injection.language "html"))

    (document . (section . (thematic_break) (_) @injection.content (thematic_break)) (#set! injection.language "yaml"))

    ((minus_metadata) @injection.content (#set! injection.language "yaml"))
  '';
}
