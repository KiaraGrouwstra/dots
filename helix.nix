{ lib, ... }:
{
  home.sessionVariables.COLORTERM = "truecolor";

  programs.helix = {
    enable = true;
    # https://docs.helix-editor.com/configuration.html
    settings = {
      theme = lib.mkForce "base16_transparent";
      editor = {
        auto-save = {
          focus-lost = true;
          after-delay = {
            enable = true;
            timeout = 3000;
          };
        };
        auto-format = false;
        # line-number = "relative";
        soft-wrap.enable = true;
        lsp.display-messages = true;
        file-picker.hidden = false;
        whitespace.render = "all";
        color-modes = true;
        indent-guides.render = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        end-of-line-diagnostics = "disable";
        inline-diagnostics = {
          cursor-line = "info";
          other-lines = "disable";
          prefix-len = 1;
          max-wrap = 20;
          max-diagnostics = 1;
        };
      };
      keys =
        let
          pageHigh = lib.replicate 53;
        in
        {
          normal = {
            space.space = "file_picker";
            space.w = ":w";
            space.q = ":q";
            space.x = ":buffer-close";
            esc = [
              "collapse_selection"
              "keep_primary_selection"
            ];
            "A-z" = ":q!";
            "A-tab" = "goto_next_buffer";
            "A-S-tab" = "goto_previous_buffer";
            "A-m" = "toggle_comments";
            "K" = "page_up";
            "J" = "page_down";
            "S-H" = "goto_next_buffer";
            "S-L" = "goto_previous_buffer";
            "A-g" = "goto_next_buffer";
            "A-s" = "goto_previous_buffer";
            "S-x" = ":buffer-close";
            "x" = "select_regex";
            "s" = "select_line_below";
            "S" = "select_line_above";
            "h" = "move_char_left";
            "j" = "move_visual_line_down";
            "k" = "move_visual_line_up";
            "l" = "move_char_right";
            "e" = "move_next_word_end";
            "E" = "move_next_long_word_end";
            "g" = {
              "e" = "goto_last_line";
              "h" = "goto_line_start";
              "l" = "goto_line_end";
              "y" = "goto_type_definition";
              "n" = "goto_next_buffer";
              "k" = "move_line_up";
              "j" = "move_line_down";
            };
            "o" = "open_below";
            "O" = "open_above";
            # "A-l" = "expand_selection";
            # "A-k" = "select_next_sibling";
            # "A-h" = "move_parent_node_end";
            # "[" = {
            #   "e" = "goto_prev_entry";
            # };
            # "]" = {
            #   "e" = "goto_next_entry";
            # };
            "n" = "search_next";
            "N" = "search_prev";
            # "y" = ''@"+Y'';
            # "Y" = "yank_to_clipboard";
            "=" = "paste_clipboard_after";
            "+" = "paste_clipboard_before";
            # "p" = ''@"+='';
            # "P" = ''@"++'';
            # "r" = ''@"+R'';
            # "R" = "replace_selections_with_clipboard";
            "c" = "change_selection_noyank";
            # "d" = ''@"+D'';
            # "D" = [ "yank_to_clipboard" "delete_selection_noyank" ];
            # "J" = "join_selections";
            # "A-J" = "join_selections_space";
            # "K" = "keep_selections";
            # "A-K" = "remove_selections";
            # "esc" = "normal_mode";
            "C-b" = "page_up";
            "C-f" = "page_down";
            # "C-u" = "page_cursor_half_up";
            # "C-d" = "page_cursor_half_down";
            "C-w" = {
              "h" = "jump_view_left";
              "j" = "jump_view_down";
              "k" = "jump_view_up";
              "l" = "jump_view_right";
              "C-h" = "jump_view_left";
              "C-j" = "jump_view_down";
              "C-k" = "jump_view_up";
              "C-l" = "jump_view_right";
              "L" = "swap_view_right";
              "K" = "swap_view_up";
              "H" = "swap_view_left";
              "J" = "swap_view_down";
              "w" = {
                "s" = "hsplit_new";
                "v" = "vsplit_new";
                "C-s" = "hsplit_new";
                "C-v" = "vsplit_new";
              };
            };
            "C-o" = "jump_backward";
            C-g = [
              # Lazygit
              ":write-all"
              ":new"
              ":insert-output lazygit"
              ":buffer-close!"
              ":redraw"
              ":reload-all"
            ];
            "space" = {
              "n" = "jumplist_picker";
              # "w" = {
              #   "h" = "jump_view_left";
              #   "j" = "jump_view_down";
              #   "k" = "jump_view_up";
              #   "l" = "jump_view_right";
              #   "C-h" = "jump_view_left";
              #   "C-j" = "jump_view_down";
              #   "C-k" = "jump_view_up";
              #   "C-l" = "jump_view_right";
              #   "H" = "swap_view_left";
              #   "j" = "swap_view_down";
              #   "k" = "swap_view_up";
              #   "L" = "swap_view_right";
              #   "k" = {
              #     "s" = "hsplit_new";
              #     "v" = "vsplit_new";
              #     "C-s" = "hsplit_new";
              #     "C-v" = "vsplit_new";
              #   };
              # };
              # "y" = ''@"+Y'';
              # "Y" = "yank_to_clipboard";
              "h" = "select_references_to_symbol_under_cursor";
              "=" = "paste_clipboard_after";
              "+" = "paste_clipboard_before";
              # "p" = ''@"+='';
              # "P" = ''@"++'';
              # "r" = ''@"+R'';
              # "R" = "replace_selections_with_clipboard";
            };
            "z" = {
              "k" = "scroll_up";
              "j" = "scroll_down";
              # "C-b" = "page_up";
              # "C-f" = "page_down";
              # "C-u" = "page_cursor_half_up";
              # "C-d" = "page_cursor_half_down";
              "n" = "search_next";
              "N" = "search_prev";
            };
            "Z" = {
              "k" = "scroll_up";
              "j" = "scroll_down";
              # "C-b" = "page_up";
              # "C-f" = "page_down";
              # "C-u" = "page_cursor_half_up";
              # "C-d" = "page_cursor_half_down";
              "n" = "search_next";
              "N" = "search_prev";
            };
          };
          select = {
            # "y" = ''@"+Y'';
            # "Y" = "yank_to_clipboard";
            "h" = "extend_char_left";
            "j" = "extend_visual_line_down";
            "k" = "extend_visual_line_up";
            "J" = pageHigh "extend_visual_line_down";
            "K" = pageHigh "extend_visual_line_up";
            "l" = "extend_char_right";
            "e" = "extend_next_word_end";
            "E" = "extend_next_long_word_end";
            "A-e" = "extend_parent_node_end";
            "n" = "extend_search_next";
            "N" = "extend_search_prev";
            "g" = {
              "k" = "extend_line_up";
              "j" = "extend_line_down";
              "h" = "goto_line_start";
              "l" = "goto_line_end";
            };
            # "space" = {
            #   "y" = ''@"+Y'';
            #   "Y" = "yank_to_clipboard";
            # };
          };
          insert = {
            # "C-u" = "kill_to_line_start";
            "C-k" = "kill_to_line_end";
            "C-h" = "delete_char_backward";
            # "C-d" = "delete_char_forward";
            "C-j" = "insert_newline";
          };
        };
    };
    # https://docs.helix-editor.com/languages.html
    languages = {
      language-server = {
        nixd = {
          command = "nixd";
          # https://raw.githubusercontent.com/nix-community/nixd/main/nixd/docs/nixd-schema.json
          config = {
            nixpkgs.expr = "import <nixpkgs> { }";
            formatting = {
              command = [ "nixfmt" ];
            };
          };
        };
      };
    };
  };
}
