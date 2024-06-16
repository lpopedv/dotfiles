# Dotfiles
Este repositório contém minhas configurações pessoais para diversas ferramentas utilizando GNU stow para facilitar o gerenciamento e setup em outros dispositivos.

## O que é GNU Stow?
GNU Stow é uma ferramenta de gerenciamento de pacotes symlink, que facilita a instalação de pacotes de software criando links simbólicos em diretórios de destino a partir de um diretório central. Isso permite manter os arquivos de configuração organizados em um único lugar e simplifica o processo de configuração em novos sistemas.

## Ferramentas Gerenciadas
- **Alacritty**: Terminal acelerado por GPU
- **i3**: Gerenciador de janelas 
- **nvim (Neovim)**: Editor de texto
- **Picom**: Um compositor de composição de janelas X (transparência, sombras, animações com i3)
- **Polybar**: Barra de status utilizada com o i3
- **tmux**: Um multiplexador de terminais

## Instalação
Para instalar as configurações, siga estas etapas:

1. Clone este repositório para o seu diretório home:
    ```bash
    git clone https://github.com/lpopedv/dotfiles ~/dotfiles
    ```

2. Navegue até o diretório `dotfiles`:
    ```bash
    cd ~/dotfiles
    ```

3. Use o GNU Stow para criar links simbólicos para os arquivos de configuração desejados:
    ```bash
    stow alacritty
    stow i3
    stow nvim
    stow picom
    stow polybar
    stow tmux
    ```

## Desinstalação
Para remover as configurações, navegue até o diretório `dotfiles` e use o comando `stow -D` seguido do nome do pacote:
```bash
cd ~/dotfiles
stow -D alacritty
stow -D i3
stow -D nvim
stow -D picom
stow -D polybar
stow -D tmux

