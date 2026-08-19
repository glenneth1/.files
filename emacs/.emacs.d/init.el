;;; init.el --- Paren.Works Emacs -*- lexical-binding: t; -*-
;;; Commentary:
;; A focused Common Lisp development environment with a modern Neovim feel.
;; Glenn Thompson — paren.works
;;; Code:

;;;; ========================================================================
;;;; Package Management
;;;; ========================================================================

(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))
(package-initialize)

(require 'use-package)
(setq use-package-always-ensure t)

;;;; ========================================================================
;;;; Paths & Directories
;;;; ========================================================================

(defvar pw/org-directory (expand-file-name "~/orgfiles/")
  "Root directory for all Org files.")

(defvar pw/sextant-path (expand-file-name "~/SourceCode/sextant/sextant")
  "Path to the Sextant CL language server binary.")

(defvar pw/logo-path (expand-file-name "~/Pictures/parenworks-avatar.png")
  "Path to the Paren.Works logo for dashboard.")

;; Ensure opencode is in exec-path
(add-to-list 'exec-path (expand-file-name "~/.opencode/bin/"))

;; Keep custom.el out of init.el
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file 'noerror))

;; Backups in one place
(setq backup-directory-alist
      `(("." . ,(expand-file-name "backups/" user-emacs-directory)))
      backup-by-copying t
      version-control t
      delete-old-versions t
      kept-new-versions 5
      kept-old-versions 2)

;; Auto-save files alongside backups
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "auto-saves/" user-emacs-directory) t)))
(make-directory (expand-file-name "auto-saves/" user-emacs-directory) t)

;;;; ========================================================================
;;;; Fonts
;;;; ========================================================================

;; Default monospace — Iosevka Comfy (compact, ligatures, great for code)
(set-face-attribute 'default nil
                    :family "Iosevka Comfy"
                    :height 130
                    :weight 'regular)

;; Fixed-pitch (same as default for consistency in code blocks)
(set-face-attribute 'fixed-pitch nil
                    :family "Iosevka Comfy"
                    :height 130)

;; Variable-pitch — ZedMono Nerd Font (for org prose, email, etc.)
(set-face-attribute 'variable-pitch nil
                    :family "ZedMono Nerd Font"
                    :height 130
                    :weight 'regular)

;; Ensure Nerd Font icons render correctly (fallback for symbols)
(set-fontset-font t 'symbol "Symbols Nerd Font Mono" nil 'prepend)
(set-fontset-font t 'unicode "Symbols Nerd Font Mono" nil 'append)
;; Noto Sans Symbols for alchemical, astrological, and misc Unicode symbols
(set-fontset-font t 'unicode "Noto Sans Symbols" nil 'append)

;;;; ========================================================================
;;;; Sane Defaults
;;;; ========================================================================

(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 80
              sentence-end-double-space nil)

(setq require-final-newline t
      uniquify-buffer-name-style 'forward
      scroll-margin 3
      scroll-conservatively 101
      mouse-wheel-scroll-amount '(3 ((shift) . 1))
      mouse-wheel-progressive-speed nil)

(pixel-scroll-precision-mode 1)

;; File auto-revert
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)

;; Recent files
(recentf-mode 1)
(setq recentf-max-saved-items 100)

;; Remember cursor position
(save-place-mode 1)

;; Persist history across sessions
(savehist-mode 1)

;; Allow commands to use minibuffer while in minibuffer (needed for posframe)
(setq enable-recursive-minibuffers t)
(minibuffer-depth-indicate-mode 1)

;; Show matching parens instantly
(show-paren-mode 1)
(setq show-paren-delay 0
      show-paren-style 'parenthesis)

;; Line numbers in prog modes (relative for vim feel)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(setq display-line-numbers-type 'relative)

;; Column number in modeline
(column-number-mode 1)

;; Highlight current line
(global-hl-line-mode 1)

;; Delete selection when typing
(delete-selection-mode 1)

;; Electric pairs (disabled in paredit buffers, see below)
(electric-pair-mode 1)

;; Winner mode for window layout undo
(winner-mode 1)

;; Whitespace cleanup on save
(add-hook 'before-save-hook #'whitespace-cleanup)

;; Shell file associations
(add-to-list 'auto-mode-alist '("\\.zsh\\'" . sh-mode))
(add-to-list 'auto-mode-alist '("\\.zshrc\\'" . sh-mode))

;; Terminal mouse support
(unless (display-graphic-p)
  (xterm-mouse-mode 1))

;; Start server for emacsclient
(when (display-graphic-p)
  (server-start))

;;;; ========================================================================
;;;; Evil Mode — Neovim Feel
;;;; ========================================================================

(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil    ; let evil-collection handle it
        evil-want-C-u-scroll t      ; C-u scrolls up like vim
        evil-want-C-d-scroll t
        evil-want-Y-yank-to-eol t   ; Y yanks to end of line
        evil-undo-system 'undo-redo
        evil-search-module 'evil-search
        evil-split-window-below t
        evil-vsplit-window-right t
        evil-respect-visual-line-mode t)
  :config
  (evil-mode 1)
  ;; Use Emacs state in these modes
  (dolist (mode '(custom-mode
                  eshell-mode
                  term-mode
                  sly-db-mode
                  sly-inspector-mode
                  discourse-ui-categories-mode
                  discourse-ui-topics-mode
                  discourse-ui-topic-mode))
    (add-to-list 'evil-emacs-state-modes mode)))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode 1))

(use-package evil-commentary
  :after evil
  :config
  (evil-commentary-mode))

;; SPC leader key — the Doom/Spacemacs feel
(use-package general
  :demand t
  :after evil
  :config
  (general-create-definer pw/leader
    :states '(normal visual motion)
    :keymaps 'override
    :prefix "SPC"
    :non-normal-prefix "M-SPC")

  (pw/leader
    ;; Top-level
    "SPC" '(execute-extended-command :wk "M-x")
    "."   '(find-file :wk "Find file")
    ","   '(consult-buffer :wk "Switch buffer")
    "/"   '(consult-ripgrep :wk "Ripgrep")
    ";"   '(eval-expression :wk "Eval expression")

    ;; Files
    "f"   '(:ignore t :wk "Files")
    "ff"  '(find-file :wk "Find file")
    "fr"  '(consult-recent-file :wk "Recent files")
    "fs"  '(save-buffer :wk "Save")
    "fS"  '(write-file :wk "Save as")
    "fp"  '(pw/show-file-path :wk "Copy file path")

    ;; Buffers
    "b"   '(:ignore t :wk "Buffers")
    "bb"  '(consult-buffer :wk "Switch buffer")
    "bd"  '(kill-current-buffer :wk "Kill buffer")
    "br"  '(revert-buffer :wk "Revert buffer")
    "bs"  '(save-buffer :wk "Save buffer")
    "bm"  '(bookmark-set :wk "Set bookmark")
    "bj"  '(consult-bookmark :wk "Jump to bookmark")

    ;; Windows
    "w"   '(:ignore t :wk "Windows")
    "wv"  '(evil-window-vsplit :wk "Vertical split")
    "ws"  '(evil-window-split :wk "Horizontal split")
    "wd"  '(evil-window-delete :wk "Delete window")
    "ww"  '(evil-window-next :wk "Next window")
    "wu"  '(winner-undo :wk "Undo layout")
    "wU"  '(winner-redo :wk "Redo layout")

    ;; Search
    "s"   '(:ignore t :wk "Search")
    "ss"  '(swiper :wk "Swiper search")
    "sS"  '(swiper-all :wk "Swiper all buffers")
    "sl"  '(consult-line :wk "Consult line")
    "sr"  '(consult-ripgrep :wk "Ripgrep")
    "sf"  '(consult-find :wk "Find file")
    "si"  '(consult-imenu :wk "Imenu")

    ;; Git
    "g"   '(:ignore t :wk "Git")
    "gg"  '(magit-status :wk "Magit status")
    "gb"  '(magit-blame :wk "Blame")
    "gl"  '(magit-log-current :wk "Log")

    ;; Lisp (Common Lisp / Sly)
    "l"   '(:ignore t :wk "Lisp")
    "ll"  '(sly :wk "Start Sly")
    "lc"  '(sly-connect :wk "Connect to Sly")
    "le"  '(sly-eval-last-expression :wk "Eval last sexp")
    "lb"  '(sly-eval-buffer :wk "Eval buffer")
    "ld"  '(sly-eval-defun :wk "Eval defun")
    "lr"  '(sly-restart-inferior-lisp :wk "Restart Lisp")
    "li"  '(sly-inspect :wk "Inspector")
    "lD"  '(sly-describe-symbol :wk "Describe symbol")

    ;; Mail (notmuch)
    "m"   '(:ignore t :wk "Mail")
    "mm"  '(notmuch :wk "Notmuch")
    "mi"  '(pw/notmuch-inbox :wk "Inbox")
    "mc"  '(notmuch-mua-new-mail :wk "Compose new")
    "mu"  '(pw/notmuch-sync :wk "Sync mail")
    "ms"  '(notmuch-search :wk "Search")
    "mj"  '(notmuch-jump-search :wk "Jump to search")
    "mg"  '(pw/notmuch-glenn-inbox :wk "Glenn inbox")
    "mh"  '(pw/notmuch-hello-inbox :wk "Hello inbox")

    ;; Org
    "o"   '(:ignore t :wk "Org")
    "oa"  '(org-agenda :wk "Agenda")
    "od"  '((lambda () (interactive) (org-agenda nil "d")) :wk "Dashboard")
    "on"  '((lambda () (interactive) (org-agenda nil "n")) :wk "Next Actions")
    "ow"  '((lambda () (interactive) (org-agenda nil "w")) :wk "Waiting")
    "oW"  '((lambda () (interactive) (org-agenda nil "W")) :wk "Weekly Review")
    "oc"  '(org-capture :wk "Capture")
    "ol"  '(org-store-link :wk "Store link")
    "oO"  '(pw/open-org-dir :wk "Open orgfiles")

    "oC"  '((lambda () (interactive) (org-agenda nil "C")) :wk "CMMS Board")

    ;; GTD sub-group
    "og"  '(:ignore t :wk "GTD")
    "ogc" '(org-gtd-capture :wk "GTD Capture")
    "ogp" '(org-gtd-process-inbox :wk "GTD Process inbox")
    "oge" '(org-gtd-engage :wk "GTD Engage")
    "ogn" '(org-gtd-show-all-next :wk "GTD Next actions")
    "ogs" '(org-gtd-reflect-stuck-projects :wk "GTD Stuck projects")

    ;; Project
    "p"   '(:ignore t :wk "Project")
    "pp"  '(project-switch-project :wk "Switch project")
    "pf"  '(project-find-file :wk "Find in project")
    "pb"  '(project-switch-to-buffer :wk "Project buffer")
    "pk"  '(project-kill-buffers :wk "Kill project buffers")

    ;; AI / Agent
    "a"   '(:ignore t :wk "AI Agent")
    "aa"  '(agent-shell :wk "Agent shell")
    "ao"  '(agent-shell-opencode-start-agent :wk "OpenCode agent")

    ;; Help
    "h"   '(:ignore t :wk "Help")
    "hf"  '(helpful-callable :wk "Describe function")
    "hv"  '(helpful-variable :wk "Describe variable")
    "hk"  '(helpful-key :wk "Describe key")
    "hi"  '(info :wk "Info")

    ;; Discourse
    "D"   '(:ignore t :wk "Discourse")
    "Dd"  '(discourse :wk "Open Discourse")
    "Dc"  '(discourse-connect :wk "Connect to site")
    "Ds"  '(discourse-switch-site :wk "Switch site")

    ;; CrafterBin
    "C"   '(:ignore t :wk "CrafterBin")
    "Cu"  '(crafterbin-upload :wk "Upload (region or file)")
    "Cf"  '(crafterbin-upload-file :wk "Upload file")
    "Cr"  '(crafterbin-upload-region :wk "Upload region")
    "Ck"  '(crafterbin-upload-kill-ring :wk "Upload kill ring")

    ;; Typst
    "T"   '(:ignore t :wk "Typst")
    "Tp"  '(pw/typst-live-preview :wk "Live preview")
    "Ts"  '(pw/typst-stop-preview :wk "Stop preview")
    "Tc"  '(typst-ts-compile :wk "Compile")

    ;; Toggle
    "t"   '(:ignore t :wk "Toggle")
    "tt"  '(consult-theme :wk "Switch theme")
    "tl"  '(display-line-numbers-mode :wk "Line numbers")
    "tw"  '(whitespace-mode :wk "Whitespace")
    "tz"  '(olivetti-mode :wk "Zen mode")

    ;; Quit
    "q"   '(:ignore t :wk "Quit")
    "qq"  '(save-buffers-kill-emacs :wk "Quit Emacs")))

;;;; ========================================================================
;;;; Theme — Doom Tokyo Night
;;;; ========================================================================

(use-package doom-themes
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (load-theme 'doom-tokyo-night t)
  (doom-themes-org-config)
  ;; Fix doom-themes face inheritance cycles that crash child frames on Emacs 31
  ;; (gnus faces have circular :inherit chains; break them with override specs)
  (dolist (face '(gnus-group-news-low
                  gnus-group-news-low-empty
                  gnus-group-news-low-unread))
    (face-spec-set face '((t :inherit shadow)) 'face-override-spec)))

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-height 30)
  (doom-modeline-bar-width 4)
  (doom-modeline-buffer-file-name-style 'truncate-upto-project)
  (doom-modeline-icon t)
  (doom-modeline-major-mode-icon t)
  (doom-modeline-minor-modes nil)
  (doom-modeline-modal t)
  (doom-modeline-modal-icon t))

(use-package nerd-icons)

;; Zen/distraction-free writing mode
(use-package olivetti
  :custom
  (olivetti-body-width 100))

(add-to-list 'custom-theme-load-path "/home/glenn/SourceCode/kusanagi-theme")
(load-theme 'kusanagi t)

;;;; ========================================================================
;;;; Dashboard — Paren.Works Landing Page
;;;; ========================================================================

(use-package dashboard
  :demand t
  :custom
  (dashboard-banner-logo-title "Paren.Works — ()")
  (dashboard-startup-banner pw/logo-path)
  (dashboard-center-content t)
  (dashboard-vertically-center-content t)
  (dashboard-set-heading-icons t)
  (dashboard-set-file-icons t)
  (dashboard-icon-type 'nerd-icons)
  (dashboard-items '((recents   . 8)
                     (projects  . 5)
                     (agenda    . 5)
                     (bookmarks . 3)))
  (dashboard-set-navigator t)
  (dashboard-navigator-buttons
   `(((,(when (require 'nerd-icons nil t)
          (nerd-icons-faicon "nf-fa-github" :height 1.1 :v-adjust 0.0))
       "Source" "Browse parenworks source"
       (lambda (&rest _) (browse-url "https://src.paren.works")))
      (,(when (require 'nerd-icons nil t)
          (nerd-icons-faicon "nf-fa-terminal" :height 1.1 :v-adjust 0.0))
       "Sly" "Start Common Lisp REPL"
       (lambda (&rest _) (sly)))
      (,(when (require 'nerd-icons nil t)
          (nerd-icons-faicon "nf-fa-folder_open" :height 1.1 :v-adjust 0.0))
       "Org" "Open orgfiles"
       (lambda (&rest _) (find-file pw/org-directory))))))
  :config
  (dashboard-setup-startup-hook)
  (setq initial-buffer-choice (lambda () (get-buffer-create dashboard-buffer-name))))

;;;; ========================================================================
;;;; Completion — Vertico (Posframe) + Corfu + Orderless + Marginalia
;;;; ========================================================================

(use-package vertico
  :demand t
  :custom
  (vertico-cycle t)
  (vertico-count 15)
  :config
  (vertico-mode 1))

(use-package posframe
  :demand t)

(use-package vertico-posframe
  :demand t
  :after (vertico posframe)
  :custom
  (vertico-posframe-poshandler #'posframe-poshandler-frame-center)
  (vertico-posframe-border-width 2)
  (vertico-posframe-width 80)
  (vertico-posframe-parameters
   '((left-fringe  . 8)
     (right-fringe . 8)))
  :config
  (vertico-posframe-mode 1))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :init (marginalia-mode))

(use-package consult
  :bind
  (("C-x b"   . consult-buffer)
   ("C-x 4 b" . consult-buffer-other-window)
   ("M-g g"   . consult-goto-line)
   ("M-g M-g" . consult-goto-line)
   ("M-s r"   . consult-ripgrep)
   ("M-s f"   . consult-find)
   ("C-c h"   . consult-org-heading))
  :custom
  (consult-narrow-key "<"))

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.15)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-preselect 'prompt)
  (corfu-popupinfo-delay '(0.5 . 0.2))
  :init
  (global-corfu-mode)
  (corfu-popupinfo-mode)
  :bind (:map corfu-map
              ("TAB" . corfu-next)
              ([tab] . corfu-next)
              ("S-TAB" . corfu-previous)
              ([backtab] . corfu-previous)))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file))

