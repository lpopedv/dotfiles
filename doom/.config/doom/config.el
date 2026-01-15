;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;;;; Basic settings
(setq user-full-name "Lucas Pope"
      user-mail-address "lpopedv@proton.me")

(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 17)
      doom-variable-pitch-font (font-spec :family "JetBrainsMono Nerd Font" :size 16))

(setq display-line-numbers-type 'relative)

;; Set Fish as default shell
(setq shell-file-name "/usr/bin/fish"
      explicit-shell-file-name "/usr/bin/fish")

;; Theme
(setq doom-theme 'doom-gruvbox)

;; Background transparency
(when (display-graphic-p)
  (set-frame-parameter (selected-frame) 'alpha '(95 . 95))
  (add-to-list 'default-frame-alist '(alpha . (95 . 95))))

;; Remove title bar (window decorations)
(add-to-list 'default-frame-alist '(undecorated . t))


;;;; Custom bidings

;; Move with vim keys in insert mode
(after! evil 
  (evil-define-key 'insert 'global
    (kbd "C-h") 'backward-char
    (kbd "C-j") 'evil-next-line
    (kbd "C-k") 'evil-previous-line
    (kbd "C-l") 'forward-char))

;; Vterm escape key handler - send ESC to terminal with C-c c q
(after! vterm 
  (define-key vterm-mode-map (kbd "C-c c q") 'vterm-send-escape))

;;;; Languages settings

;; JavaScript/TypeScript - Biome formatter
(use-package! biomejs-format
  :hook ((js-mode js2-mode typescript-mode typescript-tsx-mode web-mode) . biomejs-format-mode))

;; Elixir
(setq flycheck-elixir-credo-strict t)
(setq lsp-elixir-fetch-deps t)

;; LSP
(setq lsp-enable-file-watchers t)
(setq lsp-file-watch-threshold 20000)
(setq vterm-max-scrollback 100000)

