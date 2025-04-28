;; Harmony Circle Contract
;; ===================================
;; Storage & Persistence Layer
;; ===================================

;; Core user record storage
(define-map participant-records
  { participant-id: uint }
  {
    display-name: (string-ascii 50),
    account-address: principal,
    enrollment-date: uint,
    personal-statement: (string-ascii 160),
    interest-tags: (list 5 (string-ascii 30))
  }
)

;; Access control management system
(define-map access-control-settings
  { participant-id: uint, observer-address: principal }
  { access-allowed: bool }
)

;; User engagement analytics
(define-map participant-engagement-metrics
  { participant-id: uint }
  {
    latest-session: uint,
    session-count: uint,
    recent-operation: (string-ascii 50)
  }
)

;; ===================================
;; System Constants
;; ===================================

;; System response codes
(define-constant ERR-ACCESS-DENIED (err u500))
(define-constant ERR-RECORD-MISSING (err u501))
(define-constant ERR-ALREADY-REGISTERED (err u502))
(define-constant ERR-DATA-CONSTRAINT-VIOLATION (err u503))
(define-constant ERR-PERMISSION-REQUIRED (err u504))

;; Administrative settings
(define-constant PLATFORM-ADMINISTRATOR tx-sender)

;; ===================================
;; State Management
;; ===================================

;; Global participant counter
(define-data-var participant-total uint u0)

;; ===================================
;; Internal Utility Functions
;; ===================================

;; Participant existence verification
(define-private (participant-registered? (participant-id uint))
  (is-some (map-get? participant-records { participant-id: participant-id }))
)

;; Ownership validation system
(define-private (is-record-owner? (participant-id uint) (address principal))
  (match (map-get? participant-records { participant-id: participant-id })
    record-data (is-eq (get account-address record-data) address)
    false
  )
)

;; Interest tag validator - single tag
(define-private (validate-single-tag (tag (string-ascii 30)))
  (and
    (> (len tag) u0)
    (< (len tag) u31)
  )
)

;; Interest tags collection validator
(define-private (validate-tag-collection (tags (list 5 (string-ascii 30))))
  (and
    (> (len tags) u0)
    (<= (len tags) u5)
    (is-eq (len (filter validate-single-tag tags)) (len tags))
  )
)

;; ===================================
;; Public Interface Functions
;; ===================================

;; Create new participant profile
(define-public (create-participant-profile 
    (display-name (string-ascii 50)) 
    (personal-statement (string-ascii 160)) 
    (interest-tags (list 5 (string-ascii 30))))
  (let
    (
      (assigned-id (+ (var-get participant-total) u1))
    )
    ;; Input data validation
    (asserts! (and (> (len display-name) u0) (< (len display-name) u51)) ERR-DATA-CONSTRAINT-VIOLATION)
    (asserts! (and (> (len personal-statement) u0) (< (len personal-statement) u161)) ERR-DATA-CONSTRAINT-VIOLATION)
    (asserts! (validate-tag-collection interest-tags) ERR-DATA-CONSTRAINT-VIOLATION)

    ;; Establish participant record
    (map-insert participant-records
      { participant-id: assigned-id }
      {
        display-name: display-name,
        account-address: tx-sender,
        enrollment-date: block-height,
        personal-statement: personal-statement,
        interest-tags: interest-tags
      }
    )

    ;; Initialize access permissions
    (map-insert access-control-settings
      { participant-id: assigned-id, observer-address: tx-sender }
      { access-allowed: true }
    )

    ;; Update global counter
    (var-set participant-total assigned-id)
    (ok assigned-id)
  )
)

;; Modify participant interest tags
(define-public (modify-participant-interests (participant-id uint) (updated-tags (list 5 (string-ascii 30))))
  (let
    (
      (participant-data (unwrap! (map-get? participant-records { participant-id: participant-id }) ERR-RECORD-MISSING))
    )
    ;; System validation checks
    (asserts! (participant-registered? participant-id) ERR-RECORD-MISSING)
    (asserts! (is-eq (get account-address participant-data) tx-sender) ERR-PERMISSION-REQUIRED)
    (asserts! (validate-tag-collection updated-tags) ERR-DATA-CONSTRAINT-VIOLATION)

    ;; Update interest tags
    (map-set participant-records
      { participant-id: participant-id }
      (merge participant-data { interest-tags: updated-tags })
    )
    (ok true)
  )
)

