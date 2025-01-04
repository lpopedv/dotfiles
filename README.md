# Dotfiles

This repository contains my personal configurations for various tools using GNU Stow to simplify management and setup on other devices.

## What is GNU Stow?

GNU Stow is a symlink package management tool that simplifies the installation of software packages by creating symbolic links in target directories from a central directory. This allows configuration files to be organized in one place and simplifies the setup process on new systems.

## Managed Tools

- **nvim (Neovim)**: Text editor
- **Kitty**: GPU-accelerated terminal
- **doom emacs**: Text editor

## Installation

To install the configurations, follow these steps:

1. Clone this repository to your home directory:

    ```bash
    git clone https://github.com/lpopedv/dotfiles ~/Dotfiles
    ```

2. Navigate to the `dotfiles` directory:

    ```bash
    cd ~/Dotfiles
    ```

3. Use GNU Stow to create symbolic links for the desired configuration files:

    ```bash
    stow nvim
    stow kitty
    stow doom
    ```

## Uninstallation

To remove the configurations, navigate to the `dotfiles` directory and use the `stow -D` command followed by the package name:

```bash
cd ~/Dotfiles
stow -D nvim
stow -D kitty
stow -D doom
```
