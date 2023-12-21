#!/bin/sh
set -e

RESET="\\033[0m"
RED="\\033[31;1m"
GREEN="\\033[32;1m"
YELLOW="\\033[33;1m"
BLUE="\\033[34;1m"
WHITE="\\033[37;1m"

print_unsupported_platform()
{
    >&2 say_red "error: We're sorry, but it looks like Pulumi Customer Managed Deployment Agent is not supported on your platform"
    >&2 say_red "       We support 64-bit versions of Linux and macOS and are interested in supporting"
    >&2 say_red "       more platforms.  Please open an issue at https://github.com/pulumi/customer-managed-deployment-agent/issues/new/choose and"
    >&2 say_red "       let us know what platform you're using!"
}

say_green()
{
    [ -z "${SILENT}" ] && printf "%b%s%b\\n" "${GREEN}" "$1" "${RESET}"
    return 0
}

say_red()
{
    printf "%b%s%b\\n" "${RED}" "$1" "${RESET}"
}

say_yellow()
{
    [ -z "${SILENT}" ] && printf "%b%s%b\\n" "${YELLOW}" "$1" "${RESET}"
    return 0
}

say_blue()
{
    [ -z "${SILENT}" ] && printf "%b%s%b\\n" "${BLUE}" "$1" "${RESET}"
    return 0
}

say_white()
{
    [ -z "${SILENT}" ] && printf "%b%s%b\\n" "${WHITE}" "$1" "${RESET}"
    return 0
}

at_exit()
{
    # shellcheck disable=SC2181
    # https://github.com/koalaman/shellcheck/wiki/SC2181
    # Disable because we don't actually know the command we're running
    if [ "$?" -ne 0 ]; then
        >&2 say_red
        >&2 say_red "We're sorry, but it looks like something might have gone wrong during installation."
        >&2 say_red "If you need help, please join us on https://slack.pulumi.com/"
    fi
}

trap at_exit EXIT

VERSION=""
SILENT=""
while [ $# -gt 0 ]; do
    case "$1" in
        --version)
            if [ "$2" != "latest" ]; then
                VERSION=$2
            fi
            ;;
        --silent)
            SILENT="--silent"
            ;;
     esac
     shift
done

if [ -z "${VERSION}" ]; then
    VERSION=0.0.1
    # TODO: automate latest-version selection
#    # Query pulumi.com/esc/latest-version for the most recent release. Because this approach
#    # is now used by third parties as well (e.g., GitHub Actions virtual environments),
#    # changes to this API should be made with care to avoid breaking any services that
#    # rely on it (and ideally be accompanied by PRs to update them accordingly).
#
#    if ! VERSION=$(curl --retry 3 --fail --silent -L "https://www.pulumi.com/esc/latest-version"); then
#        >&2 say_red "error: could not determine latest version of Pulumi ESC, try passing --version X.Y.Z to"
#        >&2 say_red "       install an explicit version"
#        exit 1
#    fi
fi

OS=""
case $(uname) in
    "Linux") OS="linux";;
    "Darwin") OS="darwin";;
    *)
        print_unsupported_platform
        exit 1
        ;;
esac

ARCH=""
case $(uname -m) in
    "x86_64") ARCH="x64";;
    "arm64") ARCH="arm64";;
    "aarch64") ARCH="arm64";;
    *)
        print_unsupported_platform
        exit 1
        ;;
esac

TARBALL_URL="https://github.com/pulumi/customer-managed-deployment-agent/releases/download/v${VERSION}/"
#TARBALL_URL_FALLBACK="https://get.pulumi.com/esc/releases/"
TARBALL_PATH=customer-managed-deployment-agent-v${VERSION}-${OS}-${ARCH}.tar.gz

if ! command -v customer-managed-deployment-agent >/dev/null; then
    say_blue "=== Installing Customer Managed Deployment Agent v${VERSION} ==="
else
    say_blue "=== Upgrading Customer Managed Deployment Agent $(customer-managed-deployment-agent version) to v${VERSION} ==="
fi

TARBALL_DEST=$(mktemp -t cmda.tar.gz.XXXXXXXXXX)

download_tarball() {
    # Try to download from github first, then fallback to get.pulumi.com
    say_white "+ Downloading ${TARBALL_URL}${TARBALL_PATH}..."
    # This should opportunistically use the GITHUB_TOKEN to avoid rate limiting
    # ...I think. It's hard to test accurately. But it at least doesn't seem to hurt.
    if ! curl --fail ${SILENT} -L \
        --header "Authorization: Bearer $GITHUB_TOKEN" \
        -o "${TARBALL_DEST}" "${TARBALL_URL}${TARBALL_PATH}"; then
            return 1
    fi
#    if ! curl --fail ${SILENT} -L \
#        --header "Authorization: Bearer $GITHUB_TOKEN" \
#        -o "${TARBALL_DEST}" "${TARBALL_URL}${TARBALL_PATH}"; then
#        say_white "+ Error encountered, falling back to ${TARBALL_URL_FALLBACK}${TARBALL_PATH}..."
#        if ! curl --retry 2 --fail ${SILENT} -L -o "${TARBALL_DEST}" "${TARBALL_URL_FALLBACK}${TARBALL_PATH}"; then
#            return 1
#        fi
#    fi
}

