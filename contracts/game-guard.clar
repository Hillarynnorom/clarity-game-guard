;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-member (err u101))
(define-constant err-invalid-role (err u102))
(define-constant err-already-member (err u103))

;; Data vars
(define-map members 
  principal 
  {
    role: (string-ascii 20),
    reputation: uint,
    join-height: uint,
    verified: bool
  }
)

(define-map community-roles
  (string-ascii 20)
  {
    can-invite: bool,
    can-verify: bool,
    can-moderate: bool
  }
)

;; Public functions
(define-public (join-community)
  (let ((sender tx-sender))
    (if (is-some (get-member-data sender))
      err-already-member
      (ok (map-set members 
        sender
        {
          role: "member",
          reputation: u0,
          join-height: block-height,
          verified: false
        }
      ))
    )
  )
)

(define-public (verify-member (member principal))
  (let ((sender tx-sender))
    (if (can-verify sender)
      (ok (map-set members
        member
        (merge (unwrap-panic (get-member-data member))
          { verified: true })
      ))
      err-invalid-role
    )
  )
)

(define-public (add-reputation (member principal) (points uint))
  (let ((sender tx-sender)
        (member-data (unwrap-panic (get-member-data member))))
    (if (can-moderate sender)
      (ok (map-set members
        member
        (merge member-data
          { reputation: (+ (get reputation member-data) points) })
      ))
      err-invalid-role
    )
  )
)

;; Read only functions
(define-read-only (get-member-data (member principal))
  (map-get? members member)
)

(define-read-only (can-verify (member principal))
  (let ((role-data (unwrap-panic (get-member-data member))))
    (get can-verify (unwrap-panic (map-get? community-roles (get role role-data))))
  )
)

(define-read-only (can-moderate (member principal))
  (let ((role-data (unwrap-panic (get-member-data member))))
    (get can-moderate (unwrap-panic (map-get? community-roles (get role role-data))))
  )
)
