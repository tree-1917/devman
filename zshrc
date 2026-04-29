# ============================================
# Powerlevel10k Instant Prompt
# ============================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================
# Core Zsh Options (CRITICAL FOR YOUR WORKFLOW)
# ============================================
# This allows you to press Enter on "command # comment" without causing errors
setopt INTERACTIVE_COMMENTS 

# ============================================
# Oh My Zsh Setup
# ============================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# ============================================
# Completion System & Modules
# ============================================
autoload -Uz compinit && compinit
zmodload zsh/complist

# ============================================
# Snippets File Setup
# ============================================
export ZSH_SNIPPETS_FILE="$HOME/.zsh_snippets_history"

if [[ ! -f "$ZSH_SNIPPETS_FILE" ]]; then
  cat > "$ZSH_SNIPPETS_FILE" << 'EOF'
docker ps -a # Template command: command # usage for it
docker compose up -d # Run in background
docker compose down # stop docker compose 
docker logs -f # show follow logs file 
git status # find the status for current repo
git log --oneline --graph --all 
npm install # install package for nodejs project 
npm run dev # start development 
cargo build --release
python3 -m http.server 8000
EOF
fi

# ============================================
# UNIFIED SMART COMPLETERS
# ============================================

_smart_snippets_completer() {
    local cmd="${words[1]}"
    [[ -z "$cmd" ]] && return 1

    local -a insert_items display_items
    local line insert
    
    # Generate the Yellow Header for Snippets
    local header=$(print -P "%F{yellow}[[ -- snippets -- ]]%f")

    # Safely fetch lines that start with the command word
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == "$LBUFFER" ]] && continue
        
        if [[ "$line" == "$LBUFFER"* ]]; then
            insert="${line#$LBUFFER}"
            insert_items+=( "$PREFIX$insert" )
            display_items+=( "$line" )
        fi
    done < <(awk -v p="$cmd" 'index($0, p) == 1' "$ZSH_SNIPPETS_FILE" 2>/dev/null)

    if [[ ${#insert_items} -gt 0 ]]; then
        compadd -U -Q -l -d display_items -J snippets -X "$header" -- "${insert_items[@]}"
    fi
}

_smart_history_completer() {
    # Skip full-line history lookup if typing a flag
    [[ "$PREFIX" == -* ]] && return 1
    
    local cmd="${words[1]}"
    [[ -z "$cmd" ]] && return 1

    local -a insert_items display_items
    local line insert
    
    # Generate the Yellow Header for History
    local header=$(print -P "%F{yellow}[[ -- history -- ]]%f")

    while IFS= read -r line; do
        line="${(Q)line}"               
        [[ -z "$line" || "$line" == "$LBUFFER" ]] && continue

        if [[ "$line" == "$LBUFFER"* ]]; then
            insert="${line#$LBUFFER}"
            insert_items+=( "$PREFIX$insert" )
            display_items+=( "$line" )
        fi
    done < <(fc -ln 1 | awk -v p="$LBUFFER" 'index($0, p) == 1 && !seen[$0]++' | tail -n 15)

    if [[ ${#insert_items} -gt 0 ]]; then
        compadd -U -Q -l -d display_items -J history -X "$header" -- "${insert_items[@]}"
    fi
}

# The Master Wrapper: Calls EVERYTHING so they all appear in the menu
_smart_master_completer() {
    local cur="$PREFIX$SUFFIX"

    # Context: Local Files (Triggered by ./)
    if [[ "$cur" == ./* ]]; then
        # Explicitly force the Yellow Header for files
        local header=$(print -P "%F{yellow}[[ -- files -- ]]%f")
        _path_files -W . -g './*' -J files -X "$header"
        return 0
    fi

    # 1. Add matching snippets
    _smart_snippets_completer
    
    # 2. Add matching history
    _smart_history_completer
    
    # 3. Add standard completion (files, flags, branches, generic completions, etc.)
    _complete
    
    return 0 
}

# ============================================
# WIDGET SETUP
# ============================================
zle -C smart-complete menu-select _generic

# bindkey -v  # Enable Vi Mode
bindkey '^I'    smart-complete
bindkey '^[[Z'  reverse-menu-complete

# ============================================
# MENU NAVIGATION (Interactive Mode)
# ============================================
bindkey -M menuselect '^I'    menu-complete          
bindkey -M menuselect '^[[Z'  reverse-menu-complete   
bindkey -M menuselect '^M'    .accept-line           
bindkey -M menuselect '^['    send-break    

# ============================================
# ZSTYLE CONFIGURATION
# ============================================
# Tell our widget to use our master completer
zstyle ':completion:smart-complete:*' completer _smart_master_completer

# Force menu selection instantly
zstyle ':completion:*' menu select=0
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'

# Use *:*:*:*:* to GUARANTEE Docker/Git don't overwrite the Yellow Headers!
zstyle ':completion:*:*:*:*:descriptions' format '%F{yellow}[[ -- %d -- ]]%f'
zstyle ':completion:*:*:*:*:messages'     format '%F{yellow}[[ -- %d -- ]]%f'

# Generate the Red Header for warnings (no matches)
zstyle ':completion:*:*:*:*:warnings'     format '%F{red}[[ -- no matches -- ]]%f'

# ============================================
# AUTOSUGGESTIONS & HIGHLIGHTING
# ============================================
ZSH_AUTOSUGGEST_STRATEGY=(history completion snippets)

# This tells autosuggestions how to read your snippets file
_zsh_autosuggest_strategy_snippets() {
    local prefix="$1"
    local match
    match=$(awk -v p="$prefix" 'index($0, p) == 1' "$ZSH_SNIPPETS_FILE" 2>/dev/null | head -n 1)
    [[ -n "$match" ]] && typeset -g suggestion="$match"
}

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
bindkey '^ ' autosuggest-accept

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

# ============================================
# HISTORY & ALIASES
# ============================================
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

export EDITOR="vim"
alias snippets-edit="$EDITOR $ZSH_SNIPPETS_FILE && source ~/.zshrc"

# ============================================
# SNIPPET MANAGEMENT FUNCTIONS
# ============================================

# Usage: snippet-add <command> # <description>
snippet-add() {
    [[ $# -lt 2 ]] && {echo "Usage: snippet-add '<command>' '# <description>'"; return 1;}
    echo "$*" >> "$ZSH_SNIPPETS_FILE"
    echo "Snippet added."
    source ~/.zshrc
}


# Usage: snippet-rm <keyword> 
snippet-rm() {
    [[ -z "$1" ]] && {echo "Usage: snippet-rm <keyword_to_delete>"; return 1;}
    local tmp_file=$(mktemp)
    grep -v "$1" "$ZSH_SNIPPETS_FILE" > "$tmp_file"
    mv "$tmp_file" "$ZSH_SNIPPETS_FILE"
    echo "Snippet(s) containing '$1' removed."
    source ~/.zshrc
}

# Usage: snippet-upd <keyword_to_find> "new command # new usage"
snippet-upd() {
    [[ -z "$1" || -z "$2" ]] && {echo "Usage: snippet-upd <old_keyword> <'new command # usage'>"; return 1;}
    snippet-rm "$1"
    echo "$2" >> "$ZSH_SNIPPETS_FILE"
    echo "Snippet updated."
    source ~/.zshrc
} 

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

