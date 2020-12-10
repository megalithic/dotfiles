GIT_PROMPT_ORDER=(
	"prefix"
	"branch"
	"behind"
	"ahead"
	"separator"
	"staged"
	"changed"
	"conflicts"
	"untracked"
	"clean"
	"suffix"
)

declare -A GIT_PROMPT_SYMBOLS
GIT_PROMPT_SYMBOLS=(
	"prefix" "%F{250}[%f"
	"branch" "%F{120}"
	"behind" "%F{216}%{←%G%}"
	"ahead" "%F{216}%{→%G%}"
	"separator" "%F{250}|%f"
	"staged" "%F{117}%{♦%G%}"
	"changed" "%F{226}%{◊%G%}"
	"conflicts" "%F{9}%{≠%G%}"
	"untracked" "%F{214}%{…%G%}"
	"clean" "%F{10}%B%{✓%G%}%b"
	"suffix" "%F{250}]%f"
)

# Remove right margin from $RPROMPT. In theory, setting ZLE_RPROMPT_INDENT
# appropriately should be enough, but in practice results vary:
# https://superuser.com/q/655607
GIT_PROMPT_INDENT_HACK=1

declare -A GIT_STATUS_MAP
GIT_STATUS_MAP=(
	' M' 'changed'    # not updated, work tree changed since index
	' D' 'changed'    # not updated, deleted in work tree
	' T' 'changed'    # type changed in work tree, not staged
	'M ' 'staged'     # updated in index, index and work tree matches
	'MM' 'changed'    # updated in index, work tree changed since index
	'MD' 'changed'    # updated in index, deleted in work tree
	'MT' 'changed'    # updated in index, type changed in work tree
	'A ' 'staged'     # added to index, index and work tree matches
	'AM' 'changed'    # added to index, work tree changed since index
	'AD' 'changed'    # added to index, deleted in work tree
	'AT' 'changed'    # added to index, type changed in work tree
	'D ' 'staged'     # deleted from index
	'DM' 'changed'    # deleted from index
	'R ' 'staged'     # renamed in index, index and work tree matches
	'RM' 'changed'    # renamed in index, work tree changed since index
	'RD' 'changed'    # renamed in index, deleted in work tree
	'C ' 'staged'     # copied in index, index and work tree matches
	'CM' 'changed'    # copied in index, work tree changed since index
	'CD' 'changed'    # copied in index, deleted in work tree
	'T ' 'staged'     # type changed in index, index and work tree matches
	'TM' 'changed'    # type changed in index and matches type in work tree, content differs
	'TD' 'changed'    # type changed in index, deleted in work tree
	'TT' 'changed'    # type changed in index and differs from type in work tree
	'DD' 'conflicts'  # unmerged, both deleted
	'AU' 'conflicts'  # unmerged, added by us
	'UD' 'conflicts'  # unmerged, deleted by them
	'UA' 'conflicts'  # unmerged, added by them
	'DU' 'conflicts'  # unmerged, deleted by us
	'AA' 'conflicts'  # unmerged, both added
	'UU' 'conflicts'  # unmerged, both modified
	'??' 'untracked'  # untracked
	'!!' 'ignored'    # ignored
)

GIT_PROMPT_FIFO_DIR="$HOME/.tmp/zsh-git-prompt"

if [[ $GIT_PROMPT_INDENT_HACK -eq 1 ]]; then
	if [[ $TMUX_PANE ]]; then
		export ZLE_RPROMPT_INDENT=0
	else
		export ZLE_RPROMPT_INDENT=1
	fi
fi

