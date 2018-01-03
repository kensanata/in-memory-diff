;;; in-memory-diff.el --- diff lines of two buffers

;; Copyright (C) 2017-2018 Alex Schroeder, Dan Harms

;; Author: Alex Schroeder <alex@gnu.org>
;; Version: 0.1
;; Keywords: text tools unix
;; URL: https://github.com/kensanata/in-memory-diff.git

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.

;; You should have received a copy of the GNU General Public
;; License along with this program; if not, write to the Free
;; Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
;; MA 02111-1307 USA

;;; Commentary:

;; `in-memory-diff' takes two source buffers and treats their content
;; as a set of unordered lines, as one would excpect for a file like
;; ~/.authinfo.gpg, for example.  We don't use diff(1) to diff the
;; buffers and thus we don't write temporary files to disk.  The result
;; is two buffers, *A* and *B*.  Each contains the lines the other
;; buffer does not contain.  These files are in a major mode with the
;; following interesting keys bindings:
;;
;; c – copy the current line to the other source buffer
;; k - kill the current line from this source buffer
;; RET - visit the current line in this source buffer
;;
;; In theory, using c and k on all the lines should result in the two
;; source containing the same lines a subsequent call of
;; in-memory-diff showing two empty buffers.

;;; Code:

(defvar in-memory-this nil
  "This source buffer.")

(defvar in-memory-other nil
  "The other source buffer.")

(defun in-memory-line ()
  "Return the current line."
  (buffer-substring-no-properties
   (line-beginning-position)
   (line-end-position)))

(defun in-memory-delete-this-line ()
  "Delete the current line."
  (let ((inhibit-read-only t))
    (delete-region
     (line-beginning-position)
     (line-end-position))))

(defun in-memory-diff-copy ()
  "Copy the current line to the other buffer.

The other buffer is in `in-memory-other'."
  (interactive)
  (let ((line (in-memory-line)))
    (with-current-buffer in-memory-other
      (goto-char (point-max))
      (insert line "\n"))
    (in-memory-delete-this-line)))

(defun in-memory-diff-kill ()
  "Kill the current line in this buffer.

This buffer is in `in-memory-this'."
  (interactive)
  (let ((line (in-memory-line)))
    (with-current-buffer in-memory-this
      (goto-char (point-min))
      (while (re-search-forward (concat "^" (regexp-quote line) "$") nil t)
        (replace-match "")))
    (in-memory-delete-this-line)))

(defun in-memory-diff-visit ()
  "Visit the current line in this buffer.

This buffer is in `in-memory-this'."
  (interactive)
  (let ((line (in-memory-line)))
    (pop-to-buffer in-memory-this)
    (goto-char (point-min))
    (when (re-search-forward (concat "^" (regexp-quote line) "$") nil t)
      (goto-char (match-beginning 0)))))

(defvar in-memory-diff-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "c" 'in-memory-diff-copy)
    (define-key map "k" 'in-memory-diff-kill)
    (define-key map "q" 'bury-buffer)
    (define-key map (kbd "RET") 'in-memory-diff-visit)
    map)
  "Keymap for In Memory Diff mode.")

(define-derived-mode in-memory-diff-mode fundamental-mode "extra-lines")

(defun in-memory-insert (lines1 lines2)
  "Insert all the lines of LINES1 not in LINES2 in the current buffer."
  (dolist (line lines1)
    (when (not (member line lines2))
      (insert line "\n"))))

(defun in-memory-name-buffer (bufname)
  "Name an `in-memory-diff' buffer according to original buffer BUFNAME."
  (format " *extra lines in %s*" bufname))

(defun in-memory-diff (buffer1 buffer2)
  "Show the difference between two buffers.

BUFFER1 and BUFFER2 are treated as a set of unordered lines, as
one would excpect for a file like ~/.authinfo.gpg, for example.
We don't use diff(1) to diff the buffers and don't write
temporary files to disk."
  (interactive "bFirst buffer: \nbSecond buffer: ")
  (let ((lines (mapcar (lambda (buf)
                         (with-current-buffer buf
                           (split-string (buffer-string) "\n")))
                       (list buffer1 buffer2))))

    (with-current-buffer (get-buffer-create (in-memory-name-buffer buffer1))
      (let ((inhibit-read-only t))
        (erase-buffer)
        (apply 'in-memory-insert lines))
      (in-memory-diff-mode)
      (set (make-local-variable 'in-memory-this) buffer1)
      (set (make-local-variable 'in-memory-other) buffer2)
      (display-buffer (current-buffer)))
    (with-current-buffer (get-buffer-create (in-memory-name-buffer buffer2))
      (let ((inhibit-read-only t))
        (erase-buffer)
        (apply 'in-memory-insert (reverse lines)))
      (in-memory-diff-mode)
      (set (make-local-variable 'in-memory-this) buffer2)
      (set (make-local-variable 'in-memory-other) buffer1)
      (display-buffer (current-buffer) 'display-buffer-pop-up-window))))

(provide 'in-memory-diff)

;;; in-memory-diff.el ends here
