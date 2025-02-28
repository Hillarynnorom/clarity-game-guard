;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-member (err u101))
(define-constant err-invalid-role (err u102))
(define-constant err-already-member (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-invalid-params (err u105))

;; Data vars
(define-data-var contract-paused bool false)

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
    can-moderate: bool,
    can-manage-roles: bool
  }
)

;; Initialize default roles
(define-private (initialize-roles)
  (begin
    (map-set community-roles "admin"
      {
        can-invite: true,
        can-verify: true, 
        can-moderate: true,
        can-manage-roles: true
      }
    )
    (map-set community-roles "moderator"
      {
        can-invite: true,
        can-verify: true,
        can-moderate: true,
        can-manage-roles: false
      }
    )
    (map-set community-roles "member"
      {
        can-invite: false,
        can-verify: false,
        can-moderate: false,
        can-manage-roles: false
      }
    )
    (map-set members contract-owner
      {
        role: "admin",
        reputation: u100,
        join-height: block-height,
        verified: true
      }
    )
  )
)

;; New role management functions
(define-public (create-role (role-name (string-ascii 20)) (permissions {can-invite: bool, can-verify: bool, can-moderate: bool, can-manage-roles: bool}))
  (let ((sender tx-sender))
    (asserts! (not (var-get contract-paused)) err-unauthorized)
    (asserts! (can-manage-roles sender) err-invalid-role)
    (ok (map-set community-roles role-name permissions))
  )
)

(define-public (assign-role (member principal) (new-role (string-ascii 20)))
  (let ((sender tx-sender)
        (member-data (unwrap-panic (get-member-data member))))
    (asserts! (not (var-get contract-paused)) err-unauthorized)
    (asserts! (can-manage-roles sender) err-invalid-role)
    (asserts! (is-some (map-get? community-roles new-role)) err-invalid-params)
    (ok (map-set members
      member
      (merge member-data
        { role: new-role })
    ))
  )
)

;; Emergency pause
(define-public (set-pause-state (new-state bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (var-set contract-paused new-state))
  )
)

;; Enhanced public functions
(define-public (join-community)
  (let ((sender tx-sender))
    (asserts! (not (var-get contract-paused)) err-unauthorized)
    (if (is-some (get-member-data sender))
      err-already-member
      (begin
        (print {event: "member-joined", member: sender})
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
)

(define-public (verify-member (member principal))
  (let ((sender tx-sender))
    (asserts! (not (var-get contract-paused)) err-unauthorized)
    (asserts! (can-verify sender) err-invalid-role)
    (begin
      (print {event: "member-verified", member: member, verifier: sender})
      (ok (map-set members
        member
        (merge (unwrap-panic (get-member-data member))
          { verified: true })
      ))
    )
  )
)

(define-public (add-reputation (member principal) (points uint))
  (let ((sender tx-sender)
        (member-data (unwrap-panic (get-member-data member))))
    (asserts! (not (var-get contract-paused)) err-unauthorized)
    (asserts! (can-moderate sender) err-invalid-role)
    (begin
      (print {event: "reputation-added", member: member, points: points, moderator: sender})
      (ok (map-set members
        member
        (merge member-data
          { reputation: (+ (get reputation member-data) points) })
      ))
    )
  )
)

;; Enhanced read only functions 
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

(define-read-only (can-manage-roles (member principal))
  (let ((role-data (unwrap-panic (get-member-data member))))
    (get can-manage-roles (unwrap-panic (map-get? community-roles (get role role-data))))
  )
)

(initialize-roles)
