#!/bin/bash
# validate neovim package installation on python2/3 and automatically install if missing

RED="\033[0;31m";
GREEN="\033[0;32m";
YELLOW="\033[0;33m";
WHITE="\033[1;37m";
CYAN="\033[0;36m";
RESET="\033[0m";

_version_check() {
    curver="${1/v/}"; targetver="$2";
    [ "$targetver" = "$(echo -e "$curver\n$targetver" | sort -V | head -n1)" ]
}
NVIM_MINIMUM_VERSION="0.5.1"

if which nvim >/dev/null && _version_check "$(nvim --version | head -n1 | cut -d' ' -f2)" "$NVIM_MINIMUM_VERSION"; then
    echo -e "neovim found at ${GREEN}$(which nvim)${RESET}"
    host_python3=""
    [[ -z "$host_python3" ]] && [[ -f "/usr/local/bin/python3" ]] && host_python3="/usr/local/bin/python3"
    [[ -z "$host_python3" ]] && [[ -f "/usr/bin/python3" ]]       && host_python3="/usr/bin/python3"
    [[ -z "$host_python3" ]] && host_python3="$(which python3)"
    if [[ -z "$host_python3" ]]; then
        echo -e "${RED}  Python3 not found -- please have it installed in the system! ${RESET}";
        exit 1;
    fi
    suggest_cmds=()
    for py_bin in "$host_python3" "/usr/bin/python"; do
        echo -e "Checking neovim package for the host python: ${GREEN}${py_bin}${RESET}"
        neovim_ver=$($py_bin -c 'import pynvim; print("{major}.{minor}.{patch}".format(**pynvim.VERSION.__dict__))')
        neovim_install_cmd="$py_bin -m pip install --user --upgrade pynvim"
        rc=$?; if [[ $rc != 0 ]]; then
            echo -e "${YELLOW}[!!!] Neovim requires 'pynvim' package on the host python. Try:${RESET}"
            echo -e "${YELLOW}  $neovim_install_cmd${RESET}";
            suggest_cmds+=("$neovim_install_cmd")
        else  # check neovim is up-to-date
            neovim_latest=$(python2 -c 'from xmlrpclib import ServerProxy; print(\
                ServerProxy("http://pypi.python.org/pypi").package_releases("pynvim")[0])')
            if [[ "$neovim_ver" != "$neovim_latest" ]]; then
                echo -e "${YELLOW}  [!!] Neovim ($neovim_ver) is outdated (latest = $neovim_latest). Needs upgrade!${RESET}"
                echo -e "${YELLOW}  $neovim_install_cmd${RESET}"
                suggest_cmds+=("$neovim_install_cmd")
            else
                echo -e "${GREEN}  [OK] pynvim $neovim_ver${RESET}"
            fi
        fi
    done
    for cmd in "${suggest_cmds[@]}"; do
        echo -e "\n${CYAN}Executing:${WHITE} $cmd ${RESET}"
        $cmd;
    done
else
    if [ `uname` == "Darwin" ]; then
        NEOVIM_INSTALL_CMD="brew install neovim"
    else
        NEOVIM_INSTALL_CMD="dotfiles install neovim"
    fi
    if ! which nvim >/dev/null; then
        echo -e "${RED}Neovim not found."
    else
        echo -e "${RED}Neovim is too old (recommended >= $NVIM_MINIMUM_VERSION): $(nvim --version | head -1)"
    fi
    echo -e "Please install using '${NEOVIM_INSTALL_CMD}'.${RESET}"

    # Automatically install dotfiles upon confirmation (Linux only)
    if [[ -n "$BASH_VERSION" ]] && [ `uname` == "Linux" ]; then
        while true; do
            echo -en "${YELLOW}Do you want to install neovim locally [y/N] ${RESET}"
            [ -t 1 ] && read -t 5 -p "(wait 5 secs for auto-yes) ? " user_prompt;
            if [ $? -ne 0 ]; then user_prompt="y"; fi  # when timeout, yes
            case $user_prompt in
                [YyNn]* ) break;;
                *) echo "Please answer yes or no.";;
            esac
        done
        if [[ "$user_prompt" == [Yy]* ]]; then
            echo -e "\n${GREEN}Installing neovim into ~/.local/bin/ ...${RESET}";
            $HOME/.dotfiles/bin/dotfiles install neovim && exit 0;
        fi
    fi

    exit 1;
fi
