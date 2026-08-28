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

;; System clipboard needs no help here: this Emacs is an X11 build, so
;; `gui-get-selection' talks to XWayland, which WSLg bridges to the Windows
;; clipboard. `pbcopy' used to be loaded here, but it shells out to macOS'
;; pbpaste/pbcopy; with those missing it set `interprogram-paste-function' to
;; a function that always returns nil, which killed yanking from outside.

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
      :i "C-v" #'+vterm/ctrl-v-paste
      ;; ESC belongs to the program in the terminal (vim, less, readline's
      ;; meta prefix), not to evil. evil-collection offers this as a runtime
      ;; toggle on `C-c C-z', which `C-c' above shadows anyway; make it the
      ;; permanent state instead. Leave insert state with `C-g'.
      :i "<escape>" #'vterm--self-insert)

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

;; Doom turns on the `overlong-summary-line' check, which makes `C-c C-c'
;; stop and ask "Summary line is too long.  Commit anyway?" past 50 chars.
;; Keep the overlong tail highlighted, drop the blocking prompt.
(after! magit
  (setq git-commit-style-convention-checks '(non-empty-second-line)))

;; Treemacs only highlights files by git status out of the box, so a modified
;; file inside a collapsed directory is invisible. `deferred' propagates the
;; status up to parent directories too (async, needs python3).
(setq +treemacs-git-mode 'deferred)

;; Doom turns on path collapsing (`a/b/c' on one row) whenever git mode is
;; extended or deferred. Keep one directory per row instead.
(after! treemacs
  (setq treemacs-collapse-dirs 0)

  ;; Treemacs refreshes from file-notify events, but only after
  ;; `treemacs-file-event-delay' ms of quiet, and it only watches directories
  ;; that were expanded while `treemacs-filewatch-mode' was already on. Shorten
  ;; the debounce and push the git state of the file we just wrote ourselves, so
  ;; the highlight lands on save instead of a second later or not at all.
  (setq treemacs-file-event-delay 500
        treemacs-silent-refresh t
        treemacs-silent-filewatch t)

  (defun +treemacs-update-git-state-h ()
    "Refresh the saved file's git fontification in treemacs."
    (when (and buffer-file-name (treemacs-get-local-buffer))
      (treemacs-do-update-single-file-git-state buffer-file-name nil t)))
  (add-hook 'after-save-hook #'+treemacs-update-git-state-h)

  ;; Git operations outside Emacs (a commit in vterm, a rebase in another
  ;; window) change the status of files treemacs never sees written, and .git/
  ;; itself is not watched. Magit is covered by `treemacs-magit'; catch the rest
  ;; by refreshing when the frame regains focus.
  (defun +treemacs-refresh-on-focus-h ()
    "Refresh every treemacs project when the frame regains focus."
    (when (frame-focus-state)
      (when-let ((buf (treemacs-get-local-buffer)))
        (treemacs--do-refresh buf 'all))))
  (add-function :after after-focus-change-function #'+treemacs-refresh-on-focus-h))

;; Carries the leader key in ghostel buffers; the binding itself is made once
;; ghostel loads, below. A minor-mode map rather than `ghostel-mode-map', which
;; the input modes inherit and install with `use-local-map': which-key paints
;; every entry it can also resolve through `current-local-map' in
;; `which-key-local-map-description-face', so a leader in the local map turns
;; the whole menu that color. Minor-mode maps outrank the local map, so the key
;; still lands; char mode still wins over it, through its own
;; `emulation-mode-map-alists' entry.
(defvar-keymap +ghostel-leader-mode-map
  :doc "Keymap carrying the leader key in `ghostel-mode' buffers.")

(define-minor-mode +ghostel-leader-mode
  "Keep the Doom leader reachable in ghostel buffers."
  :keymap +ghostel-leader-mode-map)

;; Terminal for the AI TUIs (claude, copilot, codex), which draw a fixed input
;; box and scroll their own viewport. vterm cannot serve those: its module never
;; calls libvterm's mouse entry points, so a wheel event only ever scrolls the
;; Emacs window over the buffer, dragging the input box along with it. ghostel
;; forwards mouse events to the program over the SGR protocol instead. vterm
;; stays the terminal for everything else, on `SPC o t'.
(use-package! ghostel
  :commands ghostel
  :hook (ghostel-mode . +ghostel-leader-mode)
  :init
  ;; The module is a binary downloaded on first use, and it defaults to living
  ;; in the package directory -- which straight rebuilds on every `doom sync',
  ;; taking the module with it. Keep it in Doom's data dir, which survives.
  (setq ghostel-module-directory (expand-file-name "ghostel/" doom-data-dir))
  :config
  ;; `ghostel-shell' follows $SHELL, which is zsh here; the interactive
  ;; terminals get fish, same as vterm.
  (setq ghostel-shell "/run/current-system/sw/bin/fish")

  ;; `SPC' is a literal space in a terminal, so the leader is only reachable
  ;; through `doom-leader-alt-key' -- `M-SPC', or `C-SPC' under WSLg (wsl.el).
  ;; Neither arrives on its own: semi-char mode sends `M-SPC' to the program,
  ;; and deliberately leaves `C-SPC' unbound so it reaches the global map,
  ;; where it lands on `set-mark-command'. The exception stops the first, and
  ;; the binding below covers both. Char mode forwards everything by design,
  ;; leader included.
  (unless (member doom-leader-alt-key ghostel-keymap-exceptions)
    (setopt ghostel-keymap-exceptions
            (cons doom-leader-alt-key ghostel-keymap-exceptions)))
  (define-key +ghostel-leader-mode-map (kbd doom-leader-alt-key) #'doom/leader)

  ;; Without this the buffer counts as unreal (it visits no file and its name
  ;; is starred), so `+workspaces-add-current-buffer-h' never registers it with
  ;; the perspective and it is missing from `SPC ,'. `vterm-mode' is on that
  ;; list out of the box; ghostel opens in a normal window rather than a popup,
  ;; so the buffer switcher is the way back to it.
  (add-to-list 'doom-real-buffer-modes 'ghostel-mode))

;; Routes insert-state ESC to the program in alt-screen TUIs, which is what the
;; vterm block above does by hand. `C-c C-r' toggles that per buffer, `C-c
;; <escape>' reaches normal state once without changing the routing.
(use-package! evil-ghostel
  :after ghostel
  :hook (ghostel-mode . evil-ghostel-mode))

;; A bare `ghostel' pops to the existing terminal and only spawns a new one
;; under a non-numeric prefix arg, which routes `ghostel--start' to the next
;; free instance. Hand it that arg unconditionally: every press is a new
;; terminal, and the old ones stay reachable through `SPC ,'.
(map! :leader :desc "Ghostel terminal" "o G" (cmd! (ghostel '(4))))

;; Load WSLg specific config
(when (file-exists-p "/mnt/wslg")
  (load! "wsl.el"))