(use-package embark
  :bind
  (("C-." . embark-act)
   ("C-;" . embark-dwim))
  :config
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;;; Swiper - regex-powered buffer search with live preview
(use-package swiper
  :pin gnu
  :commands (swiper swiper-backward swiper-all)
  :bind
  (("C-s"   . swiper)
   ("C-r"   . swiper-backward)
   ("C-S-s" . swiper-all))
  :custom
  (swiper-action-recenter t)
  (swiper-include-line-number-in-search t)
  (swiper-goto-start-of-match t)
  :config
  ;; Use orderless-style matching in swiper (space-separated terms)
  (setq ivy-re-builders-alist '((swiper     . ivy--regex-plus)
                                 (swiper-all . ivy--regex-plus)
                                 (t          . ivy--regex-plus)))
  ;; Make ivy's minibuffer feel at home with the rest of the config
  (setq ivy-height 15
        ivy-wrap t
        ivy-use-virtual-buffers nil      ; don't let ivy touch buffer switching
        ivy-count-format "(%d/%d) "
        ivy-initial-inputs-alist nil))   ; no ^ prefix in input

;; Evil integration — / and ? in normal mode use swiper (deferred)
(with-eval-after-load 'evil
  (evil-global-set-key 'normal "/" 'swiper)
  (evil-global-set-key 'normal "?" 'swiper-backward))

