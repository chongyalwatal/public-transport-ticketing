;; ptt-coupon.clar
;; Clarity v3, independent feature: self-issuance and redemption of a one-time coupon per user.

;; Error constants
(define-constant ERR-ALREADY-HAS (err u100))
(define-constant ERR-NOT-FOUND   (err u101))
(define-constant ERR-ALREADY-USED (err u102))

;; Storage: map tracks per-user coupon
(define-map user-coupons
  { user: principal }
  { issued-at: uint, used: bool })

;; Read-only: get a user's coupon (if any)
(define-read-only (get-coupon (user principal))
  (match (map-get? user-coupons { user: user })
    entry (ok entry)
    ERR-NOT-FOUND))

;; Public: issue a coupon for tx-sender; fails if already issued
(define-public (issue-coupon)
  (if (is-some (map-get? user-coupons { user: tx-sender }))
      ERR-ALREADY-HAS
      (begin
        (map-set user-coupons { user: tx-sender } { issued-at: block-height, used: false })
        (ok true))))

;; Public: redeem a coupon for tx-sender; fails if not found or already used
(define-public (redeem-coupon)
  (match (map-get? user-coupons { user: tx-sender })
    entry
      (if (get used entry)
          ERR-ALREADY-USED
          (begin
            (map-set user-coupons { user: tx-sender } { issued-at: (get issued-at entry), used: true })
            (ok true)))
    ERR-NOT-FOUND))
