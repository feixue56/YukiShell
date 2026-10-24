set -g fish_greeting

# --- migrated from ~/.bashrc ---
fish_add_path -g $HOME/.local/bin

set -gx TIME_STYLE '+%-m月%-d日 %H:%M'
for v in LC_TIME LC_NUMERIC LC_MONETARY LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION
    set -gx $v zh_CN.UTF-8
end

alias ls 'ls --color=auto'
alias grep 'grep --color=auto'
alias la 'ls -la'

# --- bash habits that fish lacks ---
# !! and !$ expand to the last command / its last argument
function __last_cmd;  echo $history[1]; end
function __last_arg;  string split ' ' -- $history[1] | tail -n 1; end
abbr -a '!!' --position anywhere --function __last_cmd
abbr -a '!$' --position anywhere --function __last_arg

# `bsource script.sh` runs a bash script and imports the variables it exports (like `source` in bash).
function bsource --description 'Source a bash script into fish (exported vars only)'
    set -l before (env -0 | string split0 | sort)
    set -l after (bash -c 'source "$1" >/dev/null 2>&1; env -0' _ $argv[1] | string split0 | sort)
    for line in (comm -13 (printf '%s\n' $before | psub) (printf '%s\n' $after | psub))
        set -l kv (string split -m1 = -- $line)
        test (count $kv) -eq 2; and set -gx $kv[1] $kv[2]
    end
end
