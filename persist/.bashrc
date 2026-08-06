# ~/.bashrc

# Enable color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi



alias histfind="history | grep --color=always --ignore-case"
alias t="tail -f"
alias l="less"
alias topu="top -u $USER"
alias ll="ls -lha"
alias la="ls -a"
alias ld="ls -d"
alias lt="ls -lhatr"
alias bashrc="source $HOME/.bashrc"
devnullredirect () {
    echo "$@ 2>/dev/null"
    "$@" 2>/dev/null
}
function f {
    devnullredirect find . -iname "$1" "${@:2}"
}

alias uv-tests="source .venv/bin/activate; uv sync --dev; uv run ruff format; uv run ruff check --fix; uv run pytest; mypy ."
alias venv-here="[ ! -d .venv ] && uv venv; source .venv/bin/activate"

# Resume previous session for installed AI agents
if command -v cline >/dev/null 2>&1; then
    alias cline-resume='cline history'
fi
if command -v hermes >/dev/null 2>&1; then
    alias hermes-resume='hermes --continue'
fi
if command -v devin >/dev/null 2>&1; then
    alias devin-resume='devin -c'
fi
if command -v opencode >/dev/null 2>&1; then
    alias opencode-resume='opencode -c --auto'
fi



# Source personal customizations if present (not committed to git)
if [ -f /persist/bashrc-extra ]; then
    . /persist/bashrc-extra
fi

# Only print welcome in interactive shells
[[ $- == *i* ]] && echo "Welcome to the Simple Agent Sandbox!"

# opencode
export PATH=/persist/.opencode/bin:$PATH