if download_tarball; then
    say_white "+ Extracting to $HOME/.pulumi/bin/customer-managed-deployment-agent"

    # If `~/.pulumi/bin/customer-managed-deployment-agent exists`, remove the existing files.
    # Note: handle files explicitly to avoid removing any existing configuration file
    if [ -e "${HOME}/.pulumi/bin/customer-managed-deployment-agent" ]; then
        rm -f "${HOME}/.pulumi/bin/customer-managed-deployment-agent/customer-managed-deployment-agent"
        rm -f ${HOME}/.pulumi/bin/customer-managed-deployment-agent/workflow-runner*
        rm -f "${HOME}/.pulumi/bin/customer-managed-deployment-agent/pulumi-deployment-agent.yaml.sample"
    fi

    mkdir -p "${HOME}/.pulumi/bin/customer-managed-deployment-agent"

    # Yarn's shell installer does a similar dance of extracting to a temp
    # folder and copying to not depend on additional tar flags
    EXTRACT_DIR=$(mktemp -dt cmda.XXXXXXXXXX)
    tar zxf "${TARBALL_DEST}" -C "${EXTRACT_DIR}"

    cp ${EXTRACT_DIR}/customer-managed-deployment-agent/* "${HOME}/.pulumi/bin/customer-managed-deployment-agent/"

    rm -f "${TARBALL_DEST}"
    rm -rf "${EXTRACT_DIR}"
else
    >&2 say_red "error: failed to download ${TARBALL_URL}"
    >&2 say_red "       check your internet and try again; if the problem persists, file an"
    >&2 say_red "       issue at https://github.com/pulumi/customer-managed-deployment-agent/issues/new/choose"
    exit 1
fi

# Now that we have installed the Customer Managed Deployment Agent, if it is not already on the path, let's add a line
# to the user's profile to add the folder to the PATH for future sessions.
if ! command -v customer-managed-deployment-agent >/dev/null; then
    # If we can, we'll add a line to the user's .profile adding $HOME/.pulumi/bin/customer-managed-deployment-agent to the PATH
    SHELL_NAME=$(basename "${SHELL}")
    PROFILE_FILE=""

    case "${SHELL_NAME}" in
        "bash")
            # Terminal.app on macOS prefers .bash_profile to .bashrc, so we prefer that
            # file when trying to put our export into a profile. On *NIX, .bashrc is
            # preferred as it is sourced for new interactive shells.
            if [ "$(uname)" != "Darwin" ]; then
                if [ -e "${HOME}/.bashrc" ]; then
                    PROFILE_FILE="${HOME}/.bashrc"
                elif [ -e "${HOME}/.bash_profile" ]; then
                    PROFILE_FILE="${HOME}/.bash_profile"
                fi
            else
                if [ -e "${HOME}/.bash_profile" ]; then
                    PROFILE_FILE="${HOME}/.bash_profile"
                elif [ -e "${HOME}/.bashrc" ]; then
                    PROFILE_FILE="${HOME}/.bashrc"
                fi
            fi
            ;;
        "zsh")
            if [ -e "${ZDOTDIR:-$HOME}/.zshrc" ]; then
                PROFILE_FILE="${ZDOTDIR:-$HOME}/.zshrc"
            fi
            ;;
    esac

    if [ -n "${PROFILE_FILE}" ]; then
        LINE_TO_ADD="export PATH=\$PATH:\$HOME/.pulumi/bin/customer-managed-deployment-agent"
        if ! grep -q "# add Pulumi Customer Managed Deployment Agent to the PATH" "${PROFILE_FILE}"; then
            say_white "+ Adding \$HOME/.pulumi/bin/customer-managed-deployment-agent to \$PATH in ${PROFILE_FILE}"
            printf "\\n# add Pulumi Customer Managed Deployment Agent to the PATH\\n%s\\n" "${LINE_TO_ADD}" >> "${PROFILE_FILE}"
        fi

        EXTRA_INSTALL_STEP="+ Please restart your shell or add $HOME/.pulumi/bin/customer-managed-deployment-agent to your \$PATH"
    else
        EXTRA_INSTALL_STEP="+ Please add $HOME/.pulumi/bin/customer-managed-deployment-agent to your \$PATH"
    fi
elif [ "$(command -v customer-managed-deployment-agent)" != "$HOME/.pulumi/bin/customer-managed-deployment-agent/customer-managed-deployment-agent" ]; then
    say_yellow
    say_yellow "warning: Pulumi Customer Managed Deployment Agent has been installed to $HOME/.pulumi/bin/customer-managed-deployment-agent, but it looks like there's a different copy"
    say_yellow "         on your \$PATH at $(dirname "$(command -v customer-managed-deployment-agent)"). You'll need to explicitly invoke the"
    say_yellow "         version you just installed or modify your \$PATH to prefer this location."
fi

say_blue
say_blue "=== Pulumi Customer Managed Deployment Agent is now installed! ==="
if [ "$EXTRA_INSTALL_STEP" != "" ]; then
    say_white "${EXTRA_INSTALL_STEP}"
fi
say_green "+ Get started with Pulumi Customer Managed Deployment Agent: https://github.com/pulumi/customer-managed-deployment-agent/blob/main/README.md"
