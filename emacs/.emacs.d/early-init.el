;;; early-init.el --- Paren.Works early initialization -*- lexical-binding: t; -*-
;;; Commentary:
;; Performance tuning and UI stripping before init.el loads.
;;; Code:

;;;; ---- Garbage Collection ----
;; Max out GC threshold during startup; restore sane values after.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(defun pw/reset-gc ()
  "Restore GC defaults and collect on focus loss."
  (setq gc-cons-threshold (* 20 1024 1024)
        gc-cons-percentage 0.1)
  (when (boundp 'after-focus-change-function)
    (add-function :after after-focus-change-function
                  (lambda () (run-with-idle-timer
                              5 nil
                              (lambda () (unless (frame-focus-state)
                                          (garbage-collect))))))))

(add-hook 'emacs-startup-hook #'pw/reset-gc)

;;;; ---- File Handler Optimization ----
;; Nil out file-name-handler-alist during init; restore after.
(let ((old-file-name-handler-alist file-name-handler-alist))
  (setq vc-handled-backends nil
        file-name-handler-alist nil)
  (add-hook 'emacs-startup-hook
            (lambda ()
              (setq vc-handled-backends '(Git)
                    file-name-handler-alist
                    (delete-dups (append file-name-handler-alist
                                         old-file-name-handler-alist))))))

;;;; ---- Native Compilation ----
;; Per-host eln-cache so the same config works across machines.
(when (featurep 'native-compile)
  (let ((path (expand-file-name
               (concat "eln-cache-" (system-name) "/")
               user-emacs-directory)))
    (setq native-comp-eln-load-path (list path)
          native-compile-target-directory path)
    (startup-redirect-eln-cache path))
  (setq native-comp-async-report-warnings-errors 'silent
        native-comp-jit-compilation t
        native-compile-prune-cache t
        package-native-compile t))

(setq load-prefer-newer noninteractive)

;;;; ---- Tree-sitter Grammar Path ----
(add-to-list 'treesit-extra-load-path
             (expand-file-name "tree-sitter/" user-emacs-directory))

;;;; ---- Package Bootstrap ----
(setq package-enable-at-startup nil)
(setq site-run-file nil
      inhibit-default-init t)

;;;; ---- Process Performance ----
(setq process-adaptive-read-buffering nil
      read-process-output-max (* 4 1024 1024))

;;;; ---- UI: Strip Everything Early ----
(setq frame-inhibit-implied-resize t
      frame-resize-pixelwise t
      frame-title-format '("%b — Paren.Works"))

(setq inhibit-x-resources t
      inhibit-splash-screen t
      inhibit-startup-screen t
      inhibit-startup-message t
      inhibit-startup-buffer-menu t
      initial-scratch-message ";; Paren.Works — ()\n\n"
      server-client-instructions nil
      ring-bell-function #'ignore
      visible-bell nil
      use-dialog-box nil
      use-short-answers t
      warning-minimum-level :error)

(when (fboundp 'tool-bar-mode)   (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(menu-bar-mode -1)

(unless (memq initial-window-system '(x pgtk))
  (setq command-line-x-option-alist nil))

(modify-all-frames-parameters
 '((horizontal-scroll-bars . nil)
   (vertical-scroll-bars . nil)
   (width . (text-pixels . 1400))
   (height . (text-pixels . 900))))

;;; early-init.el ends here
