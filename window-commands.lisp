;;; -*- Mode: Lisp; Package: CLIMACS-GUI -*-

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

;;; Window commands for the Climacs editor. 

(cl:in-package #:climacs-commands)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 
;;; Commands for splitting windows

(defun split-window-maybe-cloning (vertically-p clone-current-view-p)
  #.(format nil "If VERTICALLY-P is true, then split the current~@
                 window vertially.  Otherwise split it horizontally.~@
                 If CLONE-CURRENT-VIEW-P is true, then use a clone~@
                 of the current window for the new window.")
  (handler-bind ((climacs-gui:view-already-displayed
                  #'(lambda (condition)
                      (declare (ignore condition))
                      ;; If this happens, `clone-current-view-p' is false.
                      (esa:display-message "Can't split: no view available ~
                                            for new window")
                      (return-from split-window-maybe-cloning nil))))
    (climacs-gui:split-window vertically-p clone-current-view-p)))

(clim:define-command (com-split-window-vertically
		      :name t
		      :command-table window-table)
    ((clone-current-view 'boolean :default nil))
  (split-window-maybe-cloning t clone-current-view))

(esa:set-key `(com-split-window-vertically ,*numeric-argument-marker*)
	     'window-table
	     '((#\x :control) (#\2)))

(clim:define-command (com-split-window-horizontally
		      :name t
		      :command-table window-table)
    ((clone-current-view 'boolean :default nil))
  (split-window-maybe-cloning nil clone-current-view))

(esa:set-key `(com-split-window-horizontally ,*numeric-argument-marker*)
	     'window-table
	     '((#\x :control) (#\3)))

(clim:define-command (com-other-window
		      :name t
		      :command-table window-table)
    ()
  (other-window))

(esa:set-key 'com-other-window
	     'window-table
	     '((#\x :control) (#\o)))

(defun click-to-offset (window x y)
  (with-accessors ((top top) (bot bot)) (clim:view window)
    (let ((new-x (floor x (stream-character-width window #\m)))
          (new-y (floor y (stream-line-height window)))
          (buffer (buffer (clim:view window))))
      (loop for scan from (drei-buffer:offset top)
	    with lines = 0
	    until (= scan (drei-buffer:offset bot))
	    until (= lines new-y)
	    when (eql (drei-buffer:buffer-object buffer scan) #\Newline)
	      do (incf lines)
	    finally (loop for columns from 0
			  until (= scan (drei-buffer:offset bot))
			  until (eql (drei-buffer:buffer-object buffer scan) #\Newline)
			  until (= columns new-x)
			  do (incf scan))
		    (return scan)))))

(clim:define-command (com-switch-to-this-window
		      :name nil
		      :command-table window-table)
    ((window 'pane) (x 'integer) (y 'integer))
  (other-window window)
  (when (and (buffer-pane-p window)
             (typep (clim:view window) 'point-mark-view))
    (setf (drei-buffer:offset (point (clim:view window)))
	  (click-to-offset window x y))))

(define-presentation-to-command-translator blank-area-to-switch-to-this-window
    (blank-area com-switch-to-this-window window-table
                :echo nil)
    (window x y)
  (list window x y))

(define-gesture-name :select-other :pointer-button (:right) :unique nil)

(clim:define-command (com-mouse-save :name nil :command-table window-table)
    ((window 'pane) (x 'integer) (y 'integer))
  (when (and (buffer-pane-p window)
	     (eq window (esa:current-window)))
    (setf (drei-buffer:offset (drei-buffer:mark (clim:view window)))
	  (click-to-offset window x y))
    (drei-commands::com-exchange-point-and-mark)
    (drei-commands::com-copy-region)))

(define-presentation-to-command-translator blank-area-to-mouse-save
    (blank-area com-mouse-save window-table :echo nil :gesture :select-other)
    (window x y)
  (list window x y))

(define-gesture-name :middle-button :pointer-button (:middle) :unique nil)

(clim:define-command (com-yank-here :name nil :command-table window-table)
    ((window 'pane) (x 'integer) (y 'integer))
  (when (buffer-pane-p window)
    (other-window window)
    (setf (drei-buffer:offset (point (clim:view window)))
	  (click-to-offset window x y))
    (drei-commands::com-yank)))

(define-presentation-to-command-translator blank-area-to-yank-here
    (blank-area com-yank-here window-table :echo nil :gesture :middle-button)
    (window x y)
  (list window x y))

(defun single-window ()
  (loop until (null (cdr (esa:windows *application-frame*)))
	do (rotatef (car (esa:windows *application-frame*))
		    (cadr (esa:windows *application-frame*)))
	   (com-delete-window))
  (setf *standard-output* (car (esa:windows *application-frame*))))

(clim:define-command (com-single-window :name t :command-table window-table)
    ()
  (single-window))

(esa:set-key 'com-single-window
	     'window-table
	     '((#\x :control) (#\1)))

(clim:define-command (com-scroll-other-window
		      :name t
		      :command-table window-table)
    ()
  (let ((other-window (second (esa:windows *application-frame*))))
    (when other-window
      (page-down other-window (clim:view other-window)))))

(esa:set-key 'com-scroll-other-window
	     'window-table
	     '((#\v :control :meta)))

(clim:define-command (com-scroll-other-window-up
		      :name t
		      :command-table window-table)
    ()
  (let ((other-window (second (esa:windows *application-frame*))))
    (when other-window
      (page-up other-window (clim:view other-window)))))

(esa:set-key 'com-scroll-other-window-up
	     'window-table
	     '((#\V :control :meta)))

(clim:define-command (com-delete-window :name t :command-table window-table) ()
  (climacs-gui:delete-window))

(esa:set-key 'com-delete-window
	     'window-table
	     '((#\x :control) (#\0)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 
;;; Commands for switching/killing current view.

(clim:define-command (com-switch-to-view :name t :command-table window-table)
    ;; Perhaps the default should be an undisplayed view?
    ((view 'view :default (or (find (current-view) (views *application-frame*)
                               :test (complement #'eq))
                              (any-view))))
  #.(format nil "Prompt for a view name and switch to that view.~@
                 If the a view with that name does not exist,~@
                 create a buffer-view with the name and switch to it.~@
                 Uses the name of the next view (if any) as a default.")
  (handler-case (switch-to-view (esa:current-window) view)
    (climacs-gui:view-already-displayed (condition)
      (other-window (window condition)))))

(esa:set-key `(com-switch-to-view ,clim:*unsupplied-argument-marker*)
	     'window-table
	     '((#\x :control) (#\b)))

(clim:define-command (com-kill-view :name t :command-table window-table)
    ((view 'view :prompt "Kill view"
                 :default (current-view)))
  #.(format nil "Prompt for a view name and kill that view.~@
                 If the view is of a buffer and the buffer needs~@
                 saving, prompt the user before killing it.~@
                 Uses the current view as a default.")
  (climacs-core:kill-view view))

(esa:set-key `(com-kill-view ,clim:*unsupplied-argument-marker*)
	     'window-table
	     '((#\x :control) (#\k)))

(esa-utils:define-menu-table window-menu-table (window-table)
  '(com-split-window-vertically nil)
  '(com-split-window-horizontally nil)
  'com-other-window
  'com-single-window
  'com-delete-window
  :divider
  `(com-switch-to-view ,clim:*unsupplied-argument-marker*)
  `(com-kill-view ,clim:*unsupplied-argument-marker*))