;;;; ========================================================================
;;;; Common Lisp — The Main Event
;;;; ========================================================================

;;; Sly — REPL, debugger, inspector
(use-package sly
  :custom
  (inferior-lisp-program "sbcl")
  (sly-lisp-implementations
   '((sbcl ("sbcl" "--dynamic-space-size" "4096"))))
  (sly-net-coding-system 'utf-8-unix)
  (sly-complete-symbol-function 'sly-flex-completions)
  :config
  (setq sly-symbol-completion-mode nil)
  (add-hook 'sly-mrepl-mode-hook (lambda () (paredit-mode -1))))

;;; Sextant — CL Language Server via eglot
(use-package eglot
  :ensure nil
  :config
  (add-to-list 'eglot-server-programs
               `(lisp-mode . (,pw/sextant-path)))
  :hook
  (lisp-mode . eglot-ensure))

;;; eldoc-box - show docs in a popup at point instead of echo area
(use-package eldoc-box
  :hook
  (eglot-managed-mode . eldoc-box-hover-at-point-mode))

;;; Paredit — structural editing for s-expressions
(use-package paredit
  :hook
  ((lisp-mode . paredit-mode)
   (emacs-lisp-mode . paredit-mode)
   (sly-mrepl-mode . paredit-mode)
   (scheme-mode . paredit-mode))
  :config
  (add-hook 'paredit-mode-hook
            (lambda () (electric-pair-local-mode -1))))

;;; Evil-cleverparens — vim motions that respect parens
(use-package evil-cleverparens
  :after (evil paredit)
  :hook ((lisp-mode emacs-lisp-mode scheme-mode sly-mrepl-mode)
         . evil-cleverparens-mode))

;;; Rainbow delimiters
(use-package rainbow-delimiters
  :hook ((lisp-mode emacs-lisp-mode scheme-mode sly-mrepl-mode)
         . rainbow-delimiters-mode))

;;; Aggressive indent for Lisp
(use-package aggressive-indent
  :hook ((lisp-mode emacs-lisp-mode scheme-mode) . aggressive-indent-mode))

;;;; ========================================================================
;;;; Tree-sitter
;;;; ========================================================================

(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;;; Markless — .mess files via tree-sitter-markless
(when (treesit-available-p)
  (add-to-list 'treesit-extra-load-path
               (expand-file-name "tree-sitter" user-emacs-directory))

  ;; ── Flymake backend: report tree-sitter ERROR nodes as diagnostics ──
  (defun pw/markless-flymake (report-fn &rest _args)
    "Flymake backend for Markless using tree-sitter ERROR nodes."
    (let ((diagnostics '())
          (root (treesit-buffer-root-node 'markless)))
      (when root
        (let ((query (treesit-query-compile 'markless '((ERROR) @err))))
          (dolist (match (treesit-query-capture root query))
            (when (eq (car match) 'err)
              (let* ((node (cdr match))
                     (start (treesit-node-start node))
                     (end (treesit-node-end node))
                     (text (buffer-substring-no-properties
                            start (min (+ start 40) end)))
                     (msg (format "Malformed markup near: %s%s"
                                  text (if (> (- end start) 40) "…" ""))))
                (push (flymake-make-diagnostic
                       (current-buffer) start end :warning msg)
                      diagnostics))))))
      (funcall report-fn (nreverse diagnostics))))

  ;; ── Defun name extractor for which-function-mode ──
  (defun pw/markless-defun-name (node)
    "Return header text from NODE for which-function-mode."
    (when (string= (treesit-node-type node) "header")
      (let ((parts '()))
        (dotimes (i (treesit-node-child-count node))
          (let ((child (treesit-node-child node i)))
            (when (string= (treesit-node-type child) "text")
              (push (treesit-node-text child) parts))))
        (when parts
          (string-trim (mapconcat #'identity (nreverse parts) ""))))))

  ;; ── Completion-at-point for Markless syntax ──
  (defvar pw/markless-completions
    '(;; Instructions
      ("set"           . "instruction — set a variable")
      ("info"          . "instruction — info message")
      ("warning"       . "instruction — warning message")
      ("error"         . "instruction — error message")
      ("include"       . "instruction — include a file")
      ("disable"       . "instruction — disable a directive")
      ("enable"        . "instruction — enable a directive")
      ("label"         . "instruction — label this section")
      ;; Embed types
      ("image"         . "embed type")
      ("video"         . "embed type")
      ("audio"         . "embed type")
      ("source"        . "embed type")
      ;; Embed options
      ("loop"          . "embed option")
      ("autoplay"      . "embed option")
      ("float"         . "embed option — float left/right")
      ("width"         . "embed option — e.g. 100px")
      ("height"        . "embed option — e.g. 100px")
      ("description"   . "embed option")
      ("caption"       . "embed option")
      ("encoding"      . "embed option")
      ("options"       . "embed option")
      ("start"         . "embed option — start time")
      ("end"           . "embed option — end time")
      ;; Instruction variables
      ("author"        . "variable")
      ("language"      . "variable")
      ("line-break-mode" . "variable — show/hide/skip"))
    "Alist of Markless keywords and their annotations for completion.")

  (defun pw/markless-capf ()
    "Completion-at-point for Markless syntax keywords."
    (let ((bounds (bounds-of-thing-at-point 'word)))
      (when bounds
        (list (car bounds) (cdr bounds)
              (mapcar #'car pw/markless-completions)
              :exclusive 'no
              :annotation-function
              (lambda (s)
                (when-let* ((ann (cdr (assoc s pw/markless-completions))))
                  (concat "  " ann)))))))

  ;; ── Electric pairs for multi-char Markless delimiters ──
  (defvar pw/markless-electric-chars '(?* ?/ ?_ ?`)
    "Characters that form paired Markless delimiters when doubled.")

  (defun pw/markless-post-self-insert ()
    "Auto-close Markless paired delimiters like **, //, __, ``."
    (when (and (memq last-command-event pw/markless-electric-chars)
               (> (point) 1)
               (eq (char-before (1- (point))) last-command-event)
               (not (eq (char-after) last-command-event)))
      (save-excursion
        (insert (make-string 2 last-command-event)))))

  ;; ── The major mode ──
  (define-derived-mode markless-ts-mode text-mode "Markless"
    "Major mode for editing Markless (.mess) files, powered by tree-sitter."
    :syntax-table text-mode-syntax-table

    (when (treesit-ready-p 'markless t)
      (treesit-parser-create 'markless)

      ;; Font-lock
      (setq-local treesit-font-lock-settings
                  (treesit-font-lock-rules
                   :language 'markless
                   :feature 'heading
                   '((header) @font-lock-function-name-face)

                   :language 'markless
                   :feature 'markup
                   '((bold) @bold
                     (italic) @italic
                     (underline) @underline
                     (strikethrough) @shadow
                     (code) @font-lock-string-face
                     (supertext) @font-lock-type-face
                     (subtext) @font-lock-type-face)

                   :language 'markless
                   :feature 'link
                   '((url) @link
                     (footnote-reference) @font-lock-constant-face
                     (footnote) @font-lock-constant-face)

                   :language 'markless
                   :feature 'code-block
                   '((code-block (options) @font-lock-type-face)
                     (code-block (text) @font-lock-string-face))

                   :language 'markless
                   :feature 'quote
                   '((blockquote) @font-lock-doc-face
                     (blockquote-header) @font-lock-doc-face)

                   :language 'markless
                   :feature 'comment
                   '((comment) @font-lock-comment-face)

                   :language 'markless
                   :feature 'instruction
                   '((instruction) @font-lock-preprocessor-face
                     (set) @font-lock-keyword-face
                     (info) @font-lock-keyword-face
                     (warning) @font-lock-keyword-face
                     (error) @font-lock-keyword-face
                     (include) @font-lock-keyword-face
                     (disable) @font-lock-keyword-face
                     (enable) @font-lock-keyword-face
                     (label) @font-lock-keyword-face
                     (variable) @font-lock-variable-name-face
                     (value) @font-lock-string-face
                     (directive) @font-lock-type-face)

                   :language 'markless
                   :feature 'embed
                   '((embed) @font-lock-constant-face
                     (image) @font-lock-keyword-face
                     (video) @font-lock-keyword-face
                     (audio) @font-lock-keyword-face
                     (source) @font-lock-keyword-face)

                   :language 'markless
                   :feature 'punctuation
                   '((horizontal-rule) @font-lock-comment-delimiter-face
                     (em-dash) @font-lock-punctuation-face
                     (en-dash) @font-lock-punctuation-face
                     (escape) @font-lock-escape-face
                     (number) @font-lock-number-face)))

      (setq-local treesit-font-lock-feature-list
                  '((comment heading)
                    (markup link code-block quote)
                    (instruction embed punctuation)))

      ;; Imenu — jump to headers via SPC s i
      (setq-local treesit-simple-imenu-settings
                  '(("Header" "\\`header\\'" nil nil)))

      ;; Structural navigation — M-a / M-e / C-M-a / C-M-e between blocks
      (setq-local treesit-defun-type-regexp
                  (regexp-opt '("header" "paragraph" "list" "enumeration"
                                "blockquote" "blockquote-header" "code-block"
                                "embed" "instruction" "footnote"
                                "left-align" "right-align" "center" "justify")))

      ;; Sentence-level navigation — M-a / M-e between inline elements
      (setq-local treesit-sentence-type-regexp
                  (regexp-opt '("bold" "italic" "underline" "strikethrough"
                                "supertext" "subtext" "code" "compound"
                                "url" "footnote-reference" "text")))

      ;; Which-function — show current header in modeline
      (setq-local treesit-defun-name-function #'pw/markless-defun-name)
      (setq-local which-func-functions nil)
      (which-function-mode 1)

      ;; Outline — fold headers with C-c @ commands or outline-minor-mode
      (setq-local treesit-outline-predicate "\\`header\\'")

      ;; Flymake diagnostics from tree-sitter ERROR nodes
      ;; Disabled by default — parser still produces too many false positives
      ;; on real documents. Enable manually with M-x flymake-mode when needed.
      (add-hook 'flymake-diagnostic-functions #'pw/markless-flymake nil t)

      ;; Completion-at-point for Markless keywords
      (add-hook 'completion-at-point-functions #'pw/markless-capf nil t)

      ;; Electric pairs — type ** to get **||** (cursor in middle)
      (add-hook 'post-self-insert-hook #'pw/markless-post-self-insert nil t)

      ;; Visual line mode for prose
      (visual-line-mode 1)

      (treesit-major-mode-setup)))

  (add-to-list 'auto-mode-alist '("\\.mess\\'" . markless-ts-mode)))

