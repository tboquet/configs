alias emacs="/Applications/Emacs.app/Contents/MacOS/Emacs -nw"
alias emacsclient="/Applications/Emacs.app/Contents/MacOS/bin/emacsclient"
alias spacemacs="emacs --daemon && emacsclient -c &; disown"
alias spacemacsk="emacsclient -e '(save-buffers-kill-emacs)'"
export PATH="$PATH:/opt/homebrew/bin"
ulimit -n 1000000
