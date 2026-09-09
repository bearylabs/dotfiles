;;; $DOOMDIR/wsl.el -*- lexical-binding: t; -*-

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

;; WSLg only, terminal frames: a terminal cannot transmit Ctrl+Space as
;; `C-SPC'. It sends the NUL byte, which Emacs reads as `C-@' -- a genuinely
;; different event, `(kbd "C-SPC")' being [67108896] against `(kbd "C-@")' being
;; "\0" -- so the binding above is never reached under `emacs -nw' and the
;; leader is unreachable there for the same reason it is under WSLg's GUI.
;; Mirror it onto `C-@'.
;;
;; That costs `company-complete-common', which the GUI branch above keeps on
;; `C-@' precisely because the two keys are distinct there. In a terminal they
;; are not, and the leader is worth more than the completion key.
;;
;; Registered on `tty-setup-hook', which config.el runs by hand at its end --
;; the hook does not fire on its own for the frame `emacs -nw' starts in.
(when (file-exists-p "/mnt/wslg")
  (add-hook! 'tty-setup-hook
    (defun +wsl-tty-alt-leader-h ()
      (map! :i "C-@" nil)
      (evil-define-key* '(insert emacs) general-override-mode-map
        (kbd "C-@") 'doom/leader))))

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
;; parted ways above. Doom registers them as key-based replacements over the
;; literal key sequence (see `doom--define-leader-key'), so a description only
;; renders under the exact prefix it was stored with.
;;
;; Three prefixes can reach the leader: `M-SPC' is the stock alt leader,
;; `C-SPC' what this file makes it in a graphical frame, and `C-@' what a
;; terminal actually delivers for Ctrl+Space. Which one Doom stored depends on
;; whether it read `doom-leader-alt-key' before or after this file -- as of now
;; it stores `C-SPC' and there are no `M-SPC' entries left at all, which is why
;; this copies from whichever prefix is populated instead of assuming one.
;; Runs last so it also catches the leader keys config.el binds.
(when (file-exists-p "/mnt/wslg")
  (after! which-key
    (dolist (src '("\\`M-SPC " "\\`C-SPC "))
      (dolist (dst '("\\`C-SPC " "\\`C-@ "))
        (unless (equal src dst)
          (dolist (entry (copy-sequence which-key-replacement-alist))
            (let ((key (car-safe (car entry))))
              (when (and (stringp key) (string-prefix-p src key))
                ;; `cl-pushnew', so a second load of this file -- `doom/reload'
                ;; resets the alist first, a bare `load' does not -- cannot
                ;; stack another copy of every entry on top.
                (cl-pushnew (cons (cons (concat dst (substring key (length src)))
                                        (cdr (car entry)))
                                  (cdr entry))
                            which-key-replacement-alist
                            :test #'equal)))))))))

;; WSLg only, terminal frames: a Nerd Font glyph is wider than its cell, and
;; Windows Terminal draws the overhang only while the next cell is blank --
;; otherwise it clips. treemacs pads every icon with a separator (see
;; `treemacs-nerd-icons'), which is why its icons come out whole; doom-modeline
;; butts its icons straight against the text, so those are the ones cut off.
;; Pad them the same way.
;;
;; WSL-only because this is a property of the terminal, not of Emacs: Ghostty,
;; on the bare-metal machine, recognises the Nerd Font codepoint ranges and
;; fits such glyphs into the cell itself, so the same font needs no padding
;; there and would only gain a stray space.
;;
;; Also pointless with the "Mono" cut of the font, whose glyphs are scaled down
;; to a single cell and never overhang in the first place.
(defun +wsl-tty-pad-nerd-icon-a (icon)
  "Give ICON a trailing space so Windows Terminal may draw its overhang."
  (if (and (stringp icon)
           (not (string-empty-p icon))
           (not (string-suffix-p " " icon)))
      (concat icon " ")
    icon))

(when (file-exists-p "/mnt/wslg")
  (add-hook! 'tty-setup-hook
    (defun +wsl-tty-pad-modeline-icons-h ()
      ;; Named function, so a second run of the hook re-adds nothing.
      (advice-add 'doom-modeline-icon :filter-return #'+wsl-tty-pad-nerd-icon-a)
      (advice-add 'doom-modeline-icon-for-buffer :filter-return
                  #'+wsl-tty-pad-nerd-icon-a))))

;; WSLg only, terminal frames: yanking text copied in Windows.
;;
;; `:os tty +osc' installs clipetty, and clipetty is copy-only -- it sets
;; `interprogram-cut-function' to push kills out over OSC 52 and never touches
;; `interprogram-paste-function'. OSC 52 does have a read half, but terminals
;; refuse to implement it (any escape sequence in command output could then
;; exfiltrate the clipboard), Windows Terminal included. A tty frame also opens
;; no X connection of its own, so `gui-get-selection' -- what the WSLg GUI frame
;; uses -- is unavailable here too. That leaves the kill ring as the only source
;; a yank has, which is why `p' keeps handing back the last text killed inside
;; Emacs however often the Windows clipboard changes. The direction that works
;; is the one clipetty covers.
;;
;; Pasting inside vterm/ghostel looks like it works only because that goes
;; through the terminal, not through Emacs: Windows Terminal's own paste types
;; the text into the pty as a bracketed paste, and the child program inserts it.
;; Nothing consults the kill ring on that path.
;;
;; WSLg mirrors the Windows clipboard onto XWayland's CLIPBOARD selection, so
;; `xsel' can read it from the Linux side without leaving WSL: ~3ms per call,
;; against ~800ms for `powershell.exe -Command Get-Clipboard'. Only the paste
;; half is replaced; kills keep leaving through clipetty's OSC 52, which also
;; works over ssh and outside WSLg.
;;
;; The bridge hands the line endings over as Windows wrote them, so the text
;; arrives with CRLF and has to be converted. It also drops the very last byte
;; when that is a newline: copying one full line in a browser yields
;; "text\r", not "text\r\n". Turning the leftover lone CR into a newline
;; puts that break back rather than inventing one.
;;
;; `interprogram-paste-function' is a global, not frame-local, so under a daemon
;; serving a GUI frame as well this routes its yanks through xsel too. Same
;; clipboard, one subprocess instead of a native selection request.

(defvar +wsl-tty-last-clipboard nil
  "Text `+wsl-tty-clipboard-paste' returned last, to avoid repeating it.")

(defun +wsl-tty-clipboard-paste ()
  "Return the Windows clipboard, read through WSLg's X CLIPBOARD selection.
Returns nil when the text is unchanged since the last call or already sits
at the head of the kill ring; `current-kill' pushes whatever comes back onto
the ring, so returning it twice would stack duplicates."
  (when-let* ((xsel (executable-find "xsel"))
              ;; stderr discarded: with no X server reachable xsel writes a
              ;; diagnostic and exits, and an empty result falls back to the
              ;; kill ring on its own.
              (text (with-output-to-string
                      (with-current-buffer standard-output
                        (call-process xsel nil '(t nil) nil
                                      "--clipboard" "--output")))))
    (setq text (string-replace "\r" "\n" (string-replace "\r\n" "\n" text)))
    (unless (or (string-empty-p text)
                (equal text +wsl-tty-last-clipboard)
                (equal text (car kill-ring)))
      (setq +wsl-tty-last-clipboard text))))

(when (file-exists-p "/mnt/wslg")
  (add-hook! 'tty-setup-hook
    (defun +wsl-tty-clipboard-paste-h ()
      (setq interprogram-paste-function #'+wsl-tty-clipboard-paste))))
