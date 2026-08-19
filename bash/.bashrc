# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
# /etc/omarchy.conf is written by omarchy-dev-link. When absent, force the
# package default instead of preserving a stale inherited dev-link value before
# we decide which rc file to source.
if [[ -f /etc/omarchy.conf ]]; then
  source /etc/omarchy.conf
  export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
else
  export OMARCHY_PATH=/usr/share/omarchy
fi
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# Prioritize Cargo binaries over system binaries
export PATH="$HOME/.cargo/bin:$PATH"

# Automatically added by the Guix install script.
if [ -n "$GUIX_ENVIRONMENT" ]; then
    if [[ $PS1 =~ (.*)"\\$" ]]; then
        PS1="${BASH_REMATCH[1]} [env]\\\$ "
    fi
fi

# Guix profile configuration
GUIX_PROFILE="/home/glenn/.guix-profile"
if [ -f "$GUIX_PROFILE/etc/profile" ]; then
    . "$GUIX_PROFILE/etc/profile"
fi

# Guix current profile (for guix pull updates)
GUIX_PROFILE="/home/glenn/.config/guix/current"
if [ -f "$GUIX_PROFILE/etc/profile" ]; then
    . "$GUIX_PROFILE/etc/profile"
fi


# opencode
export PATH=/home/glenn/.opencode/bin:$PATH

export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Added by Radicle.
export PATH="$PATH:/home/glenn/.radicle/bin"
export PATH=$HOME/.local/bin:$PATH

if [[ -z "${SSH_CONNECTION}" ]]; then
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi

alias radicle='nohup radicle-desktop &'

eval "$(~/.sigil/bin/sigil cli env)"
OPAM_LAST_ENV='/home/glenn/.opam/.last-env/env-8d9f8da7686a2a925379135ddec8e375-0'; export OPAM_LAST_ENV;
OPAM_SWITCH_PREFIX='/home/glenn/.opam/default'; export OPAM_SWITCH_PREFIX;
OCAMLTOP_INCLUDE_PATH='/home/glenn/.opam/default/lib/toplevel'; export OCAMLTOP_INCLUDE_PATH;
CAML_LD_LIBRARY_PATH='/home/glenn/.opam/default/lib/stublibs:/home/glenn/.opam/default/lib/ocaml/stublibs:/home/glenn/.opam/default/lib/ocaml'; export CAML_LD_LIBRARY_PATH;
OCAML_TOPLEVEL_PATH='/home/glenn/.opam/default/lib/toplevel'; export OCAML_TOPLEVEL_PATH;
MANPATH=':/home/glenn/.opam/default/man'; export MANPATH;
PATH='/home/glenn/.opam/default/bin:/home/glenn/.sigil/bin:/home/glenn/.sigil/bin/apps:/home/glenn/.local/bin:/home/glenn/.opencode/bin:/home/glenn/.config/guix/current/bin:/home/glenn/.guix-profile/bin:/home/glenn/.cargo/bin:/home/glenn/.local/share/mise/installs/node/25.0.0/bin:/home/glenn/.local/share/omarchy/bin/:/home/glenn/.guix-profile/bin:/home/glenn/.config/guix/current/bin:/home/glenn/.guix-profile/bin:/home/glenn/.config/guix/current/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/var/lib/snapd/snap/bin:/home/glenn/.radicle/bin'; export PATH;

export PARENVAULT_DB_PASSWORD="b3l0wz3r0"
export EDITOR=nvim

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init bash)"; fi

PS1='λ \w ❯ '

export LEDGER_FILE=~/Finance/personal.ledger
