;; Donation Splitter Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-invalid-percentage (err u103))

;; Data Variables
(define-data-var total-donations uint u0)
(define-data-var total-charities uint u0)

;; Data Maps
(define-map charities principal {
    name: (string-ascii 50),
    percentage: uint,
    total-received: uint,
    active: bool
})

;; Read Only Functions
(define-read-only (get-charity-info (charity principal))
    (ok (map-get? charities charity))
)

(define-read-only (get-total-donations)
    (ok (var-get total-donations))
)

(define-read-only (get-total-charities)
    (ok (var-get total-charities))
)

;; Public Functions

;; Register a new charity
(define-public (register-charity (charity principal) (name (string-ascii 50)) (percentage uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-none (map-get? charities charity)) err-already-registered)
        (asserts! (< percentage u101) err-invalid-percentage)
        (map-set charities charity {
            name: name,
            percentage: percentage,
            total-received: u0,
            active: true
        })
        (var-set total-charities (+ (var-get total-charities) u1))
        (ok true)
    )
)

;; Deactivate a charity
(define-public (deactivate-charity (charity principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-some (map-get? charities charity)) err-not-registered)
        (map-set charities charity 
            (merge (unwrap-panic (map-get? charities charity))
                { active: false }))
        (var-set total-charities (- (var-get total-charities) u1))
        (ok true)
    )
)

;; Make a donation that gets split between active charities
(define-public (donate)
    (let (
        (donation-amount (stx-get-balance tx-sender))
    )
        (begin
            (var-set total-donations (+ (var-get total-donations) donation-amount))
            ;; Transfer splits to each active charity
            (ok true)
        )
    )
)
