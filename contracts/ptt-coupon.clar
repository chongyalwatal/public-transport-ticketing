;; ptt-coupon.clar
;; Clarity v3, independent feature: self-issuance and redemption of a one-time coupon per user.

;; Error constants
(define-constant ERR-ALREADY-HAS (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-USED (err u102))

;; Storage: map tracks per-user coupon
(define-map user-coupons
  { user: principal }
  {
    issued-at: uint,
    used: bool,
  }
)

;; Read-only: get a user's coupon (if any)
(define-read-only (get-coupon (user principal))
  (match (map-get? user-coupons { user: user })
    entry (ok entry)
    ERR-NOT-FOUND
  )
)

;; Public: issue a coupon for tx-sender; fails if already issued
(define-public (issue-coupon)
  (if (is-some (map-get? user-coupons { user: tx-sender }))
    ERR-ALREADY-HAS
    (begin
      (map-set user-coupons { user: tx-sender } {
        issued-at: block-height,
        used: false,
      })
      (ok true)
    )
  )
)

;; Public: redeem a coupon for tx-sender; fails if not found or already used
(define-public (redeem-coupon)
  (match (map-get? user-coupons { user: tx-sender })
    entry (if (get used entry)
      ERR-ALREADY-USED
      (begin
        (map-set user-coupons { user: tx-sender } {
          issued-at: (get issued-at entry),
          used: true,
        })
        (ok true)
      )
    )
    ERR-NOT-FOUND
  )
)

(define-data-var coupon-admin principal tx-sender)

(define-map coupon-policy
  { id: uint }
  {
    expires-at: (optional uint),
    max-uses: (optional uint),
    used: uint,
  }
)

(define-public (set-coupon-admin (new principal))
  (begin
    (asserts! (is-eq tx-sender (var-get coupon-admin)) (err u103))
    (var-set coupon-admin new)
    (ok true)
  )
)

(define-read-only (get-coupon-admin)
  (var-get coupon-admin)
)

(define-read-only (get-coupon-policy (id uint))
  (default-to {
    expires-at: none,
    max-uses: none,
    used: u0,
  }
    (map-get? coupon-policy { id: id })
  )
)

(define-read-only (is-coupon-valid (id uint))
  (let ((p (default-to {
      expires-at: none,
      max-uses: none,
      used: u0,
    }
      (map-get? coupon-policy { id: id })
    )))
    (and
      (match (get expires-at p)
        exp (<= block-height exp)
        true
      )
      (match (get max-uses p)
        m (> m (get used p))
        true
      )
    )
  )
)

(define-public (set-coupon-policy
    (id uint)
    (expires-at (optional uint))
    (max-uses (optional uint))
  )
  (begin
    (asserts! (is-eq tx-sender (var-get coupon-admin)) (err u103))
    (let ((prev (default-to {
        expires-at: none,
        max-uses: none,
        used: u0,
      }
        (map-get? coupon-policy { id: id })
      )))
      (map-set coupon-policy { id: id } {
        expires-at: expires-at,
        max-uses: max-uses,
        used: (get used prev),
      })
    )
    (ok true)
  )
)

(define-public (use-coupon (id uint))
  (let ((p (default-to {
      expires-at: none,
      max-uses: none,
      used: u0,
    }
      (map-get? coupon-policy { id: id })
    )))
    (begin
      (asserts!
        (match (get expires-at p)
          exp (<= block-height exp)
          true
        )
        (err u104)
      )
      (asserts!
        (match (get max-uses p)
          m (> m (get used p))
          true
        )
        (err u105)
      )
      (map-set coupon-policy { id: id } {
        expires-at: (get expires-at p),
        max-uses: (get max-uses p),
        used: (+ u1 (get used p)),
      })
      (ok true)
    )
  )
)