;;;; ========================================================================
;;;; Git — Magit
;;;; ========================================================================

(use-package magit
  :bind ("C-x g" . magit-status)
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

(use-package diff-hl
  :hook
  ((magit-pre-refresh  . diff-hl-magit-pre-refresh)
   (magit-post-refresh . diff-hl-magit-post-refresh))
  :init (global-diff-hl-mode))

;;;; ========================================================================
;;;; Org Mode
;;;; ========================================================================

(use-package org
  :ensure nil
  :hook (org-mode . pw/org-mode-setup)
  :custom
  (org-directory pw/org-directory)
  (org-default-notes-file (expand-file-name "inbox.org" pw/org-directory))
  (org-agenda-files (list pw/org-directory
                          (expand-file-name "gtd/" pw/org-directory)))
  (org-ellipsis " ▾")
  (org-hide-emphasis-markers t)
  (org-fontify-quote-and-verse-blocks t)
  (org-src-tab-acts-natively t)
  (org-edit-src-content-indentation 2)
  (org-startup-folded 'content)
  (org-cycle-separator-lines 2)
  (org-agenda-start-with-log-mode t)
  (org-log-done 'time)
  (org-log-into-drawer t)
  (org-return-follows-link t)
  (org-support-shift-select 'always)
  (org-todo-keywords
   '((sequence "TODO(t)" "NEXT(n)" "ACTIVE(a)" "WAIT(w@/!)" "HOLD(h)" "|" "DONE(d!)" "CNCL(c@)")))
  :bind
  (("C-c a" . org-agenda)
   ("C-c c" . org-capture)
   ("C-c l" . org-store-link))
  :config
  (require 'ox-md nil t)
  (require 'org-protocol)

  ;; ── Capture Templates ──────────────────────────────────────────────
  (setq org-capture-templates
        `(;; ── GTD Inbox (quick stuff) ──
          ("i" "Inbox (GTD)" entry
           (file ,(expand-file-name "gtd/inbox.org" pw/org-directory))
           "* TODO %?\n:PROPERTIES:\n:CAPTURED: %U\n:END:\n"
           :empty-lines 1)

          ;; ── TFS-CMMS Project ──
          ("c" "CMMS")

          ("cb" "CMMS Bug Report" entry
           (file+headline ,(expand-file-name "tfs-cmms.org" pw/org-directory) "Bugs")
           "* TODO [#A] BUG: %? :bug:cmms:\n:PROPERTIES:\n:CAPTURED: %U\n:SEVERITY: %^{Severity|critical|high|medium|low}\n:REPORTED_BY: %^{Reported by}\n:END:\n** Description\n%?\n** Steps to Reproduce\n1. \n** Expected Behaviour\n\n** Actual Behaviour\n\n** Environment\n- Server: %^{Server|tfs.is|cmms.paren.works|localhost}\n"
           :empty-lines 1)

          ("cf" "CMMS Feature Request" entry
           (file+headline ,(expand-file-name "tfs-cmms.org" pw/org-directory) "Features")
           "* TODO [#B] FEAT: %? :feature:cmms:\n:PROPERTIES:\n:CAPTURED: %U\n:REQUESTED_BY: %^{Requested by}\n:END:\n** Description\n%?\n** Acceptance Criteria\n- [ ] \n"
           :empty-lines 1)

          ("ci" "CMMS Issue / Incident" entry
           (file+headline ,(expand-file-name "tfs-cmms.org" pw/org-directory) "Issues")
           "* TODO [#A] ISSUE: %? :issue:cmms:\n:PROPERTIES:\n:CAPTURED: %U\n:SEVERITY: %^{Severity|critical|high|medium|low}\n:AFFECTED: %^{Affected|production|test|both}\n:END:\n** Summary\n%?\n** Impact\n\n** Resolution Steps\n1. \n** Post-Mortem\n"
           :empty-lines 1)

          ("cm" "CMMS Maintenance Task" entry
           (file+headline ,(expand-file-name "tfs-cmms.org" pw/org-directory) "Maintenance")
           "* TODO [#C] MAINT: %? :maintenance:cmms:\n:PROPERTIES:\n:CAPTURED: %U\n:SERVER: %^{Server|tfs.is|cmms.paren.works|both}\n:END:\n** Task\n%?\n** Checklist\n- [ ] Backup taken\n- [ ] Changes tested\n- [ ] Deployed\n- [ ] Verified\n"
           :empty-lines 1)

          ("cn" "CMMS Note" entry
           (file+headline ,(expand-file-name "tfs-cmms.org" pw/org-directory) "Notes")
           "* %? :cmms:\n:PROPERTIES:\n:CAPTURED: %U\n:END:\n"
           :empty-lines 1)

          ;; ── Meetings ──
          ("m" "Meeting Note" entry
           (file+headline ,(expand-file-name "meetings.org" pw/org-directory) "Meetings")
           "* TODO %? :work:meeting:\nSCHEDULED: %^T\n:PROPERTIES:\n:CAPTURED: %U\n:ATTENDEES: %^{Attendees}\n:END:\n** Agenda\n- \n** Notes\n\n** Action Items\n- [ ] \n"
           :empty-lines 1)

          ;; ── General ──
          ("t" "TODO" entry
           (file ,(expand-file-name "refile.org" pw/org-directory))
           "* TODO %? \n:PROPERTIES:\n:CAPTURED: %U\n:END:\n"
           :empty-lines 1)

          ("n" "Note" entry
           (file ,(expand-file-name "refile.org" pw/org-directory))
           "* %? \n:PROPERTIES:\n:CAPTURED: %U\n:END:\n"
           :empty-lines 1)

          ;; ── Org Protocol (browser capture) ──
          ("w" "Web Link" entry
           (file+headline ,(expand-file-name "weblinks.org" pw/org-directory) "Captured Links")
           "* TODO %:description :web:\n:PROPERTIES:\n:CAPTURED: %U\n:URL: %:link\n:END:\n%:annotation\n%i\n%?"
           :empty-lines 1)

          ("W" "Web Link (to GTD inbox)" entry
           (file ,(expand-file-name "gtd/inbox.org" pw/org-directory))
           "* TODO %:description :web:\n:PROPERTIES:\n:CAPTURED: %U\n:URL: %:link\n:END:\n%:annotation\n%i\n%?"
           :empty-lines 1)))

  ;; Default template for org-protocol capture
  (setq org-protocol-default-template-key "w"))

(defun pw/org-mode-setup ()
  "Configure Org buffers."
  (org-indent-mode 1)
  (visual-line-mode 1))

;;; org-modern — Modern Org styling (replaces bullets/stars visually)
(use-package org-modern
  :after org
  :hook
  ((org-mode . org-modern-mode)
   (org-agenda-finalize . org-modern-agenda))
  :custom
  (org-modern-star '("◉" "○" "◈" "◇" "▸"))
  (org-modern-table-vertical 1)
  (org-modern-table-horizontal 0.2)
  (org-modern-list '((?- . "•") (?+ . "➤") (?* . "▹")))
  (org-modern-block-fringe nil)
  (org-modern-keyword nil)
  (org-modern-todo t)
  (org-modern-priority t))

;;; org-superstar — Fancy heading bullets (available if you prefer over org-modern)
(use-package org-superstar
  :after org
  :custom
  (org-superstar-headline-bullets-list '("◉" "○" "◈" "◇" "▸"))
  (org-superstar-item-bullet-alist '((?- . ?•) (?+ . ?➤) (?* . ?▹)))
  (org-superstar-remove-leading-stars t))

;;; org-bullets — Classic org bullets (available as fallback)
(use-package org-bullets
  :after org)

;;; org-super-agenda — Grouped, prioritised agenda views
(use-package org-super-agenda
  :after org
  :config
  (org-super-agenda-mode 1)

  ;; Default groups for daily/weekly agenda
  (setq org-super-agenda-groups
        '((:name "⏰ Overdue"
                 :deadline past
                 :scheduled past
                 :order 1)
          (:name "📅 Today"
                 :time-grid t
                 :date today
                 :scheduled today
                 :deadline today
                 :order 2)
          (:name "🔥 Active"
                 :todo "ACTIVE"
                 :order 3)
          (:name "⚡ Next Actions"
                 :todo "NEXT"
                 :order 4)
          (:name "🏢 Meetings"
                 :tag "meeting"
                 :category "meetings"
                 :order 5)
          (:name "� CMMS Bugs"
                 :tag "bug"
                 :order 6)
          (:name "🚨 CMMS Issues"
                 :tag "issue"
                 :order 7)
          (:name "🔧 CMMS Maintenance"
                 :tag "maintenance"
                 :order 8)
          (:name "✨ CMMS Features"
                 :tag "feature"
                 :order 9)
          (:name "� Work"
                 :tag "work"
                 :order 10)
          (:name "🔨 Projects"
                 :tag "project"
                 :order 11)
          (:name "⏳ Waiting"
                 :todo "WAIT"
                 :order 12)
          (:name "🔒 On Hold"
                 :todo "HOLD"
                 :order 13)
          (:name "📌 Upcoming Deadlines"
                 :deadline future
                 :order 14)
          (:name "🗓 Scheduled Soon"
                 :scheduled future
                 :order 15)
          (:name "📥 Inbox / Refile"
                 :category "refile"
                 :order 16)
          (:name "📋 Other Tasks"
                 :anything t
                 :order 99)))

  ;; Custom agenda commands
  (setq org-agenda-custom-commands
        '(("d" "Dashboard"
           ((agenda "" ((org-agenda-span 'day)
                        (org-super-agenda-groups
                         '((:name "⏰ Overdue"
                                  :deadline past
                                  :scheduled past
                                  :order 1)
                           (:name "📅 Today"
                                  :time-grid t
                                  :date today
                                  :scheduled today
                                  :deadline today
                                  :order 2)
                           (:name "🔥 Active"
                                  :todo "ACTIVE"
                                  :order 3)
                           (:name "⚡ Next Actions"
                                  :todo "NEXT"
                                  :order 4)
                           (:name "🏢 Meetings"
                                  :tag "meeting"
                                  :category "meetings"
                                  :order 5)
                           (:name "📌 Upcoming Deadlines"
                                  :deadline future
                                  :order 10)))))
            (alltodo "" ((org-agenda-overriding-header "")
                         (org-super-agenda-groups
                          '((:name "� Bugs"
                                   :tag "bug"
                                   :order 1)
                            (:name "🚨 Issues"
                                   :tag "issue"
                                   :order 2)
                            (:name "�� Work"
                                   :tag "work"
                                   :order 3)
                            (:name "� Maintenance"
                                   :tag "maintenance"
                                   :order 4)
                            (:name "⏳ Waiting"
                                   :todo "WAIT"
                                   :order 5)
                            (:name "🔒 On Hold"
                                   :todo "HOLD"
                                   :order 6)
                            (:name "📥 Inbox / Refile"
                                   :category "refile"
                                   :order 7)
                            (:discard (:anything t))))))))

          ("C" "CMMS Project"
           ((alltodo "" ((org-agenda-overriding-header "TFS-CMMS Project Board")
                         (org-super-agenda-groups
                          '((:name "🐛 Bugs (Critical/High)"
                                   :and (:tag "bug" :priority>= "B")
                                   :order 1)
                            (:name "🚨 Active Issues"
                                   :and (:tag "issue" :todo "ACTIVE")
                                   :order 2)
                            (:name "🔥 In Progress"
                                   :todo "ACTIVE"
                                   :tag "cmms"
                                   :order 3)
                            (:name "⚡ Next Up"
                                   :todo "NEXT"
                                   :tag "cmms"
                                   :order 4)
                            (:name "🐛 Other Bugs"
                                   :tag "bug"
                                   :order 5)
                            (:name "🚨 Other Issues"
                                   :tag "issue"
                                   :order 6)
                            (:name "✨ Features"
                                   :tag "feature"
                                   :order 7)
                            (:name "🔧 Maintenance"
                                   :tag "maintenance"
                                   :order 8)
                            (:name "⏳ Waiting / Blocked"
                                   :todo ("WAIT" "HOLD")
                                   :tag "cmms"
                                   :order 9)
                            (:discard (:anything t))))))))

          ("n" "Next Actions"
           ((alltodo "" ((org-agenda-overriding-header "Next Actions")
                         (org-super-agenda-groups
                          '((:name "🔥 Active Now"
                                   :todo "ACTIVE")
                            (:name "⚡ Up Next"
                                   :todo "NEXT")
                            (:discard (:anything t))))))))

          ("w" "Waiting & Held"
           ((alltodo "" ((org-agenda-overriding-header "Blocked Items")
                         (org-super-agenda-groups
                          '((:name "⏳ Waiting On"
                                   :todo "WAIT")
                            (:name "🔒 On Hold"
                                   :todo "HOLD")
                            (:discard (:anything t))))))))

          ("W" "Weekly Review"
           ((agenda "" ((org-agenda-span 'week)
                        (org-super-agenda-groups
                         '((:name "✅ Completed"
                                  :log closed
                                  :order 1)
                           (:name "⏰ Overdue"
                                  :deadline past
                                  :scheduled past
                                  :order 2)
                           (:name "📅 This Week"
                                  :time-grid t
                                  :order 3)))))
            (alltodo "" ((org-agenda-overriding-header "")
                         (org-super-agenda-groups
                          '((:name "⏳ Stuck / Waiting"
                                   :todo ("WAIT" "HOLD"))
                            (:name "📥 Needs Processing"
                                   :category "refile")
                            (:discard (:anything t)))))))))))

;;; org-gtd — Getting Things Done workflow (4.0)
(use-package org-gtd
  :after org
  :demand t
  :init
  (setq org-gtd-update-ack "4.0.0")
  :custom
  (org-gtd-directory (expand-file-name "gtd/" pw/org-directory))

  ;; Map GTD semantic states to your keywords
  (org-gtd-keyword-mapping '((todo     . "TODO")
                             (next     . "NEXT")
                             (wait     . "WAIT")
                             (canceled . "CNCL")))
  :config
  ;; REQUIRED: Enable org-edna for project dependencies
  (org-edna-mode 1)

  ;; Add org-gtd files to agenda (must be in :config so directory is defined)
  (unless (member org-gtd-directory org-agenda-files)
    (add-to-list 'org-agenda-files org-gtd-directory))

  :bind
  (("C-c d c" . org-gtd-capture)
   ("C-c d e" . org-gtd-engage)
   ("C-c d p" . org-gtd-process-inbox)
   ("C-c d n" . org-gtd-show-all-next)
   ("C-c d s" . org-gtd-reflect-stuck-projects)

   :map org-gtd-clarify-mode-map
   ("C-c c" . org-gtd-organize)

   :map org-agenda-mode-map
   ("C-c ." . org-gtd-agenda-transient)))

;;;; ========================================================================
;;;; Typst — PDF Authoring
;;;; ========================================================================

(use-package typst-ts-mode
  :custom
  (typst-ts-mode-watch-options "--open")
  :config
  ;; Ensure typst binary is found
  (setq typst-ts-compile-executable "/usr/bin/typst")
  ;; tinymist LSP for Typst via eglot
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
                 `((typst-ts-mode) .
                   ,(eglot-alternatives `(,(expand-file-name "~/.cargo/bin/tinymist")
                                          "tinymist"
                                          "typst-lsp")))))
  :hook
  (typst-ts-mode . eglot-ensure))

;;; pdf-tools — View compiled PDFs inside Emacs
(use-package pdf-tools
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query)
  (setq-default pdf-view-display-size 'fit-page))

;;; Live Typst preview inside Emacs via pdf-tools + typst watch
(defvar pw/typst-watch-process nil
  "Process running `typst watch` for live preview.")

(defun pw/typst-live-preview ()
  "Start live Typst preview: compile, open PDF in a side split, and watch for changes."
  (interactive)
  (unless (derived-mode-p 'typst-ts-mode)
    (user-error "Not in a Typst buffer"))
  (let* ((src (buffer-file-name))
         (pdf (concat (file-name-sans-extension src) ".pdf")))
    ;; Save first
    (save-buffer)
    ;; Kill any existing watch process
    (when (and pw/typst-watch-process (process-live-p pw/typst-watch-process))
      (kill-process pw/typst-watch-process))
    ;; Compile once to create the PDF
    (call-process "/usr/bin/typst" nil nil nil "compile" src)
    ;; Start typst watch in background
    (setq pw/typst-watch-process
          (start-process "typst-watch" "*typst-watch*" "/usr/bin/typst" "watch" src))
    ;; Open PDF in a right split
    (delete-other-windows)
    (split-window-right)
    (other-window 1)
    (find-file pdf)
    ;; Auto-revert so PDF refreshes on recompile
    (auto-revert-mode 1)
    (other-window 1)
    (message "Typst live preview started — save to refresh PDF")))

(defun pw/typst-stop-preview ()
  "Stop the Typst watch process."
  (interactive)
  (when (and pw/typst-watch-process (process-live-p pw/typst-watch-process))
    (kill-process pw/typst-watch-process)
    (setq pw/typst-watch-process nil)
    (message "Typst live preview stopped")))

;;;; ========================================================================
;;;; Email — Notmuch
;;;; ========================================================================

(use-package notmuch
  :ensure nil
  :load-path "/usr/share/emacs/site-lisp"
  :commands (notmuch notmuch-hello notmuch-search notmuch-mua-new-mail)
  :custom
  ;; ── Identity ──
  (notmuch-identities '("Glenn Thompson <glenn@paren.works>"
                         "Paren Works <hello@paren.works>"))
  (notmuch-fcc-dirs '(("glenn@paren.works" . "Paren-Glenn/Sent +sent -inbox -unread")
                       ("hello@paren.works" . "Paren-Hello/Sent +sent -inbox -unread")))

  ;; ── Sending via msmtp ──
  (message-send-mail-function 'message-send-mail-with-sendmail)
  (sendmail-program "msmtp")
  (message-sendmail-f-is-evil t)
  (message-sendmail-envelope-from 'header)
  (mail-envelope-from 'header)
  (mail-specify-envelope-from t)

  ;; ── Display ──
  (notmuch-show-logo nil)
  (notmuch-hello-thousands-separator ",")
  (notmuch-search-oldest-first nil)
  (notmuch-show-indent-messages-width 2)
  (notmuch-column-control 1.0)
  (notmuch-hello-auto-refresh t)
  (notmuch-show-all-multipart/alternative-parts nil)
  (notmuch-multipart/alternative-discouraged '("text/html"))
  (notmuch-mua-compose-in 'current-window)
  (notmuch-show-relative-dates t)
  (notmuch-archive-tags '("-inbox"))
  (notmuch-message-replied-tags '("+replied"))
  (notmuch-message-forwarded-tags '("+forwarded"))

  ;; ── Saved Searches (shown on hello screen) ──
  (notmuch-saved-searches
   '((:name "Inbox"        :query "tag:inbox"                :key "i" :sort-order newest-first)
     (:name "Glenn"        :query "tag:inbox and tag:glenn"  :key "g" :sort-order newest-first)
     (:name "Hello"        :query "tag:inbox and tag:hello"  :key "h" :sort-order newest-first)
     (:name "Unread"       :query "tag:unread and tag:inbox" :key "u" :sort-order newest-first)
     (:name "Flagged"      :query "tag:flagged"              :key "f" :sort-order newest-first)
     (:name "Sent"         :query "tag:sent"                 :key "s" :sort-order newest-first)
     (:name "Today"        :query "date:today and tag:inbox" :key "t" :sort-order newest-first)
     (:name "This Week"    :query "date:7d.. and tag:inbox"  :key "w" :sort-order newest-first)
     (:name "Drafts"       :query "tag:draft"                :key "d" :sort-order newest-first)
     (:name "All Mail"     :query "*"                        :key "a" :sort-order newest-first)))

  ;; ── Hello Screen Layout ──
  (notmuch-hello-sections
   '(notmuch-hello-insert-header
     notmuch-hello-insert-saved-searches
     notmuch-hello-insert-search
     notmuch-hello-insert-recent-searches
     notmuch-hello-insert-alltags
     notmuch-hello-insert-footer))

  ;; ── Attachments ──
  (mm-default-directory "~/Downloads")

  :config
  ;; Default identity
  (setq user-mail-address "glenn@paren.works"
        user-full-name "Glenn Thompson")

  ;; ── Per-account signature ──
  (defun pw/notmuch-set-signature ()
    "Set signature based on the From address in the compose buffer."
    (let ((from (message-field-value "From")))
      (setq message-signature
            (cond
             ((and from (string-match-p "hello@paren.works" from))
              "Hello // Paren.Works\n(define (ship) (build 'web 'lisp))  ; systems\nparen.works | github (dot) com/parenworks")
             (t
              "Glenn // Paren.Works\n(define (ship) (build 'web 'lisp))  ; systems\nparen.works | github (dot) com/parenworks")))))
  (add-hook 'message-setup-hook #'pw/notmuch-set-signature)
  (setq message-signature-insert-empty-line t)

  ;; ── Convenience commands ──
  (defun pw/notmuch-sync ()
    "Sync mail and refresh the notmuch database."
    (interactive)
    (message "Syncing mail...")
    (notmuch-poll)
    (when (eq major-mode 'notmuch-hello-mode)
      (notmuch-hello-update)))

  (defun pw/notmuch-inbox ()
    "Show combined inbox."
    (interactive)
    (notmuch-search "tag:inbox" t))

  (defun pw/notmuch-glenn-inbox ()
    "Show glenn@paren.works inbox."
    (interactive)
    (notmuch-search "tag:inbox and tag:glenn" t))

  (defun pw/notmuch-hello-inbox ()
    "Show hello@paren.works inbox."
    (interactive)
    (notmuch-search "tag:inbox and tag:hello" t))

  ;; ── Quick-action keybindings ──
  ;; Search mode
  (define-key notmuch-search-mode-map (kbd "d")
    (lambda ()
      "Trash thread and advance."
      (interactive)
      (notmuch-search-add-tag '("+trash" "-inbox" "-unread"))
      (notmuch-search-next-thread)))

  (define-key notmuch-search-mode-map (kbd "D")
    (lambda ()
      "Delete thread and advance."
      (interactive)
      (notmuch-search-add-tag '("+deleted" "-inbox" "-unread"))
      (notmuch-search-next-thread)))

  (define-key notmuch-search-mode-map (kbd "A")
    (lambda ()
      "Archive thread (remove inbox) and advance."
      (interactive)
      (notmuch-search-add-tag '("-inbox"))
      (notmuch-search-next-thread)))

  (define-key notmuch-search-mode-map (kbd "S")
    (lambda ()
      "Toggle spam tag and advance."
      (interactive)
      (notmuch-search-add-tag '("+spam" "-inbox" "-unread"))
      (notmuch-search-next-thread)))

  ;; Show mode
  (define-key notmuch-show-mode-map (kbd "d")
    (lambda ()
      "Trash message."
      (interactive)
      (notmuch-show-add-tag '("+trash" "-inbox" "-unread"))))

  (define-key notmuch-show-mode-map (kbd "D")
    (lambda ()
      "Delete message."
      (interactive)
      (notmuch-show-add-tag '("+deleted" "-inbox" "-unread"))))

  (define-key notmuch-show-mode-map (kbd "A")
    (lambda ()
      "Archive message."
      (interactive)
      (notmuch-show-add-tag '("-inbox"))))

  (define-key notmuch-show-mode-map (kbd "S")
    (lambda ()
      "Toggle spam tag."
      (interactive)
      (notmuch-show-add-tag '("+spam" "-inbox" "-unread"))))

  ;; ── Evil integration ──
  (with-eval-after-load 'evil
    (evil-set-initial-state 'notmuch-hello-mode 'emacs)
    (evil-set-initial-state 'notmuch-search-mode 'emacs)
    (evil-set-initial-state 'notmuch-show-mode 'emacs)
    (evil-set-initial-state 'notmuch-tree-mode 'emacs)
    (evil-set-initial-state 'notmuch-message-mode 'normal)))

;;;; ========================================================================
;;;; ParenVault -- Email Integration
;;;; ========================================================================

(defun pw/parenvault-import-email-as-task ()
  "Send the current notmuch message to ParenVault as a task."
  (interactive)
  (let ((path (notmuch-show-get-filename)))
    (unless (and path (file-exists-p path))
      (user-error "Message file not found: %s" path))
    (let ((output (shell-command-to-string
                   (format "cat '%s' | parenvault import-email 2>&1"
                           (shell-quote-argument path)))))
      (message "ParenVault: %s" (string-trim output)))))

(defun pw/parenvault-import-email-as-note ()
  "Send the current notmuch message to ParenVault as a note."
  (interactive)
  (let ((path (notmuch-show-get-filename)))
    (unless (and path (file-exists-p path))
      (user-error "Message file not found: %s" path))
    (let ((output (shell-command-to-string
                   (format "cat '%s' | parenvault import-email -n 2>&1"
                           (shell-quote-argument path)))))
      (message "ParenVault: %s" (string-trim output)))))

(with-eval-after-load 'notmuch
  (define-key notmuch-show-mode-map (kbd "C-c p t") #'pw/parenvault-import-email-as-task)
  (define-key notmuch-show-mode-map (kbd "C-c p n") #'pw/parenvault-import-email-as-note))

;;;; ========================================================================
;;;; CrafterBin -- Pastebin Upload
;;;; ========================================================================

(use-package crafterbin
  :load-path "~/SourceCode/crafterbin.el"
  :commands (crafterbin-upload crafterbin-upload-file
             crafterbin-upload-region crafterbin-upload-kill-ring))

;;;; ========================================================================
;;;; Discourse — Forum Browser
;;;; ========================================================================

(use-package discourse
  :load-path "~/SourceCode/discourse.el"
  :commands (discourse discourse-connect discourse-browse-topic discourse-switch-site)
  :custom
  (discourse-default-url "https://forum.systemcrafters.net")
  (discourse-api-auth-method 'auto)
  (discourse-site-configs
   '(("https://forum.systemcrafters.net" :auth-method session)
     (https://community.spritely.institute :auth-method session)
     ("http://localhost" :auth-method session))))

;;;; ========================================================================
;;;; IRC - clatter.el
;;;; ========================================================================

(use-package emojify
  :hook (after-init . global-emojify-mode))

(add-to-list 'load-path (expand-file-name "~/SourceCode/clatter.el"))
(require 'clatter)

;; TESTING (external-tls branch): run TLS in an external subprocess so a
;; half-open socket can no longer freeze Emacs's single thread. Remove
;; these two lines (or set method back to 'builtin) to return to stock
;; behavior. Using openssl here because CLoak serves an incomplete cert
;; chain: openssl s_client only warns and still relays (matching the
;; gnutls-verify-error workaround below), whereas gnutls-cli would refuse.
(setq clatter-tls-method 'external)
(setq clatter-tls-external-command "openssl")

;; Show activity breadcrumbs in clatter buffers' own mode line, not just
;; the global mode line. Takes effect for buffers created after this is
;; set, so reconnect (or M-x clatter-connect) to see it.
(setopt clatter-track-in-buffer-mode-line t)

;; Suppress noisy join/part/quit/away messages
(setopt clatter-suppress-messages '(join part quit away))

;; Enable inline image previews (GUI only)
(require 'clatter-image)
(setopt clatter-image-enable t)

;; Enable URL title previews (replaces bot link previews)
(setopt clatter-url-preview-enable t)

;; Per-channel logging with daily rotation.  clatter-setup (below) calls
;; clatter-log-init for us because clatter-log-enable is non-nil.
(setopt clatter-log-enable t)

(setopt clatter-log-raw-protocol t)

;; Smart notification rules - per-channel levels and schedules
(setopt clatter-notify-rules
      '((:target "#bots" :level none)
        (:target "#systemcrafters" :level all)
        (:target "#emacs" :level mentions :schedule (8 . 23))
        (:target "#lisp" :level mentions :schedule (8 . 23))))

;; Trust Let's Encrypt certs served by CLoak (incomplete chain workaround)
(setq gnutls-verify-error nil)

;; Wire everything up.  As of clatter 0.4.x, loading the package has no
;; side effects (MELPA compliance): it installs no global hooks and
;; enables no features.  clatter-setup installs the disconnect and
;; Emacs-exit (QUIT) cleanup handlers and enables the bundled extras that
;; are gated by the options set above: activity tracking, desktop
;; notifications, chathistory and read markers (on by default), plus URL
;; previews and channel logging (enabled above).  Must run AFTER the
;; setopt forms so it sees the right values.
(clatter-setup)

;; Org-mode integration (store-link, capture, log export).  The irc:
;; link type is no longer auto-registered; clatter-org-setup does it.
(require 'clatter-org)
(with-eval-after-load 'org
  (clatter-org-setup))

;; clatter-networks is managed via custom.el (M-x customize-group clatter)
;; Use /autojoin add|remove to persist channel changes.


;; Evil: normal state for leader key, i enters insert at prompt
(with-eval-after-load 'evil
  (evil-set-initial-state 'clatter-mode 'normal)
  (evil-define-key 'normal clatter-mode-map
    (kbd "g o") #'clatter-hl-open-url-nearest
    (kbd "g s") #'clatter-select-message
    (kbd "i") #'clatter-evil-insert-at-prompt)

  (defun clatter-evil-insert-at-prompt ()
    "Move to the input prompt and enter Evil insert state."
    (interactive)
    (when clatter--input-marker
      (goto-char clatter--input-marker)
      (goto-char (line-end-position)))
    (evil-insert-state)))

;; Leader key bindings for IRC
(pw/leader
  "i"   '(:ignore t :wk "IRC")
  "ii"  '(clatter :wk "Connect to network")
  "id"  '(clatter-disconnect :wk "Disconnect")
  "is"  '(clatter-status :wk "Connection status")
  "iq"  '(clatter-quick-connect :wk "Quick connect")
  "it"  '(clatter-track-switch :wk "Jump to activity")
  "il"  '(clatter-track-list :wk "List activity")
  "im"  '(clatter-track-mute :wk "Mute channel")
  "iu"  '(clatter-track-unmute :wk "Unmute channel")
  "in"  '(clatter-notify-toggle :wk "Toggle notifications")
  "ik"  '(clatter-notify-add-keyword :wk "Add notify keyword")
  "ir"  '(clatter-rawlog-open :wk "Raw protocol log")
  "io"  '(clatter-hl-browse-urls :wk "Browse URLs")
  "iy"  '(clatter-hl-copy-url :wk "Copy URL")
  "ip"  '(clatter-nicklist-toggle :wk "Toggle nick list")
  "i/"  '(clatter-search :wk "Search IRC logs")
  "ic"  '(clatter-chathistory-request :wk "Fetch chat history")
  "iN"  '(clatter-notify-test :wk "Test notification"))

;;;; ========================================================================
;;;; Telega - Path to telegram-tdlib used to build the telega server
;;;; ========================================================================

(setq telega-server-libs-prefix "/usr")

;;;; ========================================================================
;;;; Markless - Shirakumo document markup (.mess files)
;;;; ========================================================================

(use-package markless
  :load-path "~/SourceCode/markless.el"
  :mode (("\\.mess\\'" . markless-mode)
         ("\\.spess\\'" . markless-mode)))

;;;; ========================================================================
;;;; AI - agent-shell + OpenCode
;;;; ========================================================================

(use-package agent-shell
  :custom
  (agent-shell-opencode-authentication
   (agent-shell-opencode-make-authentication
    :api-key (lambda ()
               (let ((found (nth 0 (auth-source-search
                                    :host "opencode.ai"
                                    :user "apikey"
                                    :max 1))))
                 (when found
                   (let ((secret (plist-get found :secret)))
                     (if (functionp secret) (funcall secret) secret)))))))
  :bind
  (("C-c i a" . agent-shell)
   ("C-c i o" . agent-shell-opencode-start-agent)))

;;;; ========================================================================
;;;; Project Management
;;;; ========================================================================

(use-package project
  :ensure nil
  :bind-keymap ("C-c p" . project-prefix-map))

;;;; ========================================================================
;;;; Which Key
;;;; ========================================================================

(use-package which-key
  :init (which-key-mode)
  :custom
  (which-key-idle-delay 0.3)
  (which-key-sort-order 'which-key-key-order-alpha))

;;;; ========================================================================
;;;; Dired
;;;; ========================================================================

(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind ("C-x C-j" . dired-jump)
  :custom
  (dired-listing-switches "-hal --group-directories-first")
  (dired-dwim-target t))

(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

;;;; ========================================================================
;;;; Ligatures
;;;; ========================================================================

(use-package ligature
  :config
  ;; Enable common programming ligatures for Iosevka Comfy
  (ligature-set-ligatures 'prog-mode
                          '("www" "**" "***" "**/" "*>" "*/" "\\\\" "\\\\\\"
                            "{-" "[]" "::" ":::" ":=" "!!" "!=" "!==" "-}"
                            "--" "---" "-->" "->" "->>" "-<" "-<<" "-~"
                            "#{" "#[" "##" "###" "####" "#(" "#?" "#_" "#_("
                            ".-" ".=" ".." "..<" "..." "?=" "??" ";;" "/*"
                            "/**" "/=" "/==" "/>" "//" "///" "&&" "||" "||="
                            "|=" "|>" "^=" "$>" "++" "+++" "+>" "=:=" "=="
                            "===" "==>" "=>" "=>>" "<=" "=<<" "=/=" ">-"
                            ">=" ">=>" ">>" ">>-" ">>=" ">>>" "<*" "<*>"
                            "<|" "<|>" "<$" "<$>" "<!--" "<-" "<--" "<->"
                            "<+" "<+>" "<=" "<==" "<=>" "<=<" "<>" "<<"
                            "<<-" "<<=" "<<<" "<~" "<~~" "</" "</>" "~@"
                            "~-" "~=" "~>" "~~" "~~>" "%%"))
  (global-ligature-mode 1))

;;;; ========================================================================
;;;; Miscellaneous
;;;; ========================================================================

;;; Helpful — better *Help* buffers
(use-package helpful
  :bind
  ([remap describe-function] . helpful-callable)
  ([remap describe-variable] . helpful-variable)
  ([remap describe-key]      . helpful-key)
  ([remap describe-command]  . helpful-command))

;;; Expand region semantically
(use-package expand-region
  :bind ("C-=" . er/expand-region))

;;; Indent guides for modern editor feel
(use-package highlight-indent-guides
  :hook (prog-mode . highlight-indent-guides-mode)
  :custom
  (highlight-indent-guides-method 'character)
  (highlight-indent-guides-responsive 'top))

;;; Pulse line on jump (neovim cursorline flash)
(use-package pulsar
  :custom
  (pulsar-pulse t)
  (pulsar-delay 0.05)
  (pulsar-iterations 10)
  :config
  (pulsar-global-mode 1))

;;;; ========================================================================
;;;; Custom Commands
;;;; ========================================================================

(defun pw/show-file-path ()
  "Show and copy the full path of the current buffer's file."
  (interactive)
  (if buffer-file-name
      (progn
        (message "%s" buffer-file-name)
        (kill-new (file-truename buffer-file-name)))
    (message "Buffer is not visiting a file")))

(defun pw/open-org-dir ()
  "Open the Org files directory."
  (interactive)
  (find-file pw/org-directory))

(defun pw/sly-start ()
  "Start Sly with SBCL."
  (interactive)
  (sly 'sbcl))

;;;; ========================================================================
;;;; Startup
;;;; ========================================================================

(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Paren.Works Emacs ready in %.2f seconds with %d garbage collections."
                     (float-time (time-subtract after-init-time before-init-time))
                     gcs-done)))

(provide 'init)
;;; init.el ends here
