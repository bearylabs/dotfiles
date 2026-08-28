;;; $DOOMDIR/wsl.el -*- lexical-binding: t; -*-

;; WSLg only: drop window decorations and go edge-to-edge.
;; `undecorated' alone leaves a black margin where WSLg still reserves room
;; for the decorations and shadow it no longer draws; `fullboth' sizes the
;; frame to the whole monitor, which hides that margin. Side effect there:
;; the frame covers Zebar. Left disabled: a WSLg window never forwards a
;; resize to the Linux side anyway, so the window manager can only move it,
;; and at its natural size it already renders unclipped. Bare-metal Linux
;; keeps normal decorations and a normally sized frame.
(when (file-exists-p "/mnt/wslg")
  (add-to-list 'default-frame-alist '(undecorated . t))
  (add-to-list 'initial-frame-alist '(undecorated . t))
  (add-to-list 'default-frame-alist '(fullscreen . fullboth))
  (add-to-list 'initial-frame-alist '(fullscreen . fullboth)))

;; WSLg only: `C-x' does what `M-x' does everywhere else. The Windows host
;; swallows Alt-x before WSLg forwards it, so the extended-command prompt is
;; unreachable there; on bare-metal Linux `M-x' works and `C-x' stays the
;; stock `ctl-x-map' prefix. Bound in every evil state, since a plain
;; `global-set-key' is shadowed by the evil state maps. `C-x' is a prefix in
;; stock Emacs, so `ctl-x-map' moves to `C-c x' (C-c x C-s to save, ...).
(when (file-exists-p "/mnt/wslg")
  (map! :gnvime "C-c x" ctl-x-map
        :gnvime "C-x" #'execute-extended-command))

;; WSLg only: `C-SPC' as the alternate leader, for the same reason -- the
;; Windows host eats Alt-SPC (its window menu) before WSLg sees it, so the
;; leader is unreachable from insert and emacs states, i.e. in vterm and
;; anywhere else `SPC' has to stay a literal space. Costs `set-mark-command'
;; in those states; `v' in normal state still starts a selection.
(when (file-exists-p "/mnt/wslg")
  (setq doom-leader-alt-key "C-SPC"
        doom-localleader-alt-key "C-SPC m")
  ;; :completion company claims `C-SPC' in insert state (config/default's
  ;; +evil-bindings.el), and that evil state map wins over the leader's
  ;; `general-override-mode-map', so in a buffer without company-mode the key
  ;; only reports "company not enabled in this buffer". Drop it; `C-@' keeps
  ;; company-complete-common, and both keys are distinct under WSLg's GUI.
  (map! :i "C-SPC" nil)
  ;; The `setq' above only lands on a cold start, since Doom installs the
  ;; leader from `doom-after-init-hook'; `doom/reload' re-runs this file long
  ;; after that hook. Bind it here too, the same way Doom does, so a reload is
  ;; enough. `doom/leader' is the prefix command for `doom-leader-map'.
  (evil-define-key* '(insert emacs) general-override-mode-map
    (kbd "C-SPC") 'doom/leader))

;; WSLg only: this is the machine carrying an envvar file. `doom env' dumps the
;; whole shell environment into it and Emacs loads that at startup, so a dump
;; taken from inside a Claude Code session -- easy to take now that ghostel is
;; where those sessions run -- bakes in that session's CLAUDE_* variables,
;; CLAUDE_CODE_CHILD_SESSION among them. Every terminal Emacs spawns afterwards
;; inherits the set, and the next `claude' takes itself for a subprocess of a
;; session that exited long ago: it treats the marker as inherited and turns off
;; transcript saving. `doom-env-deny' is the fix on the generating side, but
;; nothing loads $DOOMDIR/cli.el in Doom 3 (bin/doom's own help text
;; notwithstanding), so scrub on this side instead -- whatever the envvar file
;; holds, `process-environment' is clean before a terminal can copy it. The
;; stale CLAUDE_CODE_MESSAGING_TOKEN is worth dropping on its own account.
(when (file-exists-p "/mnt/wslg")
  (dolist (var '("AI_AGENT" "CLAUDECODE" "CLAUDE_CODE_CHILD_SESSION"
                 "CLAUDE_CODE_ENTRYPOINT" "CLAUDE_CODE_EXECPATH"
                 "CLAUDE_CODE_MESSAGING_SOCKET" "CLAUDE_CODE_MESSAGING_TOKEN"
                 "CLAUDE_CODE_SESSION_ID" "CLAUDE_EFFORT" "CLAUDE_PID"))
    (setenv var nil)))

;; WSLg only: the leader's which-key labels follow the leader key, and the two
;; parted ways above. Doom registers them while the modules load, as key-based
;; replacements for the literal `SPC ...' and `M-SPC ...' sequences (see
;; `doom--define-leader-key'), which is long before this file changes the alt
;; key. The bindings do move -- `doom-init-leader-keys-h' installs them from
;; `doom-after-init-hook', after this file -- so `C-SPC' opens the leader but
;; renders it with whatever descriptions survive without a replacement. Clone
;; the `M-SPC' entries onto `C-SPC'. Runs last so it also catches the leader
;; keys config.el binds. Both prefixes are literal, so swapping them inside the
;; stored regexp is safe.
(when (file-exists-p "/mnt/wslg")
  (after! which-key
    (let ((old "\\`M-SPC ")
          (new "\\`C-SPC "))
      (dolist (entry (copy-sequence which-key-replacement-alist))
        (let ((key (car-safe (car entry))))
          (when (and (stringp key) (string-prefix-p old key))
            ;; `cl-pushnew', so a second load of this file -- `doom/reload'
            ;; resets the alist first, a bare `load' does not -- cannot stack
            ;; another copy of every entry on top.
            (cl-pushnew (cons (cons (concat new (substring key (length old)))
                                    (cdr (car entry)))
                              (cdr entry))
                        which-key-replacement-alist
                        :test #'equal)))))))
