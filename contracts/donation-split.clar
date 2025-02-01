;; Donation Splitter Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-invalid-percentage (err u103))
(define-constant err-invalid-threshold (err u104))

;; Data Variables
(define-data-var total-donations uint u0)
(define-data-var total-charities uint u0)
(define-data-var donation-threshold uint u1000000) ;; 1 STX minimum for rewards

;; Data Maps
(define-map charities principal {
    name: (string-ascii 50),
    percentage: uint,
    total-received: uint,
    total-donors: uint,
    active: bool
})

(define-map donor-stats principal {
    total-donated: uint,
    donation-count: uint,
    rewards-earned: uint
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

(define-read-only (get-donor-stats (donor principal))
    (ok (default-to 
        {total-donated: u0, donation-count: u0, rewards-earned: u0}
        (map-get? donor-stats donor)))
)

;; Private Functions
(define-private (calculate-reward (amount uint))
    (/ amount u100) ;; 1% reward rate
)

(define-private (update-donor-stats (donor principal) (amount uint))
    (let ((current-stats (default-to 
            {total-donated: u0, donation-count: u0, rewards-earned: u0}
            (map-get? donor-stats donor)))
          (reward (if (>= amount (var-get donation-threshold))
                    (calculate-reward amount)
                    u0)))
        (map-set donor-stats donor
            {
                total-donated: (+ (get total-donated current-stats) amount),
                donation-count: (+ (get donation-count current-stats) u1),
                rewards-earned: (+ (get rewards-earned current-stats) reward)
            }))
    )
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
            total-donors: u0,
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

;; Set minimum donation threshold for rewards
(define-public (set-donation-threshold (new-threshold uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only) 
        (var-set donation-threshold new-threshold)
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
            (update-donor-stats tx-sender donation-amount)
            ;; Transfer splits to each active charity and track metrics
            (ok true)
        )
    )
)
