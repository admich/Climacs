;;; -*- Mode: Lisp; Package: CLIMACS-COMMANDS -*-

;;;  (c) copyright 2004-2005 by
;;;           Robert Strandh (robert.strandh@gmail.com)
;;;  (c) copyright 2004-2005 by
;;;           Elliott Johnson (ejohnson@fasl.info)
;;;  (c) copyright 2005 by
;;;           Matthieu Villeneuve (matthieu.villeneuve@free.fr)
;;;  (c) copyright 2005 by
;;;           Aleksandar Bakic (a_bakic@yahoo.com)
;;;  (c) copyright 2007 by
;;;           Troels Henriksen (athas@sigkill.dk)

;;; This library is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU Library General Public
;;; License as published by the Free Software Foundation; either
;;; version 2 of the License, or (at your option) any later version.
;;;
;;; This library is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Library General Public License for more details.
;;;
;;; You should have received a copy of the GNU Library General Public
;;; License along with this library; if not, write to the
;;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;;; Boston, MA  02111-1307  USA.

;;; Miscellaneous commands for the Climacs editor. 

(cl:in-package #:climacs-commands)

(define-command (com-not-modified :name t :command-table buffer-table) ()
  #.(format nil "Clear the modified flag for the current buffer.~@
                 The modified flag is automatically set when the~@
                 contents of the buffer are changed. This flag is~@
                 consulted, for instance, when deciding whether~@
                 to prompt you to save the buffer before killing it.")
  (setf (esa-buffer:needs-saving (esa:current-buffer)) nil))

(esa:set-key 'com-not-modified
	     'buffer-table
	     '((#\~ :meta)))

(define-command (com-what-cursor-position :name t :command-table info-table) ()
  #.(format nil "Print information about point.~@
                 Gives the character after point (name and octal,~@
                 decimal and hexidecimal charcode), the offset of point,~@
                 the total objects in the buffer, and the percentage ~@
                 of the buffers objects before point.~@
                 ~@
                 FIXME: gives no information at end of buffer.")
  (let* ((char (or (drei-buffer:end-of-buffer-p (point)) (drei-buffer:object-after (point))))
	 (column (drei-buffer:column-number (point))))
    (esa:display-message "Char: ~:[none~*~;~:*~:C (#o~O ~:*~D ~:*#x~X)~] point=~D of ~D (~D%) column ~D"
		     (and (characterp char) char)
		     (and (characterp char) (char-code char))
		     (drei-buffer:offset (point)) (drei-buffer:size (esa:current-buffer))
		     (if (drei-buffer:size (esa:current-buffer))
                         (round (* 100 (/ (drei-buffer:offset (point))
                                          (drei-buffer:size (esa:current-buffer)))))
                         100)
		     column)))

(esa:set-key 'com-what-cursor-position
	     'info-table
	     '((#\x :control) (#\=)))

(define-command (com-browse-url :name t :command-table base-table) 
    ((url 'url :prompt "Browse URL"))
  (declare (ignorable url))
  #+ (and sbcl darwin)
     (sb-ext:run-program "/usr/bin/open" `(,url) :wait nil)
  #+ (and openmcl darwin)
     (ccl:run-program "/usr/bin/open" `(,url) :wait nil))

(define-command (com-set-syntax :name t :command-table buffer-table) 
    ((syntax 'drei-syntax:syntax
      :prompt "Name of syntax"))
  #.(format nil "Prompts for a syntax to set for the current buffer.~@
                 Setting a syntax will cause the buffer to be~@
                 reparsed using the new syntax.")
  (set-syntax (current-view) syntax))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 
;;; Groups

(define-command (com-define-group :name t :command-table global-climacs-table)
    ((name 'string :prompt "Name")
     (views '(sequence view) :prompt "Views"))
  (when (or (not (get-group name))
            (accept 'boolean
		    :prompt "Group already exists. Overwrite existing group?"))
    (add-group name views))
  (select-group (get-group name)))

(esa:set-key `(com-define-group ,*unsupplied-argument-marker*
				,*unsupplied-argument-marker*)
	     'global-climacs-table
	     '((#\x :control) (#\g) (#\d)))

(define-command (com-define-file-group :name t :command-table global-climacs-table)
    ((name 'string :prompt "Name")
     (pathnames '(sequence pathname) :prompt "Files"))
  (when (or (not (get-group name))
            (accept 'boolean
		    :prompt "Group already exists. Overwrite existing group?"))
    (add-group name pathnames))
  (select-group (get-group name)))

(esa:set-key `(com-define-file-group ,*unsupplied-argument-marker*
				     ,*unsupplied-argument-marker*)
	     'global-climacs-table
	     '((#\x :control) (#\g) (#\f)))

(define-command (com-select-group :name t :command-table global-climacs-table)
    ((group 'group))
  (select-group group))

(esa:set-key `(com-select-group ,*unsupplied-argument-marker*)
	     'global-climacs-table
	     '((#\x :control) (#\g) (#\s)))

(define-command (com-deselect-group :name t :command-table global-climacs-table)
    ()
  (deselect-group)
  (esa:display-message "Group deselected"))

(esa:set-key 'com-deselect-group
	     'global-climacs-table
	     '((#\x :control) (#\g) (#\u)))

(define-command (com-current-group :name t :command-table global-climacs-table)
    ()
  (esa:with-minibuffer-stream (s)
    (format s "Active group is: ")
    (present (get-active-group) 'group :stream s)))

(esa:set-key 'com-current-group
	     'global-climacs-table
	     '((#\x :control) (#\g) (#\c)))

(define-command (com-list-group-contents
		 :name t
		 :command-table global-climacs-table)
    ()
  (esa:with-minibuffer-stream (s)
    (format s "Active group designates: ")
    (display-group-contents (get-active-group) s)))

(esa:set-key 'com-list-group-contents
	     'global-climacs-table
	     '((#\x :control) (#\g) (#\l)))
