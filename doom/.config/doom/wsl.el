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


