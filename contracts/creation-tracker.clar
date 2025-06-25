;; Creation Tracking Contract
;; Tracks document creation and metadata

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-NOT-FOUND (err u201))
(define-constant ERR-INVALID-INPUT (err u202))

;; Data Variables
(define-data-var next-document-id uint u1)

;; Data Maps
(define-map documents
  { document-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    hash: (string-ascii 64),
    created-at: uint,
    updated-at: uint,
    is-active: bool,
    category: (string-ascii 50)
  }
)

(define-map document-metadata
  { document-id: uint }
  {
    description: (string-ascii 500),
    tags: (string-ascii 200),
    size: uint,
    mime-type: (string-ascii 50)
  }
)

;; Public Functions

;; Create a new document
(define-public (create-document
  (title (string-ascii 100))
  (hash (string-ascii 64))
  (category (string-ascii 50))
  (description (string-ascii 500))
  (tags (string-ascii 200))
  (size uint)
  (mime-type (string-ascii 50))
)
  (let ((document-id (var-get next-document-id)))
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len hash) u0) ERR-INVALID-INPUT)

    (map-set documents
      { document-id: document-id }
      {
        creator: tx-sender,
        title: title,
        hash: hash,
        created-at: block-height,
        updated-at: block-height,
        is-active: true,
        category: category
      }
    )

    (map-set document-metadata
      { document-id: document-id }
      {
        description: description,
        tags: tags,
        size: size,
        mime-type: mime-type
      }
    )

    (var-set next-document-id (+ document-id u1))
    (ok document-id)
  )
)

;; Update document metadata
(define-public (update-metadata
  (document-id uint)
  (description (string-ascii 500))
  (tags (string-ascii 200))
)
  (let ((document (unwrap! (map-get? documents { document-id: document-id }) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get creator document)) ERR-NOT-AUTHORIZED)
    (asserts! (get is-active document) ERR-NOT-AUTHORIZED)

    (map-set document-metadata
      { document-id: document-id }
      (merge (unwrap! (map-get? document-metadata { document-id: document-id }) ERR-NOT-FOUND)
             { description: description, tags: tags })
    )

    (map-set documents
      { document-id: document-id }
      (merge document { updated-at: block-height })
    )

    (ok true)
  )
)

;; Deactivate document
(define-public (deactivate-document (document-id uint))
  (let ((document (unwrap! (map-get? documents { document-id: document-id }) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get creator document)) ERR-NOT-AUTHORIZED)

    (map-set documents
      { document-id: document-id }
      (merge document { is-active: false, updated-at: block-height })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get document information
(define-read-only (get-document (document-id uint))
  (map-get? documents { document-id: document-id })
)

;; Get document metadata
(define-read-only (get-document-metadata (document-id uint))
  (map-get? document-metadata { document-id: document-id })
)

;; Get next document ID
(define-read-only (get-next-document-id)
  (var-get next-document-id)
)

;; Check if document exists and is active
(define-read-only (is-document-active (document-id uint))
  (match (map-get? documents { document-id: document-id })
    document (get is-active document)
    false
  )
)
