;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "Lucas Pope"
      user-mail-address "lpopedv@proton.me")

(setq doom-font (font-spec :family "CaskaydiaMono Nerd Font" :size 17)
      doom-variable-pitch-font (font-spec :family "CaskaydiaMono Nerd Font" :size 16))

(setq doom-theme 'doom-ayu-dark)
(setq display-line-numbers-type 'relative)
(setq org-directory "~/org/")

;; Elixir
(setq flycheck-elixir-credo-strict t)
(setq lsp-elixir-fetch-deps t)

;; LSP
(setq lsp-enable-file-watchers t)
(setq lsp-file-watch-threshold 20000)

;; Move with vim keys in insert mode
(after! evil
  (evil-define-key 'insert 'global
    (kbd "C-h") 'backward-char
    (kbd "C-j") 'evil-next-line
    (kbd "C-k") 'evil-previous-line
    (kbd "C-l") 'forward-char))

(setq scroll-margin 6)

;; Completion
(use-package! orderless
  :init
  (setq orderless-matching-styles '(orderless-flex orderless-regexp)
        orderless-component-separator "[ &]"))

(after! corfu
  (setq corfu-auto t
        corfu-cycle t
        corfu-min-width 80
        corfu-max-width 100
        corfu-count 14
        corfu-separator ?\s
        corfu-quit-no-match 'separator))

(after! vertico
  (setq completion-styles '(orderless flex basic)
        completion-category-defaults nil
        vertico-count 20
        vertico-cycle t))

(after! lsp-mode
  (setq lsp-completion-provider :capf))

(when (display-graphic-p)
  (set-frame-parameter (selected-frame) 'alpha '(95 . 95))
  (add-to-list 'default-frame-alist '(alpha . (95 . 95))))

(use-package! lsp-mode
  :config
  (setq lsp-clients-elixir-server-executable '("~/.elixir-ls/language_server.sh")))

(setq shell-file-name "/usr/bin/fish")
(setq explicit-shell-file-name "/usr/bin/fish")

;; Vterm escape key handler - send ESC to terminal with C-c c q
(after! vterm
  (define-key vterm-mode-map (kbd "C-c c q") 'vterm-send-escape))

;; Biome.js formatter configuration via Apheleia
(after! apheleia
  (setf (alist-get 'biome apheleia-formatters)
        '("biome" "format" "--stdin-file-path" filepath))

  (setf (alist-get 'js-mode apheleia-mode-alist) 'biome)
  (setf (alist-get 'js2-mode apheleia-mode-alist) 'biome)
  (setf (alist-get 'typescript-mode apheleia-mode-alist) 'biome)
  (setf (alist-get 'typescript-ts-mode apheleia-mode-alist) 'biome)
  (setf (alist-get 'tsx-ts-mode apheleia-mode-alist) 'biome)
  (setf (alist-get 'rjsx-mode apheleia-mode-alist) 'biome)
  (setf (alist-get 'json-mode apheleia-mode-alist) 'biome)
  (setf (alist-get 'json-ts-mode apheleia-mode-alist) 'biome))

(setq-hook! '(js-mode-hook
              js2-mode-hook
              typescript-mode-hook
              typescript-ts-mode-hook
              tsx-ts-mode-hook
              rjsx-mode-hook
              json-mode-hook
              json-ts-mode-hook)
  +format-with-lsp nil)


;; Terminal settings (emacs -nw)
(use-package! evil-terminal-cursor-changer
  :when (not (display-graphic-p))
  :hook (tty-setup . evil-terminal-cursor-changer-activate))

(setq evil-motion-state-cursor 'box)   ; █
(setq evil-visual-state-cursor 'box)   ; █
(setq evil-normal-state-cursor 'box)   ; █
(setq evil-insert-state-cursor 'bar)   ; ⎸
(setq evil-emacs-state-cursor 'hbar)    ; _

(unless (display-graphic-p)
  (require 'term)
  (setq xterm-extra-capabilities '(setSelection getSelection))
  (when (fboundp 'evil-refresh-cursor)
    (add-hook 'post-command-hook #'evil-refresh-cursor))
  ;; Clipboard support
  (when (getenv "DISPLAY")
    (setq select-enable-clipboard t
          select-enable-primary t)))
