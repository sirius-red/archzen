FROM archlinux:base-devel

RUN pacman -Syu --noconfirm

RUN pacman -S --noconfirm --needed git vim uv

RUN curl -L https://sirius-red.github.io/aurbuilder/install | sh

RUN command -v aurbuilder && aurbuilder install -y yay nvm
