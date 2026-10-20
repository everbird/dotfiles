;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email

(setq user-full-name "Stephen Zhuang"
      user-mail-address "stephen.zhuang@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Dropbox/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Here are some additional functions/macros that could help you configure Doom:
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
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(setq explicit-shell-file-name "/bin/zsh")
(use-package org-journal
  :config
  (setq org-journal-dir "~/Dropbox/org/journal")
  (setq org-journal-file-type 'daily)
)
(setq dashboard-banner-logo-title "Welcome to Emacs Dashboard")
(use-package! puppet-mode
  :mode "\\.pp\\'")

;; plantuml
;(setq plantuml-jar-path "~/bin/plantuml.jar")
;(setq plantuml-default-exec-mode 'jar)
;;(add-to-list
;;  'org-src-lang-modes '("plantuml" . plantuml))

(setq straight-repository-flavors '(melpa gnu-elpa-mirror emacsmirror-mirror))

(after! grip-mode
  (advice-add 'grip-start-process :before
              (lambda ()
                (let ((old-proc (get-process "grip-6419")))
                  (when old-proc
                    (delete-process old-proc)
                    (sleep-for 0.5)))
                (setq grip--port 6419)))
  (defun +grip-start-process-host-a (orig-fun name &rest args)
    (if (string-prefix-p "grip-" name)
        (let* ((last-arg (car (last args)))
               (new-args (append (butlast args) (list (concat "0.0.0.0:" last-arg)))))
          (apply orig-fun name new-args))
      (apply orig-fun name args)))
  (advice-add 'start-process :around #'+grip-start-process-host-a))

;; OSC 52 clipboard support for terminal frames (herdr / tmux / ssh)
(defun +osc52-copy (text &optional _push)
  "Copy TEXT to system clipboard via OSC 52 escape sequences in terminal frames."
  (unless (display-graphic-p)
    (let* ((bytes (encode-coding-string text 'utf-8-unix))
           (base64 (base64-encode-string bytes t)))
      ;; Limit length (100k bytes) to prevent overwhelming terminal buffer
      (when (<= (length base64) 100000)
        (let ((osc (format "\e]52;c;%s\a" base64)))
          (if (getenv "TMUX")
              (send-string-to-terminal (format "\ePtmux;\e%s\e\\" osc))
            (send-string-to-terminal osc)))))))

(advice-add 'gui-select-text :after #'+osc52-copy)

