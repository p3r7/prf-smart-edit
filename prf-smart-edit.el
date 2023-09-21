;;; prf-smart-edit.el --- Saner alternative to default commands -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Jordan Besly
;;
;; Version: 0.0.1
;; Keywords: convenience, files, matching
;; URL: https://github.com/p3r7/prf-smart-edit
;; Package-Requires: ((emacs "27.1"))
;;
;; SPDX-License-Identifier: MIT

;; Future improvements:
;; - delete w/ no save case C-w on empty line
;; - backward-kill-word as well ?
;; - support for rectangular selection?
;;   C-<ret>, C-x r r (copy-rectangle-to-register), C-x r k (kill-rectangle) & C-x r y (yank-rectangle)...


 ;; CONFIGURATION

(defvar smed-indent-after-kill t "Whether to indent after doing a kill.")



;; CORE - STRINGS

(defun smed--blank-string-p (s)
  "predicate: only tabs/spaces on current line
Only works for single line strings"
  ;; if want to select multi-lined string, use [[http://www.emacswiki.org/emacs/MultilineRegexp]]
  (or (string-match "^[ \t]*$" s)
            (zerop (length s))))



;; CORE - REGION

(defun smed--region-blank-p ()
  (unless (use-region-p)
    (user-error "called `smed--region-blank-p' while no active region"))
  (let ((text
	     (buffer-substring (region-beginning) (region-end)) ))
	(smed--blank-string-p text)))

(defun smed--region-comment ()
  (comment-or-uncomment-region (region-beginning) (region-end)))



;; CORE - LINES

(defun smed--bol ()
  (if (derived-mode-p 'eshell-mode)
      (eshell-bol)
    (beginning-of-line)))

(defun smed--line-empty-p ()
  "predicate: no visible characters in line"
  ;; TODO: get selection and call empty-region-p
  (let ((text (buffer-substring (line-beginning-position) (line-end-position))))
    (smed--blank-string-p text)))



;; COMMANDS - REGION

(defun smed-region-delete ()
  "Delete the region."
  (interactive)
  (unless (use-region-p)
    (user-error "called `smed-region-delete' while no active region"))
  (delete-region (region-beginning) (region-end)))

(defun smed-region-kill-ring-save ()
  "kill-ring-save the region."
  (interactive)
  (unless (region-active-p)
    (user-error "called `smed-region-kill-ring-save' while no active region"))
  (kill-ring-save (region-beginning) (region-end)))

(defun smed-region-kill-ring-save-trim ()
  "kill-ring-save the active region, trimming begining spaces and tabs"
  (interactive)
  (unless (region-active-p)
    (user-error "called `smed-region-kill-ring-save-trim' while no active region"))
  (if (< (mark) (point))
	  (progn
	    ;;(cua-exchange-point-and-mark)
	    ;; REVIEW: really needed, could just use region-beginning & region-end ?
	    (exchange-point-and-mark)
	    (kill-ring-save (progn (skip-chars-forward " \t") (point))
			            (region-end))
	    (exchange-point-and-mark))
	;; else
	(kill-ring-save (progn (skip-chars-forward " \t") (point))
			        (region-end))))

(defun smed-region-kill ()
  "kill-region on active region"
  (interactive)
  (unless (region-active-p)
    (user-error "called `smed-region-kill' while no active region"))
  (kill-region (region-beginning) (region-end)))

;; TODO: rewrite w/ trimming done w/ dash & s
(defun smed-region-kill-trim ()
  "Calls `kill-region' on active region, trimming begining spaces and tabs"
  (interactive)
  (unless (region-active-p)
    (user-error "called `smed-region-kill-trim' while no active region"))
  (if (< (mark) (point))
	  (progn
        ;; REVIEW: really needed, could just use region-beginning & region-end ?
	    (exchange-point-and-mark)
	    (kill-region (progn (skip-chars-forward " \t") (point))
			         (region-end))
	    ;; (exchange-point-and-mark) ) ;; useless
	    )
	;; else
	(kill-region (progn (skip-chars-forward " \t") (point))
		         (region-end))))



;; COMMANDS - LINE

(defun smed-next-line ()
  "Like `next-line' but taking into account `visual-line-mode'."
  (interactive)
  (let ((max-col-point (current-column)))
    (end-of-line)
    (forward-line)
    (move-to-column max-col-point)))

(defun smed-line-delete ()
  "Same as `kill-line' but wo/ the save in `kill-ring' side effect."
  (interactive)
  (delete-region (point) (progn (forward-line 1)
                                (forward-char -1)
                                (point))))

(defun smed-line-delete-whole ()
  "Same as `kill-whole-line' but wo/ the save in `kill-ring' side effect."
  (interactive)
  (delete-region (progn (forward-line 0) (point))
                 (progn (forward-line 1) (point))))


(defun smed-line-kill-ring-save ()
  "Copy current line in `kill-ring' without killing."
  (interactive)
  (kill-ring-save (line-beginning-position) (line-beginning-position 2)) )
;; NOTE: we could have an optionnal param to tel wether get \n or not


(defun smed-line-kill-ring-save-trim ()
  "Copy current line in kill-ring, trimming begining spaces and tabs."
  (interactive)
  (if (not (smed--line-empty-p))
      (progn
	(beginning-of-line)
	(kill-ring-save (progn (skip-chars-forward " \t") (point))
			(line-beginning-position 2))
	;;(exchange-point-and-mark)
	(beginning-of-line))))

(defun smed-line-kill ()
  "Kill current line."
  (interactive)
  (if (smed--line-empty-p)
      (smed-line-delete-whole)
    (progn
      (kill-region (line-beginning-position) (line-beginning-position 2))
      (when smed-indent-after-kill
	    (indent-according-to-mode)))))


(defun smed-line-kill-trim ()
  "Kill current line, trimming begining spaces and tabs."
  (interactive)
  (if (smed--line-empty-p)
      (smed-line-delete-whole)
    (progn
      (beginning-of-line)
      (kill-region (progn (skip-chars-forward " \t") (point))
		   (line-beginning-position 2))
      (when smed-indent-after-kill
	    (indent-according-to-mode)))))

(defun smed-line-comment ()
  (interactive)
  (comment-or-uncomment-region (line-beginning-position) (line-beginning-position 2)))



;; COMANDS - COPY

(defun smed-copy-line-or-region ()
  "Copy current line or region."
  (interactive)
  (if (region-active-p)
      (smed-region-kill-ring-save)
    (smed-line-kill-ring-save-trim)))

(defun smed-copy-buffer ()
  "Copy whole buffer"
  (interactive)
  (save-excursion
    (call-interactively #'mark-whole-buffer)
    (copy-region-as-kill 1 (buffer-size))))

(defun smed-copy-line-or-region-org ()
  ;; NB: doesn't insert a line (unlike standard version)
  ;; org-copy-special does it for whole subtree, and inserts it perfectly
  "Copy the current line or current text selection."
  (interactive)
  (if (region-active-p)
      (kill-ring-save (region-beginning) (region-end))
    (progn
      (org-beginning-of-line)
      (skip-chars-forward " \t")
      (cua-set-mark)
      (org-end-of-line)
      (smed-copy-line-or-region)
      (org-beginning-of-line))))



;; COMMANDS - KILL (CUT)

(defun smed-kill-line-or-region ()
  "Cut the current line or current text selection and trim begining whitespaces."
  (interactive)
  (if (region-active-p)
      (smed-region-kill)
    (smed-line-kill-trim)))


(defun smed-kill-line-or-region-org ()
  ;; NB: leaves an empty line (unlike standard version)
  ;; org-cut-special does it for whole subtree wo/ leaving an empty line
  "Cut the current line, or current text selection."
  (interactive)
  (if (region-active-p)
      (kill-region (region-beginning) (region-end))
    (progn
      (org-beginning-of-line)
      ;; (skip-chars-forward " \t")
      (org-kill-line))))



;; COMMANDS - DUPLICATE

(defun smed-duplicate-line-or-region (&optional n)
  "Duplicate current line, or region if active.
With argument N, make N copies.
With negative N, comment out original line and use the absolute value."
  (interactive "*p")
  (let ((use-region (use-region-p)))
    (save-excursion
      (let ((text (if use-region        ;Get region if active, otherwise line
                      (buffer-substring (region-beginning) (region-end))
                    (prog1 (thing-at-point 'line)
                      (end-of-line)
                      (if (< 0 (forward-line 1)) ;Go to beginning of next line, or make a new one
                          (newline))))))
        (dotimes (_ (abs (or n 1)))     ;Insert N times, or once if not specified
          (insert text))))
    (if use-region nil                  ;Only if we're working with a line (not a region)
      (let ((pos (- (point) (line-beginning-position)))) ;Save column
        (if (> 0 n)                             ;Comment out original with negative arg
            (comment-region (line-beginning-position) (line-end-position)))
        (forward-line 1)
        (forward-char pos)))))



;; COMMANDS - COMMENT

(defun smed-toggle-comment ()
  "Toggle comment on the current line, or current text selection."
  (interactive)
  (if (region-active-p)
      (smed--region-comment)
    (progn
      (smed-line-comment)
      (smed-next-line))))

(defun smed-toggle-comment-c ()
  "Toggle comment on the current line, or current text selection."
  (interactive)

  (unless (derived-mode-p 'c-mode)
    (user-error "Attempted to call `smed-toggle-comment-c' on a non-C-style buffer."))

  (if (region-active-p)
	  (let ((comment-style 'multi-line)
            (comment-start "/* ")
            (comment-end   " */"))
	    (smed--region-comment))
	(let ((comment-style 'indent)
		  (comment-start "// ")
		  (comment-end   ""))
      (smed-line-comment)
      (smed-next-line))))



;; COMMANDS - TRIM

(defun smed-trim-here ()
  (interactive)
  (just-one-space)
  (delete-blank-lines))



;; COMMANDS - FILE NAMES

(defun smed-rename-file-and-buffer (&optional new-name)
  "Renames both current buffer and file it is visiting to NEW-NAME."
  (interactive)
  (let* ((buffer-name (buffer-name))
         (filename (buffer-file-name))
         (filename-nd (file-name-nondirectory filename)))

    (unless (and filename
                 (file-exists-p filename))
      (error "Buffer '%s' is not visiting a file!" buffer-name))

    (unless new-name
      ;; REVIEW: doc says that 2nd argument should not be used anymore
      (setq new-name (read-string "New name: " filename-nd)))

    (when (file-exists-p new-name)
      (error "A file named '%s' already exists!" new-name))

    (rename-file filename-nd new-name 1)
    (rename-buffer new-name)
    (set-visited-file-name new-name)
    (set-buffer-modified-p nil)))



;; COMMANDS - SEARCH / REPLACE

(defun replace-string-whole-buffer ()
  "Whole buffer version of replace-string"
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (call-interactively 'replace-string)))



;; AUTO-INDENT

;; REVIEW: just use `aggressive-indent'?

(defun smed-register-auto-indent ()
  ;; - after new line
  ;; NB: for c-mode-common-hook, it gets overriden by the completion advices, and thus must be defined after the later being called

  (mapc
   (lambda (mode)
     (let ((mode-hook (intern (concat (symbol-name mode) "-hook"))))
       (add-hook mode-hook (lambda nil (local-set-key (kbd "RET") 'newline-and-indent)))))
   '(ada-mode cperl-mode emacs-lisp-mode html-mode lisp-mode perl-mode
	          web-mode
              php-mode prolog-mode ruby-mode scheme-mode sgml-mode sh-mode sml-mode tuareg-mode web-mode))

  ;; - after yank

  (dolist (command '(yank yank-pop))
    (eval `(defadvice ,command (after indent-region activate)
	         (and (not current-prefix-arg)
		          (member major-mode '(emacs-lisp-mode lisp-mode
						                               clojure-mode    scheme-mode
						                               haskell-mode    ruby-mode
						                               rspec-mode      python-mode
						                               c-mode          c++-mode
						                               objc-mode       latex-mode
						                               php-mode        web-mode
						                               java-mode       javascript-mode
						                               plain-tex-mode)) ;; useless ?
		          (let ((mark-even-if-inactive transient-mark-mode))
		            (indent-region (region-beginning) (region-end) nil)))))))




(provide 'prf-smart-edit)

;;; prf-smart-edit.el ends here
