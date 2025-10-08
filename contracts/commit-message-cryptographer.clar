;; title: commit-message-cryptographer
;; version: 1.0.0
;; summary: Ensures all commit messages are either 'fix' or novels about personal life events
;; description: This contract manages the binary nature of commit message cryptography in the chaos engine

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_MESSAGE_LENGTH (err u101))
(define-constant ERR_MESSAGE_NOT_FOUND (err u102))
(define-constant ERR_INVALID_MESSAGE_TYPE (err u103))
(define-constant MAX_NOVEL_LENGTH u5000)
(define-constant MIN_NOVEL_LENGTH u500)
(define-constant CRYPTIC_MESSAGE u"fix")

;; data vars
(define-data-var total-messages uint u0)
(define-data-var cryptic-count uint u0)
(define-data-var novel-count uint u0)
(define-data-var chaos-entropy-level uint u0)

;; data maps
;; Map to store commit messages with their metadata
(define-map commit-messages
  uint ;; message-id
  {
    message: (string-utf8 5000),
    message-type: (string-ascii 10), ;; "cryptic" or "novel"
    author: principal,
    timestamp: uint,
    chaos-factor: uint,
    archaeological-value: uint
  }
)

;; Map to track user's message patterns
(define-map user-patterns
  principal
  {
    total-messages: uint,
    cryptic-messages: uint,
    novel-messages: uint,
    chaos-score: uint,
    archaeological-reputation: uint
  }
)

;; Map to store message archaeology data
(define-map message-archaeology
  uint ;; message-id
  {
    excavation-depth: uint,
    historical-significance: uint,
    emotional-resonance: uint,
    philosophical-weight: uint
  }
)

;; private functions
(define-private (is-cryptic-message (message (string-utf8 5000)))
  (is-eq message CRYPTIC_MESSAGE)
)

(define-private (is-valid-novel (message (string-utf8 5000)))
  (let ((msg-length (len message)))
    (and (>= msg-length MIN_NOVEL_LENGTH) (<= msg-length MAX_NOVEL_LENGTH))
  )
)

(define-private (calculate-chaos-factor (message-type (string-ascii 10)))
  (if (is-eq message-type "cryptic")
    (+ u10 (mod (var-get total-messages) u50)) ;; Cryptic messages add base chaos
    (+ u25 (mod (var-get total-messages) u100)) ;; Novel messages add more chaos
  )
)

(define-private (calculate-archaeological-value (message (string-utf8 5000)) (message-type (string-ascii 10)))
  (if (is-eq message-type "cryptic")
    u15 ;; Cryptic messages have minimal archaeological value
    (let ((msg-length (len message)))
      (+ u40 (/ msg-length u10)) ;; Novel messages have value based on length
    )
  )
)

(define-private (update-user-pattern (user principal) (message-type (string-ascii 10)))
  (let (
    (current-pattern (default-to 
      {total-messages: u0, cryptic-messages: u0, novel-messages: u0, chaos-score: u0, archaeological-reputation: u0}
      (map-get? user-patterns user)
    ))
  )
    (let (
      (new-total (+ (get total-messages current-pattern) u1))
      (new-cryptic (if (is-eq message-type "cryptic") 
                     (+ (get cryptic-messages current-pattern) u1) 
                     (get cryptic-messages current-pattern)))
      (new-novel (if (is-eq message-type "novel") 
                   (+ (get novel-messages current-pattern) u1) 
                   (get novel-messages current-pattern)))
      (chaos-boost (if (is-eq message-type "cryptic") u5 u15))
      (archaeology-boost (if (is-eq message-type "novel") u20 u2))
    )
      (map-set user-patterns user {
        total-messages: new-total,
        cryptic-messages: new-cryptic,
        novel-messages: new-novel,
        chaos-score: (+ (get chaos-score current-pattern) chaos-boost),
        archaeological-reputation: (+ (get archaeological-reputation current-pattern) archaeology-boost)
      })
    )
  )
)

(define-private (update-global-stats (message-type (string-ascii 10)))
  (begin
    (var-set total-messages (+ (var-get total-messages) u1))
    (if (is-eq message-type "cryptic")
      (var-set cryptic-count (+ (var-get cryptic-count) u1))
      (var-set novel-count (+ (var-get novel-count) u1))
    )
    (var-set chaos-entropy-level (+ (var-get chaos-entropy-level) 
                                   (calculate-chaos-factor message-type)))
  )
)

