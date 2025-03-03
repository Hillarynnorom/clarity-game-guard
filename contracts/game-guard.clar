;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-member (err u101))
(define-constant err-invalid-role (err u102))
(define-constant err-already-member (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-invalid-params (err u105))
(define-constant err-cannot-revoke-owner (err u106))

;; Data vars
(define-data-var contract-paused bool false)

;; Enhanced event tracking
(define-map role-change-events
  uint
  {
    member: principal,
    old-role: (string-ascii 20),
    new-role: (string-ascii 20),
    changed-by: principal,
    block: uint
  }
)
(define-data-var event-nonce uint u0)

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

;; Enhanced role management
(define-public (revoke-role (member principal))
  (let (
    (sender tx-sender)
    (member-data (unwrap-panic (get-member-data member)))
  )
    (asserts! (not (var-get contract-paused)) err-unauthorized)
    (asserts! (can-manage-roles sender) err-invalid-role)
    (asserts! (not (is-eq member contract-owner)) err-cannot-revoke-owner)
    (begin
      (track-role-change member (get role member-data) "member" sender)
      (ok (map-set members
        member
        (merge member-data
          { role: "member" })
      ))
    )
  )
)

;; Event tracking
(define-private (track-role-change (member principal) (old-role (string-ascii 20)) (new-role (string-ascii 20)) (changed-by principal))
  (let ((current-nonce (var-get event-nonce)))
    (begin
      (map-set role-change-events
        current-nonce
        {
          member: member,
          old-role: old-role,
          new-role: new-role,
          changed-by: changed-by,
          block: block-height
        }
      )
      (var-set event-nonce (+ current-nonce u1))
      true
    )
  )
)

;; Existing functions with enhanced event tracking
(define-public (assign-role (member principal) (new-role (string-ascii 20)))
  (let (
    (sender tx-sender)
    (member-data (unwrap-panic (get-member-data member)))
  )
    (asserts! (not (var-get contract-paused)) err-unauthorized)
    (asserts! (can-manage-roles sender) err-invalid-role)
    (asserts! (is-some (map-get? community-roles new-role)) err-invalid-params)
    (begin
      (track-role-change member (get role member-data) new-role sender)
      (ok (map-set members
        member
        (merge member-data
          { role: new-role })
      ))
    )
  )
)

;; [Rest of the original contract code remains unchanged]
