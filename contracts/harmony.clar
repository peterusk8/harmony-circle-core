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
