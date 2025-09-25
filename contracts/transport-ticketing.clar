;; Transport Ticketing Smart Contract
;; A comprehensive blockchain-based public transport ticketing system
;; Handles ticket purchases, validation, transfers, and user balance management
;; Written by chongyalwatal

;; Error codes
(define-constant ERR_INSUFFICIENT_FUNDS (err u1001))
(define-constant ERR_TICKET_NOT_FOUND (err u1002))
(define-constant ERR_TICKET_ALREADY_USED (err u1003))
(define-constant ERR_UNAUTHORIZED (err u1004))
(define-constant ERR_INVALID_AMOUNT (err u1005))
(define-constant ERR_ROUTE_NOT_FOUND (err u1006))
(define-constant ERR_INVALID_ROUTE (err u1007))
(define-constant ERR_TRANSFER_FAILED (err u1008))
(define-constant ERR_BALANCE_OVERFLOW (err u1009))
(define-constant ERR_INVALID_TICKET_ID (err u1010))

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant MAX_TICKET_PRICE u10000000) ;; 10 STX in microSTX
(define-constant MIN_TICKET_PRICE u100000) ;; 0.1 STX in microSTX
(define-constant TICKET_VALIDITY_BLOCKS u144) ;; ~24 hours in blocks
(define-constant MAX_BALANCE u100000000) ;; 100 STX max balance

;; Data structures
(define-map user-balances principal uint)
(define-map user-ticket-counts principal uint)
(define-map ticket-registry uint {owner: principal, route-id: uint, price: uint, purchased-at: uint, used-at: (optional uint), is-active: bool})
(define-map route-prices uint uint)
(define-map route-operators uint principal)
(define-map user-tickets {user: principal, ticket-id: uint} bool)

;; Data variables
(define-data-var next-ticket-id uint u1)
(define-data-var total-tickets-sold uint u0)
(define-data-var total-revenue uint u0)
(define-data-var platform-fee-rate uint u250) ;; 2.5% in basis points

;; Private functions
(define-private (is-route-operator (route-id uint) (user principal))
    (is-eq user (default-to CONTRACT_OWNER (map-get? route-operators route-id)))
)

(define-private (calculate-platform-fee (amount uint))
    (/ (* amount (var-get platform-fee-rate)) u10000)
)

(define-private (is-ticket-expired (ticket-id uint))
    (match (map-get? ticket-registry ticket-id)
        ticket-info
        (let ((blocks-passed (- stacks-block-height (get purchased-at ticket-info))))
            (>= blocks-passed TICKET_VALIDITY_BLOCKS)
        )
        true
    )
)

(define-private (validate-ticket-price (price uint))
    (and (>= price MIN_TICKET_PRICE) (<= price MAX_TICKET_PRICE))
)

;; Read-only functions
(define-read-only (get-user-balance (user principal))
    (default-to u0 (map-get? user-balances user))
)

(define-read-only (get-ticket-info (ticket-id uint))
    (map-get? ticket-registry ticket-id)
)

(define-read-only (get-route-price (route-id uint))
    (map-get? route-prices route-id)
)

(define-read-only (get-user-ticket-count (user principal))
    (default-to u0 (map-get? user-ticket-counts user))
)

(define-read-only (get-total-tickets-sold)
    (var-get total-tickets-sold)
)

(define-read-only (get-total-revenue)
    (var-get total-revenue)
)

(define-read-only (get-platform-fee-rate)
    (var-get platform-fee-rate)
)

(define-read-only (has-valid-ticket (user principal) (route-id uint))
    (let ((ticket-count (get-user-ticket-count user)))
        (if (> ticket-count u0)
            (get found (fold check-user-tickets (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) {user: user, route-id: route-id, found: false}))
            false
        )
    )
)

(define-private (check-user-tickets (ticket-offset uint) (state {user: principal, route-id: uint, found: bool}))
    (if (get found state)
        state
        (let ((current-ticket-id (- (var-get next-ticket-id) ticket-offset)))
            (match (map-get? ticket-registry current-ticket-id)
                ticket-info
                (if (and 
                        (is-eq (get owner ticket-info) (get user state))
                        (is-eq (get route-id ticket-info) (get route-id state))
                        (get is-active ticket-info)
                        (is-none (get used-at ticket-info))
                        (not (is-ticket-expired current-ticket-id))
                    )
                    {user: (get user state), route-id: (get route-id state), found: true}
                    state
                )
                state
            )
        )
    )
)

;; Public functions
(define-public (add-balance (amount uint))
    (let (
        (sender tx-sender)
        (current-balance (get-user-balance sender))
        (new-balance (+ current-balance amount))
    )
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (<= new-balance MAX_BALANCE) ERR_BALANCE_OVERFLOW)
        (try! (stx-transfer? amount sender (as-contract tx-sender)))
        (map-set user-balances sender new-balance)
        (ok new-balance)
    )
)