function git_get_status() {
	local status_string map_status chunk chunk_index mapped_status
	local -a status_chunks
	local -A git_flags git_strings git_numbers
	status_string="$(git status --branch -u --porcelain -z 2> /dev/null)"
	if [[ $? -ne 0 ]]; then
		git_flags=(
			"in_repo" 0
		)
		typeset -p git_flags git_strings git_numbers
		return
	fi
	for map_status in $GIT_STATUS_MAP; do
		git_numbers[$map_status]=0
	done
	status_chunks=(${(0)status_string})
	chunk_index=1
	while [[ chunk_index -le ${#status_chunks} ]]; do
		chunk="${status_chunks[$chunk_index]}"
		if [[ "${chunk:0:2}" == '##' ]]; then
			git_parse_status_header "${chunk:2}"
			git_strings[branch]="$RETURN_BRANCH"
			git_numbers[ahead]=$RETURN_AHEAD
			git_numbers[behind]=$RETURN_BEHIND
		else
			mapped_status=${GIT_STATUS_MAP[${chunk:0:2}]}
			git_numbers[$mapped_status]=$((git_numbers[$mapped_status] + 1))
		fi
		if [[ "${chunk:0:2}" == R* || "${chunk:0:2}" == C* ]]; then
			chunk_index=$((chunk_index + 2))
		else
			chunk_index=$((chunk_index + 1))
		fi
	done
	git_flags[in_repo]=1
	git_flags[clean]=0
	if [[ \
		${git_numbers[staged]} -eq 0
		&& ${git_numbers[changed]} -eq 0
		&& ${git_numbers[conflicts]} -eq 0
		&& ${git_numbers[untracked]} -eq 0
	]] then
		git_flags[clean]=1
	fi
	typeset -p git_flags git_strings git_numbers
}

function git_parse_status_header() {
	local branches divergence div
	typeset -g RETURN_AHEAD RETURN_BEHIND RETURN_BRANCH
	RETURN_AHEAD=0
	RETURN_BEHIND=0
	if [[ "$1" == *'Initial commit on '* ]]; then
		RETURN_BRANCH="${1/#*'Initial commit on '/}"
		return
	fi
	if [[ "$1" == *'No commits yet on '* ]]; then
		RETURN_BRANCH="${1/#*'No commits yet on '/}"
		return
	fi
	if [[ "$1" == *'no branch'* ]]; then
		git_get_tag_or_hash
		RETURN_BRANCH="$RETURN_TAG_OR_HASH"
		return
	fi
	if [[ "$1" == *'...'* ]]; then
		# local and remote branch info
		branches=(${(s:...:)1})
		RETURN_BRANCH="${branches[1]# }"
		if [[ $#branches -ne 1 ]]; then
			# ahead or behind
			divergence="${(M)branches[2]%\[*\]}"
			divergence="${divergence#\[}"
			divergence="${divergence%\]}"
			for div in ${(s:, :)divergence}; do
				if [[ "$div" == 'ahead '* ]]; then
					RETURN_AHEAD="${div#ahead }"
				elif [[ "$div" == 'behind '* ]]; then
					RETURN_BEHIND="${div#behind }"
				fi
			done
		fi
		return
	fi
	RETURN_BRANCH="${1# }"
}

function git_get_tag_or_hash() {
	local log_string
	local refs ref
	local ret_hash ret_tag
	typeset -g RETURN_TAG_OR_HASH
	log_string="$(git log -1 --decorate=full --format="%h%d" 2> /dev/null)"
	if [[ "$log_string" == *' ('*')' ]]; then
		ret_hash="${log_string%% (*)}"
		refs="${(M)log_string%% (*)}"
		refs="${refs# \(}"
		refs="${refs%\)}"
		for ref in ${(s:, :)refs}; do
			if [[ "$ref" == 'refs/tags/'* ]]; then # git 1.7.x
				ret_tag="${ref#refs/tags/}"
			elif [[ "$ref" == 'tag: refs/tags/'* ]]; then # git 2.1.x
				ret_tag="${ref#tag: refs/tags/}"
			fi
			if [[ "$ret_tag" != "" ]]; then
				RETURN_TAG_OR_HASH="tags/$ret_tag"
				return
			fi
		done
		RETURN_TAG_OR_HASH="$ret_hash"
	fi
}

function git_prompt_completed_callback() {
	local symbol line k buffer=""
	while read -t 0 -r -u $GIT_PROMPT_DESCRIPTOR line; do
		eval $line
	done
	if [[ ${git_flags[in_repo]} -eq 1 ]]; then
		for k in $GIT_PROMPT_ORDER; do
			symbol="${GIT_PROMPT_SYMBOLS[$k]}"
			if [[ $GIT_PROMPT_INDENT_HACK -eq 1 ]]; then
				if [[ -z $TMUX_PANE ]]; then
					if [[ $k == suffix ]]; then
						symbol="%{$symbol%}"
					fi
				fi
			fi
			if [[ ${git_strings[$k]} != "" ]] then
				buffer+="$symbol${git_strings[$k]}"
			elif [[ ${git_numbers[$k]} != "" ]] then
				if [[ ${git_numbers[$k]} != 0 ]] then
					buffer+="$symbol${git_numbers[$k]}"
				fi
			elif [[ ${git_flags[$k]} != "" ]]; then
				if [[ ${git_flags[$k]} -eq 1 ]] then
					buffer+="$symbol"
				fi
			else
				buffer+="$symbol"
			fi
		done
	fi
	RPROMPT=$buffer
	zle && zle reset-prompt
}

function git_prompt_bg() {
	git_get_status >&$GIT_PROMPT_DESCRIPTOR
	kill -s USR1 $$
}

function git_prompt_hook() {
	if [[ $GIT_PROMPT_BG_PID != 0 ]]; then
		kill -s HUP $GIT_PROMPT_BG_PID > /dev/null 2>&1
	fi
	git_prompt_bg &!
	GIT_PROMPT_BG_PID=$!
}

function git_prompt_init() {
	typeset -g GIT_PROMPT_BG_PID GIT_PROMPT_DESCRIPTOR
	GIT_PROMPT_BG_PID=0
	local fifo="$GIT_PROMPT_FIFO_DIR/$$.fifo"
	mkdir -m 700 -p "$GIT_PROMPT_FIFO_DIR"
	mkfifo -m 600 $fifo
	exec {GIT_PROMPT_DESCRIPTOR}<>$fifo
	rm -f $fifo
}

function TRAPUSR1() {
	git_prompt_completed_callback
	GIT_PROMPT_BG_PID=0
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd git_prompt_hook
git_prompt_init
