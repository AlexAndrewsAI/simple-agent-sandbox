# ~/.bashrc

# Enable color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# Common aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'


echo "Welcome to the Simple Agent Sandbox!"