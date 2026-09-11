;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(let ((mise-shims (expand-file-name "~/.local/share/mise/shims")))
  (add-to-list 'exec-path mise-shims)
  (setenv "PATH" (concat mise-shims ":" (getenv "PATH"))))

(setq user-full-name "Lucas Pope"
      user-mail-address "lpopedv@proton.me")

(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 17)
      doom-variable-pitch-font (font-spec :family "JetBrainsMono Nerd Font" :size 16))

(setq display-line-numbers-type 'relative)

(setq shell-file-name (executable-find "zsh")
      explicit-shell-file-name (executable-find "zsh"))

(setq doom-theme 'doom-ayu-dark)

;; Icon is unreadable on themes like gruvbox; text state is not.
(after! doom-modeline
  (setq doom-modeline-modal-icon nil))

(setq emojify-display-style 'unicode)

(add-to-list 'default-frame-alist '(undecorated . t))

(after! evil
  (evil-define-key 'insert 'global
    (kbd "C-h") 'backward-char
    (kbd "C-j") 'evil-next-line
    (kbd "C-k") 'evil-previous-line
    (kbd "C-l") 'forward-char))

(after! vterm
  (define-key vterm-mode-map (kbd "C-c c q") 'vterm-send-escape))

(use-package! biomejs-format
  :hook ((js-mode js2-mode typescript-mode typescript-tsx-mode web-mode) . biomejs-format-mode))

(setq flycheck-elixir-credo-strict t)
(setq lsp-elixir-fetch-deps nil)

(setq lsp-enable-file-watchers t)
(setq lsp-file-watch-threshold 20000)
(setq vterm-max-scrollback 100000)

(use-package! mermaid-mode
  :config
  (setq mermaid-mmdc-location (string-trim (shell-command-to-string "which mmdc")))
  (setq mermaid-output-format ".png")
  (setq mermaid-flags "-s 3 -b white"))
