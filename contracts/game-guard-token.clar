;; Enhanced token contract with reputation integration
(define-fungible-token guard-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-amount (err u101))

;; Reputation-based reward distribution
(define-public (distribute-rewards (recipient principal) (base-amount uint))
  (let (
    (member-data (contract-call? .game-guard get-member-data recipient))
    (reputation (get reputation (unwrap! member-data err-invalid-amount)))
    (bonus-amount (/ (* base-amount reputation) u100))
    (total-amount (+ base-amount bonus-amount))
  )
    (if (is-eq tx-sender contract-owner)
      (ft-mint? guard-token total-amount recipient)
      err-owner-only
    )
  )
)

;; [Rest of the original token contract code remains unchanged]
