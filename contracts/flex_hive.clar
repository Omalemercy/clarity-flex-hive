;; FlexHive Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-state (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-invalid-duration (err u106))
(define-constant err-invalid-rating (err u107))
(define-constant err-dispute-exists (err u108))

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
    status: (string-ascii 20),
    escrow-amount: uint,
    dispute-status: (optional (string-ascii 20))
})

(define-map applications {gig-id: uint, applicant: principal} {
    cover-letter: (string-ascii 500),
    status: (string-ascii 20)
})

(define-map ratings {user: principal, gig-id: uint} {
    rating: uint,
    review: (string-ascii 500),
    timestamp: uint
})

(define-map disputes uint {
    initiator: principal,
    reason: (string-ascii 500),
    status: (string-ascii 20),
    resolution: (optional (string-ascii 500))
})

;; Public functions
(define-public (create-gig (title (string-ascii 100)) (payment uint) (duration uint) (description (string-ascii 1000)))
    (let ((gig-id (+ (var-get gig-counter) u1)))
        (try! (validate-gig-params payment duration))
        (try! (stx-transfer? payment tx-sender (as-contract tx-sender)))
        
        (map-set gigs gig-id {
            title: title,
            payment: payment,
            duration: duration,
            description: description,
            employer: tx-sender,
            worker: none,
            status: "open",
            escrow-amount: payment,
            dispute-status: none
        })
        (var-set gig-counter gig-id)
        (ok gig-id)
    )
)

(define-public (apply-for-gig (gig-id uint) (cover-letter (string-ascii 500)))
    (let ((gig (unwrap! (map-get? gigs gig-id) err-not-found)))
        (asserts! (is-eq (get status gig) "open") err-invalid-state)
        (asserts! (not (is-eq tx-sender (get employer gig))) err-unauthorized)
        
        (map-set applications {gig-id: gig-id, applicant: tx-sender} {
            cover-letter: cover-letter,
            status: "pending"
        })
        (ok true)
    )
)

(define-public (initiate-dispute (gig-id uint) (reason (string-ascii 500)))
    (let ((gig (unwrap! (map-get? gigs gig-id) err-not-found)))
        (asserts! (is-eq (get status gig) "in-progress") err-invalid-state)
        (asserts! (or (is-eq tx-sender (get employer gig)) 
                    (is-eq tx-sender (unwrap! (get worker gig) err-not-found))) 
                err-unauthorized)
        
        (map-set disputes gig-id {
            initiator: tx-sender,
            reason: reason,
            status: "open",
            resolution: none
        })
        
        (map-set gigs gig-id (merge gig {
            dispute-status: (some "open")
        }))
        (ok true)
    )
)

(define-public (resolve-dispute (gig-id uint) (resolution (string-ascii 500)) (refund-percentage uint))
    (let ((gig (unwrap! (map-get? gigs gig-id) err-not-found))
          (dispute (unwrap! (map-get? disputes gig-id) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= refund-percentage u100) err-invalid-amount)
        
        (let ((refund-amount (/ (* (get escrow-amount gig) refund-percentage) u100))
              (payment-amount (- (get escrow-amount gig) refund-amount)))
            
            (try! (as-contract (stx-transfer? refund-amount tx-sender (get employer gig))))
            (try! (as-contract (stx-transfer? payment-amount tx-sender (unwrap! (get worker gig) err-not-found))))
            
            (map-set disputes gig-id (merge dispute {
                status: "resolved",
                resolution: (some resolution)
            }))
            
            (map-set gigs gig-id (merge gig {
                status: "completed",
                dispute-status: (some "resolved")
            }))
            (ok true)
        )
    )
)

;; Private functions
(define-private (validate-gig-params (payment uint) (duration uint))
    (begin
        (asserts! (> payment u0) err-invalid-amount)
        (asserts! (and (>= duration u1) (<= duration u365)) err-invalid-duration)
        (ok true)
    )
)

;; Read only functions
(define-read-only (get-gig (gig-id uint))
    (ok (map-get? gigs gig-id))
)

(define-read-only (get-dispute (gig-id uint))
    (ok (map-get? disputes gig-id))
)
