{ config, lib, pkgs, ... }:
let
  withFzf = config.programs.fzf.enable && config.programs.fzf.enableZshIntegration;
  fzfIntegration = {
    plugins = with pkgs; lib.lists.optionals withFzf [
      {
        name = "fzf-git";
        src = fzf-git-sh;
        file = "share/fzf-git-sh/fzf-git.sh";
      }
      {
        name = "fzf-tab";
        src = zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
      {
        name = "fzf-tab-source";
        src = pkgs.fetchFromGitHub {
          owner = "Freed-Wu";
          repo = "fzf-tab-source";
          rev = "aabde06d1e82b839a350a8a1f5f5df3d069748fc";
          sha256 = "sha256-AJrbr2l2tRt42n9ZUmmGaDm10ydwm3fRDlXYI0LoXY0=";
        };
        file = "fzf-tab-source.plugin.zsh";
      }
    ];
    zvm_after_init = lib.strings.optionalString withFzf ''

      # fzf bindings
      zvm_bindkey viins '^E' fzf-cd-widget
      zvm_bindkey viins '^F' fzf-file-widget
      zvm_bindkey viins '^I' fzf-completion
      zvm_bindkey viins '^R' fzf-history-widget

      # Set insert mode keybindings for fzf-git.sh
      # https://github.com/junegunn/fzf-git.sh/issues/23
      for o in files branches tags remotes hashes stashes lreflogs each_ref; do
        eval "zvm_bindkey viins '^g^''\${o[1]}' fzf-git-$o-widget"
        eval "zvm_bindkey viins '^g''\${o[1]}' fzf-git-$o-widget"
      done
    '';

    zvm_after_lazy_keybindings = lib.strings.optionalString withFzf ''

      # fzf bindings
      zvm_bindkey vicmd '^E' fzf-cd-widget
      zvm_bindkey vicmd '^F' fzf-file-widget
      zvm_bindkey vicmd '^I' fzf-completion
      zvm_bindkey vicmd '^R' fzf-history-widget

      # Set normal and visual modes keybindings for fzf-git.sh
      # https://github.com/junegunn/fzf-git.sh/issues/23
      for o in files branches tags remotes hashes stashes lreflogs each_ref; do
        eval "zvm_bindkey vicmd '^g^''\${o[1]}' fzf-git-$o-widget"
        eval "zvm_bindkey vicmd '^g''\${o[1]}' fzf-git-$o-widget"
        eval "zvm_bindkey visual '^g^''\${o[1]}' fzf-git-$o-widget"
        eval "zvm_bindkey visual '^g''\${o[1]}' fzf-git-$o-widget"
      done
    '';
  };

in

{
  home.packages = with pkgs; [
    zsh-completions
    zsh-fast-syntax-highlighting
    zsh-fzf-tab
    zsh-vi-mode

  ];
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = ".config/zsh";
    autosuggestion = {
      enable = true;
      highlight = "fg=241";
    };
    plugins = with pkgs; [
      {
        name = "completions";
        src = zsh-completions;
      }
      {
        name = "vi-mode";
        src = zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
      {
        name = "fast-syntax-highlighting";
        src = zsh-fast-syntax-highlighting;
        file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
      }
    ] ++ fzfIntegration.plugins;

    envExtra = ''
      export ZVM_LINE_INIT_MODE=i
    '';

    initExtra = ''
      fpath+="$HOME/.config/zsh/plugins/completions/share/zsh/site-functions"

      autoload -U up-line-or-beginning-search
      zle -N up-line-or-beginning-search

      autoload -U down-line-or-beginning-search
      zle -N down-line-or-beginning-search

      # Key bindings (insert mode only)
      function zvm_after_init() {
        bindkey -v
        zvm_bindkey viins '^0' beginning-of-line
        zvm_bindkey viins '^$' end-of-line
        zvm_bindkey viins '^B' clear-screen
        zvm_bindkey viins "^Y" up-line-or-beginning-search
        zvm_bindkey viins "^U" down-line-or-beginning-search
        zvm_bindkey viins '^O' autosuggest-accept
        zvm_bindkey viins '[C' autosuggest-accept
        ${fzfIntegration.zvm_after_init}
      }

      # Lazy keybindings (visual and command mode)
      function zvm_after_lazy_keybindings() {
        zvm_bindkey vicmd '^B' clear-screen
        zvm_bindkey vicmd "^Y" up-line-or-beginning-search
        zvm_bindkey vicmd "^U" down-line-or-beginning-search
        zvm_bindkey vicmd '^O' autosuggest-accept
        zvm_bindkey vicmd '[C' autosuggest-accept
        ${fzfIntegration.zvm_after_lazy_keybindings}
      }
    '';
  };
}
