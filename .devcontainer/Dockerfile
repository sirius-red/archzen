FROM archlinux:base-devel

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN pacman -Syu --noconfirm; \
    pacman -S --noconfirm --needed git github-cli ttf-jetbrains-mono-nerd bash-language-server shellcheck shfmt direnv; \
    curl -L https://sirius-red.github.io/aurbuilder/install | sh \
    && aurbuilder install -y yay-bin
    && aurbuilder install -y hadolint-bin