(define-public (buy-ticket (route-id uint))
    (let (
        (sender tx-sender)
        (ticket-price (unwrap! (get-route-price route-id) ERR_ROUTE_NOT_FOUND))
        (user-balance (get-user-balance sender))
        (ticket-id (var-get next-ticket-id))
        (platform-fee (calculate-platform-fee ticket-price))
        (net-price (- ticket-price platform-fee))
        (current-ticket-count (get-user-ticket-count sender))
    )
        (asserts! (validate-ticket-price ticket-price) ERR_INVALID_AMOUNT)
        (asserts! (>= user-balance ticket-price) ERR_INSUFFICIENT_FUNDS)
        
        ;; Deduct balance
        (map-set user-balances sender (- user-balance ticket-price))
        
        ;; Create ticket
        (map-set ticket-registry ticket-id {
            owner: sender,
            route-id: route-id,
            price: ticket-price,
            purchased-at: stacks-block-height,
            used-at: none,
            is-active: true
        })
        
        ;; Update counters and mappings
        (map-set user-tickets {user: sender, ticket-id: ticket-id} true)
        (map-set user-ticket-counts sender (+ current-ticket-count u1))
        (var-set next-ticket-id (+ ticket-id u1))
        (var-set total-tickets-sold (+ (var-get total-tickets-sold) u1))
        (var-set total-revenue (+ (var-get total-revenue) net-price))
        
        ;; Transfer platform fee to contract owner
        (and (> platform-fee u0)
             (try! (as-contract (stx-transfer? platform-fee tx-sender CONTRACT_OWNER)))
        )
        
        (ok ticket-id)
    )
)

(define-public (use-ticket (ticket-id uint))
    (let (
        (sender tx-sender)
        (ticket-info (unwrap! (get-ticket-info ticket-id) ERR_TICKET_NOT_FOUND))
    )
        (asserts! (is-eq (get owner ticket-info) sender) ERR_UNAUTHORIZED)
        (asserts! (get is-active ticket-info) ERR_TICKET_ALREADY_USED)
        (asserts! (is-none (get used-at ticket-info)) ERR_TICKET_ALREADY_USED)
        (asserts! (not (is-ticket-expired ticket-id)) ERR_TICKET_NOT_FOUND)
        
        ;; Mark ticket as used
        (map-set ticket-registry ticket-id 
            (merge ticket-info {used-at: (some stacks-block-height), is-active: false})
        )
        
        (ok true)
    )
)

(define-public (transfer-ticket (ticket-id uint) (recipient principal))
    (let (
        (sender tx-sender)
        (ticket-info (unwrap! (get-ticket-info ticket-id) ERR_TICKET_NOT_FOUND))
        (sender-ticket-count (get-user-ticket-count sender))
        (recipient-ticket-count (get-user-ticket-count recipient))
    )
        (asserts! (is-eq (get owner ticket-info) sender) ERR_UNAUTHORIZED)
        (asserts! (get is-active ticket-info) ERR_TICKET_ALREADY_USED)
        (asserts! (is-none (get used-at ticket-info)) ERR_TICKET_ALREADY_USED)
        (asserts! (not (is-ticket-expired ticket-id)) ERR_TICKET_NOT_FOUND)
        (asserts! (not (is-eq sender recipient)) ERR_TRANSFER_FAILED)
        
        ;; Update ticket ownership
        (map-set ticket-registry ticket-id 
            (merge ticket-info {owner: recipient})
        )
        
        ;; Update user mappings
        (map-delete user-tickets {user: sender, ticket-id: ticket-id})
        (map-set user-tickets {user: recipient, ticket-id: ticket-id} true)
        
        ;; Update ticket counts
        (map-set user-ticket-counts sender (- sender-ticket-count u1))
        (map-set user-ticket-counts recipient (+ recipient-ticket-count u1))
        
        (ok true)
    )
)

(define-public (set-route-price (route-id uint) (price uint))
    (begin
        (asserts! (or (is-eq tx-sender CONTRACT_OWNER) (is-route-operator route-id tx-sender)) ERR_UNAUTHORIZED)
        (asserts! (validate-ticket-price price) ERR_INVALID_AMOUNT)
        (map-set route-prices route-id price)
        (ok true)
    )
)

(define-public (set-route-operator (route-id uint) (operator principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (map-set route-operators route-id operator)
        (ok true)
    )
)

(define-public (withdraw-balance (amount uint))
    (let (
        (sender tx-sender)
        (current-balance (get-user-balance sender))
    )
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (>= current-balance amount) ERR_INSUFFICIENT_FUNDS)
        
        (map-set user-balances sender (- current-balance amount))
        (try! (as-contract (stx-transfer? amount tx-sender sender)))
        (ok (- current-balance amount))
    )
)

(define-public (refund-unused-ticket (ticket-id uint))
    (let (
        (sender tx-sender)
        (ticket-info (unwrap! (get-ticket-info ticket-id) ERR_TICKET_NOT_FOUND))
        (current-balance (get-user-balance sender))
        (refund-amount (get price ticket-info))
        (current-ticket-count (get-user-ticket-count sender))
    )
        (asserts! (is-eq (get owner ticket-info) sender) ERR_UNAUTHORIZED)
        (asserts! (get is-active ticket-info) ERR_TICKET_ALREADY_USED)
        (asserts! (is-none (get used-at ticket-info)) ERR_TICKET_ALREADY_USED)
        
        ;; Deactivate ticket
        (map-set ticket-registry ticket-id 
            (merge ticket-info {is-active: false})
        )
        
        ;; Refund 90% of ticket price (10% processing fee)
        (let ((refund (/ (* refund-amount u9) u10)))
            (map-set user-balances sender (+ current-balance refund))
            (map-set user-ticket-counts sender (- current-ticket-count u1))
            (map-delete user-tickets {user: sender, ticket-id: ticket-id})
            (ok refund)
        )
    )
)