;; public functions
(define-public (submit-commit-message (message (string-utf8 5000)))
  (let (
    (message-id (+ (var-get total-messages) u1))
    (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
  )
    (if (is-cryptic-message message)
      (begin
        (let (
          (chaos-factor (calculate-chaos-factor "cryptic"))
          (arch-value (calculate-archaeological-value message "cryptic"))
        )
          (map-set commit-messages message-id {
            message: message,
            message-type: "cryptic",
            author: tx-sender,
            timestamp: current-time,
            chaos-factor: chaos-factor,
            archaeological-value: arch-value
          })
          (map-set message-archaeology message-id {
            excavation-depth: u1,
            historical-significance: u5,
            emotional-resonance: u2,
            philosophical-weight: u10
          })
          (update-user-pattern tx-sender "cryptic")
          (update-global-stats "cryptic")
          (ok message-id)
        )
      )
      (if (is-valid-novel message)
        (begin
          (let (
            (chaos-factor (calculate-chaos-factor "novel"))
            (arch-value (calculate-archaeological-value message "novel"))
          )
            (map-set commit-messages message-id {
              message: message,
              message-type: "novel",
              author: tx-sender,
              timestamp: current-time,
              chaos-factor: chaos-factor,
              archaeological-value: arch-value
            })
            (map-set message-archaeology message-id {
              excavation-depth: u5,
              historical-significance: (+ u20 (/ (len message) u50)),
              emotional-resonance: (+ u15 (mod (len message) u30)),
              philosophical-weight: (+ u25 (/ (len message) u100))
            })
            (update-user-pattern tx-sender "novel")
            (update-global-stats "novel")
            (ok message-id)
          )
        )
        (err ERR_INVALID_MESSAGE_LENGTH)
      )
    )
  )
)

(define-public (excavate-message-history (message-id uint))
  (let (
    (message-data (map-get? commit-messages message-id))
  )
    (match message-data
      msg (let (
            (current-arch (default-to 
              {excavation-depth: u0, historical-significance: u0, emotional-resonance: u0, philosophical-weight: u0}
              (map-get? message-archaeology message-id)
            ))
          )
            (map-set message-archaeology message-id {
              excavation-depth: (+ (get excavation-depth current-arch) u1),
              historical-significance: (get historical-significance current-arch),
              emotional-resonance: (get emotional-resonance current-arch),
              philosophical-weight: (get philosophical-weight current-arch)
            })
            (ok true)
          )
      (err ERR_MESSAGE_NOT_FOUND)
    )
  )
)

;; read only functions
(define-read-only (get-commit-message (message-id uint))
  (map-get? commit-messages message-id)
)

(define-read-only (get-message-archaeology (message-id uint))
  (map-get? message-archaeology message-id)
)

(define-read-only (get-user-pattern (user principal))
  (map-get? user-patterns user)
)

(define-read-only (get-global-statistics)
  {
    total-messages: (var-get total-messages),
    cryptic-count: (var-get cryptic-count),
    novel-count: (var-get novel-count),
    chaos-entropy-level: (var-get chaos-entropy-level)
  }
)

(define-read-only (calculate-chaos-entropy)
  (let (
    (total (var-get total-messages))
    (cryptic (var-get cryptic-count))
    (novel (var-get novel-count))
  )
    (if (> total u0)
      (/ (* (+ cryptic (* novel u3)) u100) total) ;; Novel messages weighted more heavily
      u0
    )
  )
)

(define-read-only (get-archaeological-value-by-user (user principal))
  (let (
    (pattern (map-get? user-patterns user))
  )
    (match pattern
      user-data (get archaeological-reputation user-data)
      u0
    )
  )
)

(define-read-only (is-chaos-archaeologist (user principal))
  (let (
    (pattern (map-get? user-patterns user))
  )
    (match pattern
      user-data (and 
                  (>= (get total-messages user-data) u10)
                  (>= (get chaos-score user-data) u100)
                  (>= (get archaeological-reputation user-data) u50)
                )
      false
    )
  )
)