;; Alternative enrollment function
(define-public (enroll-new-participant 
    (display-name (string-ascii 50)) 
    (personal-statement (string-ascii 160)) 
    (interest-tags (list 5 (string-ascii 30))))
  (let
    (
      (assigned-id (+ (var-get participant-total) u1))
    )
    ;; Input validation suite
    (asserts! (and (> (len display-name) u0) (< (len display-name) u51)) ERR-DATA-CONSTRAINT-VIOLATION)
    (asserts! (and (> (len personal-statement) u0) (< (len personal-statement) u161)) ERR-DATA-CONSTRAINT-VIOLATION)
    (asserts! (validate-tag-collection interest-tags) ERR-DATA-CONSTRAINT-VIOLATION)

    ;; Initialize participant profile
    (map-insert participant-records
      { participant-id: assigned-id }
      {
        display-name: display-name,
        account-address: tx-sender,
        enrollment-date: block-height,
        personal-statement: personal-statement,
        interest-tags: interest-tags
      }
    )

    ;; Configure basic permissions
    (map-insert access-control-settings
      { participant-id: assigned-id, observer-address: tx-sender }
      { access-allowed: true }
    )

    ;; Update system counts
    (var-set participant-total assigned-id)
    (ok assigned-id)
  )
)

;; Update participant display identity
(define-public (update-display-identity (participant-id uint) (new-display-name (string-ascii 50)))
  (let
    (
      (participant-data (unwrap! (map-get? participant-records { participant-id: participant-id }) ERR-RECORD-MISSING))
    )
    ;; Security validation
    (asserts! (participant-registered? participant-id) ERR-RECORD-MISSING)
    (asserts! (is-eq (get account-address participant-data) tx-sender) ERR-PERMISSION-REQUIRED)

    ;; Update display name
    (map-set participant-records
      { participant-id: participant-id }
      (merge participant-data { display-name: new-display-name })
    )
    (ok true)
  )
)

;; ===================================
;; Enhanced System Operations
;; ===================================

;; Optimized interest tag update function
(define-public (streamlined-interest-update (participant-id uint) (updated-tags (list 5 (string-ascii 30))))
  (begin
    (asserts! (participant-registered? participant-id) ERR-RECORD-MISSING)
    (asserts! (validate-tag-collection updated-tags) ERR-DATA-CONSTRAINT-VIOLATION)
    (map-set participant-records
      { participant-id: participant-id }
      (merge (unwrap! (map-get? participant-records { participant-id: participant-id }) ERR-RECORD-MISSING) 
             { interest-tags: updated-tags })
    )
    (ok "Interest tags have been updated")
  )
)

;; Access restriction enforcement
(define-public (enforce-access-restrictions (participant-id uint) (address principal))
  (let
    (
      (participant-data (unwrap! (map-get? participant-records { participant-id: participant-id }) ERR-RECORD-MISSING))
    )
    ;; Validate access permissions
    (asserts! (is-eq (get account-address participant-data) address) ERR-PERMISSION-REQUIRED)
    (ok true)
  )
)

;; Comprehensive profile update with enhanced validation
(define-public (comprehensive-profile-update (participant-id uint) 
                                            (new-display-name (string-ascii 50)) 
                                            (new-statement (string-ascii 160)) 
                                            (new-interests (list 5 (string-ascii 30))))
  (let
    (
      (participant-data (unwrap! (map-get? participant-records { participant-id: participant-id }) ERR-RECORD-MISSING))
    )
    ;; Multi-faceted validation
    (asserts! (participant-registered? participant-id) ERR-RECORD-MISSING)
    (asserts! (is-eq (get account-address participant-data) tx-sender) ERR-PERMISSION-REQUIRED)
    (asserts! (> (len new-display-name) u0) ERR-DATA-CONSTRAINT-VIOLATION)
    (asserts! (< (len new-display-name) u51) ERR-DATA-CONSTRAINT-VIOLATION)
    (asserts! (validate-tag-collection new-interests) ERR-DATA-CONSTRAINT-VIOLATION)

    ;; Complete profile update
    (map-set participant-records
      { participant-id: participant-id }
      (merge participant-data { 
        display-name: new-display-name, 
        personal-statement: new-statement, 
        interest-tags: new-interests 
      })
    )
    (ok true)
  )
)

;; Ownership verification system
(define-public (verify-account-ownership (participant-id uint) (claim-address principal))
  (let
    (
      (participant-data (unwrap! (map-get? participant-records { participant-id: participant-id }) ERR-RECORD-MISSING))
    )
    (ok (is-eq claim-address (get account-address participant-data)))
  )
)

;; Record platform engagement event
(define-public (log-platform-engagement (participant-id uint))
  (let
    (
      (current-metrics (default-to 
        { latest-session: u0, session-count: u0, recent-operation: "None" }
        (map-get? participant-engagement-metrics { participant-id: participant-id })))
    )
    (asserts! (participant-registered? participant-id) ERR-RECORD-MISSING)
    (map-set participant-engagement-metrics
      { participant-id: participant-id }
      {
        latest-session: block-height,
        session-count: (+ (get session-count current-metrics) u1),
        recent-operation: "platform-access"
      }
    )
    (ok true)
  )
)

