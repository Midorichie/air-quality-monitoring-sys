;; contracts/air-quality-monitor.clar

;; Error codes
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_READING (err u101))
(define-constant ERR_THRESHOLD_RANGE (err u102))
(define-constant ERR_INVALID_SENSOR (err u103))
(define-constant ERR_SENSOR_NOT_REGISTERED (err u104))
(define-constant ERR_ALREADY_REGISTERED (err u105))
(define-constant ERR_INVALID_LOCATION (err u106))
(define-constant ERR_INVALID_PARAMETER (err u107))
(define-constant ERR_INVALID_CONTACT (err u108))

;; Constants for validation
(define-constant MAX_SENSOR_ID u1000)
(define-constant CRITICAL_PM25_LEVEL u300)
(define-constant CRITICAL_GAS_LEVEL u800)
(define-constant VALID_PARAMETERS (list "pm25" "pm10" "temperature" "humidity" "gas"))

;; Blacklisted contacts
(define-map blacklisted-contacts principal bool)

;; Data variables
(define-data-var admin principal tx-sender)
(define-data-var emergency-contact principal tx-sender)

;; Maps
(define-map air-quality-readings
    { sensor-id: uint, timestamp: uint }
    { 
        pm25: uint,
        pm10: uint,
        temperature: uint,
        humidity: uint,
        gas: uint,
        status: (string-ascii 20)
    }
)

(define-map registered-sensors
    { sensor-id: uint }
    {
        location: (string-ascii 50),
        authorized: bool,
        last-maintenance: uint
    }
)

(define-map alert-thresholds
    { parameter: (string-ascii 20) }
    { 
        warning-level: uint,
        critical-level: uint 
    }
)

;; Public functions
(define-public (register-sensor (sensor-id uint) (location (string-ascii 50)))
    (begin
        (asserts! (is-authorized) ERR_UNAUTHORIZED)
        (asserts! (is-valid-sensor-id sensor-id) ERR_INVALID_SENSOR)
        (asserts! (is-valid-location location) ERR_INVALID_LOCATION)
        (asserts! (is-none (map-get? registered-sensors {sensor-id: sensor-id})) ERR_ALREADY_REGISTERED)
        (ok (map-set registered-sensors
            {sensor-id: sensor-id}
            {
                location: location,
                authorized: true,
                last-maintenance: block-height
            }
        ))
    )
)

(define-public (submit-reading (sensor-id uint) (pm25 uint) (pm10 uint) (temp uint) (humidity uint) (gas uint))
    (let
        (
            (timestamp block-height)
            (status (get-air-quality-status pm25 gas))
        )
        (begin
            (asserts! (is-sensor-registered sensor-id) ERR_SENSOR_NOT_REGISTERED)
            (asserts! (is-valid-reading pm25 pm10 temp humidity gas) ERR_INVALID_READING)
            (try! (check-and-trigger-alerts pm25 gas))
            (ok (map-set air-quality-readings
                { sensor-id: sensor-id, timestamp: timestamp }
                {
                    pm25: pm25,
                    pm10: pm10,
                    temperature: temp,
                    humidity: humidity,
                    gas: gas,
                    status: status
                }
            ))
        )
    )
)

(define-public (set-threshold (parameter (string-ascii 20)) (warning uint) (critical uint))
    (begin
        (asserts! (is-authorized) ERR_UNAUTHORIZED)
        (asserts! (is-valid-parameter parameter) ERR_INVALID_PARAMETER)
        (asserts! (< warning critical) ERR_THRESHOLD_RANGE)
        (ok (map-set alert-thresholds
            {parameter: parameter}
            {
                warning-level: warning,
                critical-level: critical
            }
        ))
    )
)

(define-public (update-emergency-contact (new-contact principal))
    (begin
        (asserts! (is-authorized) ERR_UNAUTHORIZED)
        (asserts! (is-valid-contact new-contact) ERR_INVALID_CONTACT)
        (ok (var-set emergency-contact new-contact))
    )
)

;; Private functions
(define-private (is-authorized)
    (is-eq tx-sender (var-get admin))
)

(define-private (is-valid-sensor-id (sensor-id uint))
    (< sensor-id MAX_SENSOR_ID)
)

(define-private (is-valid-location (location (string-ascii 50)))
    (and
        (not (is-eq location ""))
        (not (is-eq location " "))
        (>= (len location) u3)
    )
)

(define-private (is-valid-parameter (parameter (string-ascii 20)))
    (contains parameter VALID_PARAMETERS)
)

(define-private (contains (item (string-ascii 20)) (lst (list 5 (string-ascii 20))))
    (match (index-of lst item)
        value true
        false
    )
)

(define-private (is-valid-contact (contact principal))
    (and
        (not (is-eq contact tx-sender))
        (not (default-to false (map-get? blacklisted-contacts contact)))
    )
)

(define-private (is-sensor-registered (sensor-id uint))
    (and
        (is-some (map-get? registered-sensors {sensor-id: sensor-id}))
        (get authorized (unwrap-panic (map-get? registered-sensors {sensor-id: sensor-id})))
    )
)

(define-private (is-valid-reading (pm25 uint) (pm10 uint) (temp uint) (humidity uint) (gas uint))
    (and
        (< pm25 u1000)
        (< pm10 u1000)
        (< temp u100)
        (< humidity u100)
        (< gas u1000)
    )
)

(define-private (get-air-quality-status (pm25 uint) (gas uint))
    (if (or (> pm25 CRITICAL_PM25_LEVEL) (> gas CRITICAL_GAS_LEVEL))
        "critical"
        (if (or (> pm25 (/ CRITICAL_PM25_LEVEL u2)) (> gas (/ CRITICAL_GAS_LEVEL u2)))
            "warning"
            "normal"
        )
    )
)

(define-private (check-and-trigger-alerts (pm25 uint) (gas uint))
    (if (or (> pm25 CRITICAL_PM25_LEVEL) (> gas CRITICAL_GAS_LEVEL))
        (send-alert)
        (ok true)
    )
)

(define-private (send-alert)
    (as-contract
        (stx-transfer? u1 tx-sender (var-get emergency-contact))
    )
)

;; Read-only functions
(define-read-only (get-reading (sensor-id uint) (timestamp uint))
    (map-get? air-quality-readings { sensor-id: sensor-id, timestamp: timestamp })
)

(define-read-only (get-sensor-info (sensor-id uint))
    (map-get? registered-sensors {sensor-id: sensor-id})
)

(define-read-only (get-threshold (parameter (string-ascii 20)))
    (map-get? alert-thresholds {parameter: parameter})
)
