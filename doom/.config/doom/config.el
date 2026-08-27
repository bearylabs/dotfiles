;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "John Doe"
      user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:

(setq doom-font (font-spec :family "JetBrains Mono Nerd Font" :size 13 :weight 'medium)
      doom-variable-pitch-font (font-spec :family "JetBrains Mono Nerd Font" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'catppuccin)
(setq catppuccin-flavor 'macchiato) ; or 'frappe 'latte, 'macchiato, or 'mocha
(load-theme 'catppuccin t)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")
;; you can customize your rss feed at ~/org/elfeed.org. This works because I'm
;; using +org with my rss plugin. Check out
;; https://github.com/remyhonig/elfeed-org to see an example.


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; use system clipboard
(require 'pbcopy)
(turn-on-pbcopy)

;; Emacs spawns child processes through `shell-file-name'. Fish is not POSIX
;; compliant, so anything that shells out (diff-hl, TRAMP, magit) breaks with
;; it; keep that on bash and give the interactive terminals fish.
(setq shell-file-name (executable-find "bash"))
(setq-default vterm-shell "/run/current-system/sw/bin/fish")
(setq-default explicit-shell-file-name "/run/current-system/sw/bin/fish")

;; Let the cursor shape report the evil state inside vterm. vterm reassigns
;; `cursor-type' from the child process' DECSCUSR escape on every redraw, which
;; overwrites whatever evil set on the last state change; rebinding the variable
;; around the redraw throws that away and leaves evil in charge.
(setq evil-normal-state-cursor 'box
      evil-insert-state-cursor 'bar
      evil-visual-state-cursor 'hollow
      evil-replace-state-cursor 'hbar)

(defun +vterm-keep-evil-cursor-a (fn &rest args)
  "Run FN with ARGS without letting it clobber `cursor-type'."
  (let ((cursor-type cursor-type))
    (apply fn args)))

(after! vterm
  (advice-add #'vterm--redraw :around #'+vterm-keep-evil-cursor-a))

;; C-c/C-v act as copy/paste in vterm insert state, mirroring normal terminal
;; emulators. C-c only copies when a region is active (e.g. mouse-selected
;; text); otherwise it falls through to the terminal as SIGINT, since that's
;; the behavior you actually want most of the time in a shell.
(defun +vterm/ctrl-c-copy-or-interrupt ()
  "Copy the active region, or send C-c to the terminal if none is active."
  (interactive)
  (if (region-active-p)
      (progn
        (kill-ring-save (region-beginning) (region-end))
        (deactivate-mark))
    (vterm-send-key "c" nil nil t)))

(defun +vterm/ctrl-v-paste ()
  "Paste the kill-ring/clipboard into the terminal."
  (interactive)
  (vterm-yank))

(map! :map vterm-mode-map
      :i "C-c" #'+vterm/ctrl-c-copy-or-interrupt
      :i "C-v" #'+vterm/ctrl-v-paste)

;; remove LSP delays
(after! flycheck (setq flycheck-idle-change-delay 0.1))
(after! lsp-mode
  (setq lsp-idle-delay 0.1)
  (setq lsp-completion-enable-additional-text-edit t)
  (setq lsp-modeline-code-actions-enable t))

;; load go-specific dap package
;; (after! dap-mode
;;   (require 'dap-dlv-go)
;;   (dap-ui-mode 1)
;;   (dap-tooltip-mode 1))

;; Better debugging
(use-package! dape)

;; Always give a switched-to project its own workspace. The default,
;; `non-empty', only creates one when the current workspace already has
;; buffers; an empty workspace gets renamed instead, so escaping the
;; find-file prompt after `SPC p p' leaves every project sharing a single
;; workspace and losing its buffers on the next switch.
;; (setq +workspaces-on-switch-project-behavior t)

;; Load WSLg specific config
(when (file-exists-p "/mnt/wslg")
  (load! "wsl.el"))
