# TODO: path and aliases are kinda slow to source. optimize later.
#Load envrc to allow for universal syntax (bash/zsh/fish)
if test -f ~/.envrc
    eval (envsubst < ~/.envrc)
end
set -gx PATH /opt/homebrew/bin $PATH

source ~/.config/fish/path.fish
source ~/.config/fish/aliases.fish
source ~/.config/fish/functions.fish
source ~/.config/fish/chromium.fish
source (brew --prefix)/opt/fzf/shell/key-bindings.fish


#color settings come from omf agnoster
#? ONCE you have access to https://githubnext.com/projects/copilot-cli
#https://github.com/z11i/github-copilot-cli.fish
# alias , __copilot_what-the-shell
# alias ,g __copilot_git-assist
# alias ,gh __copilot_gh-assist

#gazorby/fifc settings
set -Ux fifc_editor vim 
set -U fifc_keybinding \cx # Bind fzf completions to ctrl-x
# set -U fifc_keybinding \e[Z]

set -U fifc_bat_opts --style=numbers
set -U fifc_fd_opts --hidden
set -x RM "/bin/rm -f"


[ -f /opt/homebrew/share/autojump/autojump.fish ]
source /opt/homebrew/share/autojump/autojump.fish

set -U fish_color_scheme default
set -g theme_nerd_fonts yes

# Git prompt status
set -g __fish_git_prompt_showdirtystate 'yes'
set -g __fish_git_prompt_showupstream auto

# Status Chars
#set __fish_git_prompt_char_dirtystate '*'
set __fish_git_prompt_char_upstream_equal ''
set __fish_git_prompt_char_upstream_ahead '↑'
set __fish_git_prompt_char_upstream_behind '↓'
set __fish_git_prompt_color_branch yellow
set __fish_git_prompt_color_dirtystate 'red'

set __fish_git_prompt_color_upstream_ahead ffb90f
set __fish_git_prompt_color_upstream_behind blue

# Local prompt customization
set -e fish_greeting

# Direnv hook
eval "$(direnv hook fish)"
direnv hook fish | source

# Pyenv initialization
if command -v pyenv 1>/dev/null 2>&1
    pyenv init --path | source
end

# pull in all shared `export …` aka `set -gx …`
. ~/.exports

# TODO debug this
# this currently messes with newlines in my prompt. lets debug it later.
test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /opt/homebrew/anaconda3/bin/conda
    eval /opt/homebrew/anaconda3/bin/conda "shell.fish" "hook" $argv | source
end

conda config --set auto_activate_base false
# <<< conda initialize <<<


# echo "h -->"
