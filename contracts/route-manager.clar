;; Route Manager Smart Contract
;; Manages transport routes and pricing
;; Written by chongyalwatal

;; Error codes
(define-constant ERR_ROUTE_NOT_FOUND (err u2002))
(define-constant ERR_UNAUTHORIZED (err u2003))

;; Constants
(define-constant CONTRACT_OWNER tx-sender)

;; Data structures
(define-map routes uint {
    name: (string-ascii 64),
    price: uint,
    is-active: bool,
    operator: principal
})

;; Data variables
(define-data-var next-route-id uint u1)
(define-data-var total-routes uint u0)

;; Read-only functions
(define-read-only (get-route-info (route-id uint))
    (map-get? routes route-id)
)

(define-read-only (get-total-routes)
    (var-get total-routes)
)

;; Public functions
(define-public (create-route (name (string-ascii 64)) (price uint) (operator principal))
    (let (
        (route-id (var-get next-route-id))
    )
        (asserts! (> (len name) u0) ERR_UNAUTHORIZED)
        (asserts! (> price u0) ERR_UNAUTHORIZED)
        
        (map-set routes route-id {
            name: name,
            price: price,
            is-active: true,
            operator: operator
        })
        
        (var-set next-route-id (+ route-id u1))
        (var-set total-routes (+ (var-get total-routes) u1))
        
        (ok route-id)
    )
)

(define-public (update-route-price (route-id uint) (new-price uint))
    (let (
        (route-info (unwrap! (map-get? routes route-id) ERR_ROUTE_NOT_FOUND))
    )
        (asserts! (> new-price u0) ERR_UNAUTHORIZED)
        
        (map-set routes route-id 
            (merge route-info {price: new-price})
        )
        
        (ok true)
    )
)
