;; contracts/air-quality-monitor.clar

;; Error codes
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_READING (err u101))
(define-constant ERR_THRESHOLD_RANGE (err u102))
(define-constant ERR_INVALID_SENSOR (err u103))

;; Constants for validation
(define-constant MAX_SENSOR_ID u1000)

;; Data variables
(define-data-var admin principal tx-sender)
(define-map air-quality-readings
    { sensor-id: uint, timestamp: uint }
    { 
        pm25: uint,
        pm10: uint,
        temperature: uint,
        humidity: uint,
        gas: uint
    }
)

(define-map alert-thresholds
    { parameter: (string-ascii 20) }
    { threshold: uint }
)

;; Public functions
(define-public (submit-reading (sensor-id uint) (pm25 uint) (pm10 uint) (temp uint) (humidity uint) (gas uint))
    (let
        (
            (timestamp block-height)
        )
        (begin
            (asserts! (is-authorized) ERR_UNAUTHORIZED)
            (asserts! (is-valid-sensor-id sensor-id) ERR_INVALID_SENSOR)
            (asserts! (is-valid-reading pm25 pm10 temp humidity gas) ERR_INVALID_READING)
            (ok (map-set air-quality-readings
                { sensor-id: sensor-id, timestamp: timestamp }
                {
                    pm25: pm25,
                    pm10: pm10,
                    temperature: temp,
                    humidity: humidity,
                    gas: gas
                }
            ))
        )
    )
)

;; Private functions
(define-private (is-authorized)
    (is-eq tx-sender (var-get admin))
)

(define-private (is-valid-sensor-id (sensor-id uint))
    (< sensor-id MAX_SENSOR_ID)
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

;; Read-only functions
(define-read-only (get-reading (sensor-id uint) (timestamp uint))
    (map-get? air-quality-readings { sensor-id: sensor-id, timestamp: timestamp })
)
