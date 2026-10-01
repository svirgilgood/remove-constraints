(in-package :remove-constraints)

(ql:quickload '(:parse-number :com.inuoe.jzon))
(sb-ext:add-package-local-nickname :jzon :com.inuoe.jzon)

; Find objects with a constraints.txt
; delete the version directory with the constraints.txt
; mv the inventory.json and the inventory.json.sha512 from the version -1 to the base directory
; re-run the ocfl validation
(defun write-to-file (save-file constraints-path)
  (declare (type string save-file)
           (type pathname constraints-path))
  "This takes the constraints path which will be a constraints.txt path
  The path then is then extracted to the objects level.
  The inventory.json will be extracted and then the ark-id will be returned and prented to the save file"
  (let* ((inventory-path (merge-pathnames "inventory.json" (uiop:pathname-parent-directory-pathname (uiop:pathname-parent-directory-pathname constraints-path))))
         (ark-id (gethash "id" (jzon:parse inventory-path))))
    (with-open-file (stream save-file :direction :output :if-exists :append :if-does-not-exist :create)
      (format stream "~A~%" ark-id))))

(defun extract-version-number (parent-dir)
  "this should be the version directory "
  (let ((version (car (nreverse (pathname-directory parent-dir)))))
    (parse-number:parse-number (remove-if-not #'digit-char-p version))))

(defun delete-constraints (constraints-path)
  "This deletes the constraints path and moves the previous versions inventory
  to the head."
  (let* ((parent-version (uiop:pathname-parent-directory-pathname constraints-path))
         (object-path (uiop:pathname-parent-directory-pathname parent-version))
         (version-number (extract-version-number parent-version))
         (previous-vers-dir (merge-pathnames (format nil "v~A/" (- version-number 1)) object-path))
         (inventory-path (merge-pathnames "inventory.json" previous-vers-dir) )
         (inventory-hash-path (merge-pathnames "inventory.json.sha512" previous-vers-dir)))
    (uiop:copy-file inventory-path (merge-pathnames "inventory.json" object-path ))
    (uiop:copy-file inventory-hash-path (merge-pathnames "inventory.json.sha512" object-path))
    (uiop:delete-directory-tree (uiop:pathname-parent-directory-pathname constraints-path) :validate t)))
    ;(format t "Delete: ~A~%" (uiop:pathname-parent-directory-pathname constraints-path))))

(defun find-constraints-files (root save-file)
  "This iterates through the root, finding all `constraints.txt` files
  in the rooted directory."
  (uiop:collect-sub*directories
    (uiop:ensure-directory-pathname root)
    (constantly t)      ; collect every directory
    (constantly t)      ; recurse into every directory
    (lambda (dir)
      (let ((candidate (merge-pathnames "constraints.txt" dir)))
        (when (probe-file candidate)
          (progn
            (if save-file
                (write-to-file save-file candidate))
            (delete-constraints candidate)))))))

(defun main ()
  "Do we have an option for saving data?"
  (let ((root (cadr sb-ext:*posix-argv*))
        (save-file (caddr sb-ext:*posix-argv*)))
    (if root
        (find-constraints-files root save-file)
        (find-constraints-files "." save-file))))
