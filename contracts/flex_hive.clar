;; FlexHive Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-state (err u104))

;; Data Variables
(define-data-var gig-counter uint u0)

;; Define maps
(define-map gigs uint {
    title: (string-ascii 100),
    payment: uint,
    duration: uint,
    description: (string-ascii 1000),
    employer: principal,
    worker: (optional principal),
    status: (string-ascii 20)
})

(define-map applications {gig-id: uint, applicant: principal} {
    cover-letter: (string-ascii 500),
    status: (string-ascii 20)
})

(define-map ratings {user: principal, gig-id: uint} {
    rating: uint,
    review: (string-ascii 500)
})

;; Public functions
(define-public (create-gig (title (string-ascii 100)) (payment uint) (duration uint) (description (string-ascii 1000)))
    (let ((gig-id (+ (var-get gig-counter) u1)))
        (try! (validate-user-can-create-gig))
        (map-set gigs gig-id {
            title: title,
            payment: payment,
            duration: duration,
            description: description,
            employer: tx-sender,
            worker: none,
            status: "open"
        })
        (var-set gig-counter gig-id)
        (ok gig-id)
    )
)

(define-public (apply-for-gig (gig-id uint) (cover-letter (string-ascii 500)))
    (let ((gig (unwrap! (map-get? gigs gig-id) err-not-found)))
        (asserts! (is-eq (get status gig) "open") err-invalid-state)
        (map-set applications {gig-id: gig-id, applicant: tx-sender} {
            cover-letter: cover-letter,
            status: "pending"
        })
        (ok true)
    )
)

(define-public (accept-application (gig-id uint) (applicant principal))
    (let (
        (gig (unwrap! (map-get? gigs gig-id) err-not-found))
        (application (unwrap! (map-get? applications {gig-id: gig-id, applicant: applicant}) err-not-found))
    )
        (asserts! (is-eq tx-sender (get employer gig)) err-unauthorized)
        (asserts! (is-eq (get status gig) "open") err-invalid-state)
        
        (try! (stx-transfer? (get payment gig) tx-sender (as-contract tx-sender)))
        
        (map-set gigs gig-id (merge gig {
            worker: (some applicant),
            status: "in-progress"
        }))
        (ok true)
    )
)

(define-public (complete-gig (gig-id uint))
    (let ((gig (unwrap! (map-get? gigs gig-id) err-not-found)))
        (asserts! (is-eq tx-sender (get employer gig)) err-unauthorized)
        (asserts! (is-eq (get status gig) "in-progress") err-invalid-state)
        
        (try! (as-contract (stx-transfer? (get payment gig) tx-sender (unwrap! (get worker gig) err-not-found))))
        
        (map-set gigs gig-id (merge gig {
            status: "completed"
        }))
        (ok true)
    )
)

;; Private functions
(define-private (validate-user-can-create-gig)
    (ok true)
)

;; Read only functions
(define-read-only (get-gig (gig-id uint))
    (ok (map-get? gigs gig-id))
)

(define-read-only (get-applications (gig-id uint))
    (ok (map-get? applications {gig-id: gig-id, applicant: tx-sender}))
)
