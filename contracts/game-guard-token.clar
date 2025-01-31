(define-fungible-token guard-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))

(define-public (mint (amount uint) (recipient principal))
  (if (is-eq tx-sender contract-owner)
    (ft-mint? guard-token amount recipient)
    err-owner-only
  )
)

(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (ft-transfer? guard-token amount sender recipient)
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance guard-token account))
)
