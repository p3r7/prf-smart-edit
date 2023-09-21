# prf-smart-edit

Saner default for Emacs text manipulation.

This is old code, from my early elisp-ing, back from Emacs 22!

It works but bad bad code. Don't use.

## installation

```el
(use-package prf-smart-edit
  :quelpa (prf-smart-edit :fetcher github :repo "p3r7/prf-smart-edit")
  :after (org)
  :demand
  :bind (("M-w" . smed-copy-line-or-region)
	     ("M-W" . smed-copy-buffer)
	     ("C-w" . smed-kill-line-or-region)
	     ("C-d" . smed-duplicate-line-or-region)
	     ("C-<f8>" . smed-toggle-comment)
         ("<C-kp-divide>" . smed-toggle-comment)
	     ("C-x C-o" . smed-trim-here)
         ("C-x W" . smed-rename-file-and-buffer)
	     :map org-mode-map
	     ("M-w" . smed-copy-line-or-region-org)
	     ("C-w" . smed-kill-line-or-region-org)
   :config
   (add-hook 'c-mode-common-hook
 	        #'(lambda()
	            (local-set-key (kbd "C-<f8>") #'smed-toggle-comment-c)
	            (local-set-key (kbd "<C-kp-divide>") #'smed-toggle-comment-c)))))
```

## credits

Lots of small snippets whre mostly copy-pasted blindly from the [EMACS-FU blog](http://emacs-fu.blogspot.com/). So lots of credits goes to [@djcb](https://github.com/djcb).

Similar functions that might have also been a source of inspiration:
- Xah Lee's `xah-copy-line-or-region` & `xah-cut-line-or-region` ([`source`](http://xahlee.info/emacs/emacs/emacs_copy_cut_current_line.html))
- This `copy-line` (without kill) from this [old emacsblog post](https://web.archive.org/web/20120808214140/http://emacsblog.org/2009/05/18/copying-lines-not-killing/)
- The whole [EmacsWiki - CopyingWholeLines](https://web.archive.org/web/20120624162546/http://www.emacswiki.org/emacs/CopyingWholeLines) page
- For `smed-toggle-comment-c`, [those](http://stackoverflow.com/questions/1551854/emacs-comment-region-in-c-mode) [two](http://stackoverflow.com/questions/6909292/getting-emacs-m-to-produce-style-comments) StackOverflow questions.

`smed-rename-file-and-buffer` is a robustified version of Steve Purcell's `rename-this-file-and-buffer` that can be found in his [emacs.d](https://github.com/purcell/emacs.d/blob/master/lisp/init-utils.el).

The autoindentation most likely comes from [EmacsWiki - Indentation](http://emacswiki.org/emacs/AutoIndentation).


## similar projects

- https://github.com/paldepind/smart-comment
- https://github.com/bbatsov/crux
- https://github.com/leoliu/easy-kill

There are (more basic) defadvice equivalents to `smed-copy-line-or-region` & `smed-kill-line-or-region` and `smed-toggle-comment` that get reposted everywhere. Idk their origin but here they are for reference:

```el
(defadvice kill-ring-save (before slickcopy activate compile)
  "When called interactively with no active region, copy a single line instead."
  (interactive
   (if mark-active (list (region-beginning) (region-end))
     (list (line-beginning-position)
           (line-beginning-position 2)))))

(defadvice kill-region (before slickcut activate compile)
  "When called interactively with no active region, kill a single line instead."
  (interactive
   (if mark-active (list (region-beginning) (region-end))
     (list (line-beginning-position)
           (line-beginning-position 2)))))

(defadvice comment-or-uncomment-region (before slickccomment activate compile)
  "When called interactively with no active region, kill a single line instead."
  (interactive
   (if mark-active (list (region-beginning) (region-end))
     (list (line-beginning-position)
           (line-beginning-position 2)))))
```
