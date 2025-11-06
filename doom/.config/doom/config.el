;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Basic settings

(setq user-full-name "Lucas Pope"
      user-mail-address "lpopedv@proton.me")

(setq doom-font (font-spec :family "CaskaydiaMono Nerd Font Mono" :size 17)
      doom-variable-pitch-font (font-spec :family "CaskaydiaMono Nerd Font Mono" :size 16))

;;; Theme

(setq doom-theme 'doom-gruvbox)

(custom-set-faces! ;; Custom gruvbox colors
  '(font-lock-keyword-face :foreground "#fe8019")
  '(font-lock-string-face :foreground "#fb4934")
  '(font-lock-function-name-face :foreground "#fe8019"))
(setq display-line-numbers-type 'relative)
(setq org-directory "~/org/")

;;; Custom bidings

(after! evil ;; Move with vim keys in insert mode
  (evil-define-key 'insert 'global
    (kbd "C-h") 'backward-char
    (kbd "C-j") 'evil-next-line
    (kbd "C-k") 'evil-previous-line
    (kbd "C-l") 'forward-char))

;;; Languages settings

;; Elixir
(setq flycheck-elixir-credo-strict t)
(setq lsp-elixir-fetch-deps t)
(setq lsp-enable-file-watchers t)
(setq lsp-file-watch-threshold 20000)
(setq vterm-max-scrollback 100000)

;; LSP
(setq lsp-enable-file-watchers t)
(setq lsp-file-watch-threshold 20000)

;; Add transparency
(when (display-graphic-p)
  (set-frame-parameter (selected-frame) 'alpha '(95 . 95))
  (add-to-list 'default-frame-alist '(alpha . (95 . 95))))
