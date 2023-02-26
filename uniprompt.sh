#!/usr/bin/bash

# sanity checks first: decide, when NOT to run...
[ -z "$PS1" ] && return

# to begin with: a random background color for each shell makes them easier to
# distinguish. Most virtual terminal emulators support TRUECOLOR today.
COLOR_BG_R=$((RANDOM % 255))
COLOR_BG_G=$((RANDOM % 255))
COLOR_BG_B=$((RANDOM % 255))

COLOR_BACKGROUND="\e[38;2;$COLOR_BG_R;$COLOR_BG_G;$COLOR_BG_B"m
COLOR_FOREGROUND="\e[48;0m"

# Here comes the approximation of the perceived brightness of colors: To allow
# the foreground to stand out it has to be considered. 0.2126R + 0.7152G +
# 0.0722B would be correct for relative luminance, but this approximation is
# close enough to determine either white or black as text color.
if [ $(expr $COLOR_BG_R / 3 + $COLOR_BG_G / 1 + $COLOR_BG_B / 8) -gt 240 ]; then
  COLOR_FOREGROUND="\e[48;2;0;0;0m"
else
  COLOR_FOREGROUND="\e[48;2;255;255;255m"
fi

# set window title according to exit status
function setWindowTitle() {
  local exit_status="$1"
  if [[ $? != $exit_status ]]; then # in case of an error
    echo -ne "]0; ${PWD}"  # window title
    printf "[0;33m%*s%s[0m" $(($(tput cols)-6)) "" "  $exit_status"
  else
    echo -ne "]0; ${PWD}"  # window title
  fi
}

function getClockSymbol() {
  # intential space  v123456789... you get the point :)
  local CLK_SYMBOLS=" "
  local HOUR=$(date +%I | sed -e 's/^0//')
  test $HOUR -ge 12 && HOUR=$(expr $HOUR - 12) # middach
  test "$(date +%M)" -gt "30" && HOUR=$(expr "$HOUR" + 1) # floor
  echo -ne "${CLK_SYMBOLS:HOUR:1}"
}

function getUserSymbol() {
  case "$USER" in
    root)  echo -n "⚙️ " ;;
    *)     echo -n " " ;;
  esac
}

function getGitBranch() {
  GIT_BRANCH=""
  GIT_SUMMARY=""
  if git rev-parse --git-dir 1>/dev/null 2>/dev/null; then
    GIT_BRANCH=$(git branch 2>/dev/null | grep '^*' | colrm 1 2)
    GIT_SUMMARY=$(git log --oneline -1 --pretty=format:%s)
    GIT_BRANCH_DESCRIPTION=$(git config branch.$GIT_BRANCH.description 2>/dev/null)
  fi
  echo -ne "${GIT_BRANCH:+  │    $GIT_BRANCH}"
  echo -ne "${GIT_BRANCH_DESCRIPTION:+ - $GIT_BRANCH_DESCRIPTION}"
  # echo -ne "${GIT_SUMMARY:+ - $GIT_SUMMARY}"
}

function getHgBookmark() {
  if test -f .hg/bookmarks.current ; then
    echo -ne "  $(cat .hg/bookmarks.current)"
  # TODO: alternative is too slow
  # else
  #   hg log -r . -T '{activebookmark}'
  fi
}

function getVCS() {
    PATHBEFORE=$PWD
    while [ true ]; do
        test -d .hg  && getHgBookmark
        test -d .git && getGitBranch
        cd ..
        test $OLDPWD == $PWD && break
    done
    cd $PATHBEFORE
}

function prompt() {
  setWindowTitle $?
  echo # make this write as atomic as possible to avoid flickering
  tput cuf $(($(tput cols)-15))
  echo -ne "$COLOR_BACKGROUND" 
  echo -ne "\e[49m"             # reset background
  echo -ne "\e[27m"             # inverse revert
  echo -ne ""
  echo -ne "\e[7m"
  echo -ne "$COLOR_FOREGROUND"
  echo -ne " "
  getClockSymbol
  echo -ne " "
  echo -ne "$(date +%H:%M:%S)"
  echo -ne " "
  echo -ne "░"
  echo -ne "\r"
  echo -ne "░"
  echo -ne " "
  getUserSymbol
  echo -ne "$USER@$HOSTNAME"
  echo -ne " "
  echo -ne " "
  getVCS
  echo -ne " "
  echo -ne "\e[49m" # reset background
  echo -ne "\e[27m" # inverse revert
  echo -ne ""
  echo -ne "\e[0m"
  echo
  echo
}

function setWindowTitleToCurrentCommand() {
  echo -ne "\033]0; ${BASH_COMMAND}\007"
}

export PS1=" \[\033[38;2;210;160;50m\]  \[\033[0m\]\w  "
# trap 'echo -ne "\033]0; ${BASH_COMMAND}\007"' DEBUG
export PROMPT_COMMAND=prompt

# TODO: does not work with current versions of bash, because they seem to spawn
# a sub-shell and I get a strange PS1 string back from it.
# trap setWindowTitleToCurrentCommand debug

# TODO
# shopt -s checkwinsize
# echo $COLUMNS
# echo $(tput cols)
# PS0="]0;⏳${PWD} @ ${HOSTNAME} $PROMPT_COMMAND" # replaced by trap, sets window title
# test colors with `msgcat --color=test` and see man console_codes
# and try things like export LS_COLORS=$LS_COLORS:'*.md=38;2;255;255;0'

# vim: shiftwidth=2 tabstop=2 softtabstop=2 expandtab
