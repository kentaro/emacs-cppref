;;; cppref.el --- A Simple C++ Reference Viewer

;; Copyright (C) 2009 Kentaro Kuribayashi

;; Author: Kentaro Kuribayashi, <kentarok@gmail.com>
;; Keywords: C++

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; * Description

;; cppref.el is a port of Perl's cppref command, a simple C++
;; reference viewer working on a terminal.

;; * Usage
;;
;; cppref.el requires cl and emacs-w3m installed in advance. So, add
;; the lines below into your .emacs:
;;
;;   (require 'cppref)
;;
;; Althogh cppref.el automatically find out the place of
;; documentation, if you want to put your the directory at some other
;; place, you must add one more line like below:
;;
;;   (setq cppref-doc-dir "/path/to/dir") ;; doesn't end with "/"
;;
;; Then run `cppref' command and type like "vector::begin",
;; "io::fopen", or so.

;;; Acknowledment:

;; cppref.el is Emacs version of Kazuho Oku's cppref command
;; http://search.cpan.org/dist/cppref/

;; The documents are from http://www.cppreference.com/ (under Creative
;; Commons Attribution 3.0 license).

;;; Code:

(eval-when-compile
  (require 'cl)
  (require 'w3m-load)
  (load "find-func") ;; for `find-library-name' to be loaded.
  )

(defvar cppref-doc-dir nil
  "Your local directory in which C++ references are placed")

(defun cppref (name)
  "Show C++ reference along with arg `name' using w3m web
browser."
  (interactive "sName: ")
  (cppref-init-doc-dir)
  (let ((candidates nil)
        (reference nil))
    (when (string-equal name "")
      (setq name "start"))

    ;; replace "class::method" to "class/method"
    (setq name (replace-regexp-in-string "::" "/" name))

    ;; directory index is like ***/start.html
    (when (file-directory-p (concat cppref-doc-dir "/" name))
      (setq name (concat name "/start")))

    (setq candidates
          (let ((file (concat cppref-doc-dir "/" name ".html")))
            (if (file-exists-p file)
                (list file)
              (cppref-find-reference cppref-doc-dir name))))

    (setq reference  (car candidates))
    (setq candidates (cdr candidates))

    (if (not reference)
        (error (concat "no document found for " name)))
    (if candidates
	(setq reference (cppref-select-from-multiple-choices
			 candidates)))
    (cppref-visit-reference reference)))

(defun cppref-select-from-multiple-choices (choices)
  (completing-read "multiple choies. push tab key. select :" choices nil t ""))

(defun cppref-init-doc-dir ()
  (if (not cppref-doc-dir)
      (let* ((library-path (find-library-name "cppref"))
             (library-root (file-name-directory library-path)))
        (setq cppref-doc-dir (concat library-root "docs")))))

(defun cppref-visit-reference (reference)
  (w3m-find-file reference))

(defun cppref-find-reference (dir name)
  (let ((candidates '())
        (reference  nil)
        (absolute-path nil))
    (loop for fn
          in (directory-files dir)
          do (setq absolute-path (concat dir "/" fn))
             (if (file-directory-p absolute-path)
                 (when (and (not (string-equal fn "."))
                            (not (string-equal fn "..")))
                   (if (string-match (concat name "$") absolute-path)
                       (push (concat absolute-path "/start.html") candidates)
                     (setq candidates
                           (append (cppref-find-reference absolute-path name)
                                   candidates))))
               (when (string-match (concat name "\\.html$") absolute-path)
                 (push absolute-path candidates))))
    candidates))

(provide 'cppref)
;;; cppref.el ends here
