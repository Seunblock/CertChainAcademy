;; Course Certification System Smart Contract
;; Controls course creation, enrollment, certification, and verification

;; Constants for errors and settings
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-INITIALIZED (err u101))
(define-constant ERR-NOT-INITIALIZED (err u102))
(define-constant ERR-WRONG-PRICE (err u103))
(define-constant ERR-COURSE-NOT-FOUND (err u104))
(define-constant ERR-ALREADY-ENROLLED (err u105))
(define-constant ERR-NOT-ENROLLED (err u106))
(define-constant ERR-INVALID-SCORE (err u107))
(define-constant ERR-ALREADY-CERTIFIED (err u108))
(define-constant ERR-INVALID-INPUT (err u109))  ;; Added missing error constant

;; Status Constants
(define-constant STATUS-ACTIVE u"active")
(define-constant STATUS-COMPLETED u"completed")
(define-constant STATUS-DROPPED u"dropped")

;; Data variables
(define-data-var contract-owner principal tx-sender)
(define-data-var course-counter uint u0)
(define-data-var enrollment-counter uint u0)

;; Input validation constants
(define-constant MIN-PRICE u0)
(define-constant MAX-PRICE u1000000000) ;; 1 billion microstacks
(define-constant MIN-SCORE u0)
(define-constant MAX-SCORE u100)
(define-constant MIN-TITLE-LENGTH u1)
(define-constant MAX-COURSE-ID u1000000) ;; 1 million courses max

;; Data maps
(define-map courses
    { course-id: uint }
    {
        title: (string-utf8 100),
        description: (string-utf8 500),
        instructor: principal,
        price: uint,
        metadata-uri: (string-utf8 256),
        active: bool,
        total-enrolled: uint
    }
)

(define-map enrollments
    { enrollment-id: uint }
    {
        student: principal,
        course-id: uint,
        timestamp: uint,
        status: (string-utf8 20)  ;; using STATUS constants
    }
)

(define-map certificates
    { student: principal, course-id: uint }
    {
        certificate-id: (string-utf8 64),
        score: uint,
        issued-on: uint,
        issued-by: principal,
        metadata-uri: (string-utf8 256)
    }
)

(define-map student-enrollments
    { student: principal }
    { enrolled-courses: (list 20 uint) }
)

(define-map course-students
    { course-id: uint }
    { enrolled-students: (list 100 principal) }
)

;; Validation functions
(define-private (is-valid-price (price uint))
    (and (>= price MIN-PRICE) (<= price MAX-PRICE))
)

(define-private (is-valid-course-id (course-id uint))
    (and (> course-id u0) (<= course-id MAX-COURSE-ID))
)

(define-private (is-valid-string-length (str (string-utf8 500)))
    (> (len str) u0)
)

;; Initialize contract
(define-public (initialize (owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-eq owner tx-sender)) ERR-NOT-AUTHORIZED)
        (ok (var-set contract-owner owner))
    )
)

;; Course Management Functions
(define-public (create-course (title (string-utf8 100)) 
                            (description (string-utf8 500))
                            (price uint)
                            (metadata-uri (string-utf8 256)))
    (let
        ((new-course-id (+ (var-get course-counter) u1)))
        (asserts! (or (is-eq tx-sender (var-get contract-owner))
                     (is-authorized tx-sender)) ERR-NOT-AUTHORIZED)
        (asserts! (is-valid-string-length title) ERR-INVALID-INPUT)
        (asserts! (is-valid-string-length description) ERR-INVALID-INPUT)
        (asserts! (is-valid-string-length metadata-uri) ERR-INVALID-INPUT)
        (asserts! (is-valid-price price) ERR-WRONG-PRICE)
        (map-set courses
            { course-id: new-course-id }
            {
                title: title,
                description: description,
                instructor: tx-sender,
                price: price,
                metadata-uri: metadata-uri,
                active: true,
                total-enrolled: u0
            }
        )
        (var-set course-counter new-course-id)
        (ok new-course-id)
    )
)

(define-public (update-course (course-id uint)
                            (title (string-utf8 100))
                            (description (string-utf8 500))
                            (price uint)
                            (metadata-uri (string-utf8 256))
                            (active bool))
    (let ((course (unwrap! (map-get? courses { course-id: course-id }) ERR-COURSE-NOT-FOUND)))
        (asserts! (is-valid-course-id course-id) ERR-COURSE-NOT-FOUND)
        (asserts! (is-eq tx-sender (get instructor course)) ERR-NOT-AUTHORIZED)
        (asserts! (is-valid-string-length title) ERR-INVALID-INPUT)
        (asserts! (is-valid-string-length description) ERR-INVALID-INPUT)
        (asserts! (is-valid-string-length metadata-uri) ERR-INVALID-INPUT)
        (asserts! (is-valid-price price) ERR-WRONG-PRICE)
        (ok (map-set courses
            { course-id: course-id }
            {
                title: title,
                description: description,
                instructor: (get instructor course),
                price: price,
                metadata-uri: metadata-uri,
                active: active,
                total-enrolled: (get total-enrolled course)
            }))
    )
)

;; Enrollment Functions
(define-public (enroll-in-course (course-id uint))
    (let
        ((course (unwrap! (map-get? courses { course-id: course-id }) ERR-COURSE-NOT-FOUND))
         (enrollment-id (+ (var-get enrollment-counter) u1))
         (current-enrollments (default-to { enrolled-courses: (list) } 
                             (map-get? student-enrollments { student: tx-sender }))))
        (asserts! (is-valid-course-id course-id) ERR-COURSE-NOT-FOUND)
        (asserts! (get active course) ERR-COURSE-NOT-FOUND)
        (asserts! (is-none (map-get? certificates { student: tx-sender, course-id: course-id }))
                 ERR-ALREADY-CERTIFIED)
        (try! (stx-transfer? (get price course) tx-sender (var-get contract-owner)))
        (map-set enrollments
            { enrollment-id: enrollment-id }
            {
                student: tx-sender,
                course-id: course-id,
                timestamp: block-height,
                status: STATUS-ACTIVE
            }
        )
        (map-set student-enrollments
            { student: tx-sender }
            { enrolled-courses: (unwrap! (as-max-len? 
                (append (get enrolled-courses current-enrollments) course-id) u20)
                ERR-ALREADY-ENROLLED) }
        )
        (var-set enrollment-counter enrollment-id)
        (ok enrollment-id)
    )
)

;; Certification Functions
(define-public (issue-certificate (student principal)
                                (course-id uint)
                                (score uint)
                                (metadata-uri (string-utf8 256)))
    (let
        ((course (unwrap! (map-get? courses { course-id: course-id }) ERR-COURSE-NOT-FOUND))
         (certificate-id (concat 
                            (concat u"CERT" (to-ascii course-id))
                            (to-ascii block-height))))
        (asserts! (is-valid-course-id course-id) ERR-COURSE-NOT-FOUND)
        (asserts! (is-eq (get instructor course) tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (and (>= score MIN-SCORE) (<= score MAX-SCORE)) ERR-INVALID-SCORE)
        (asserts! (is-valid-string-length metadata-uri) ERR-INVALID-INPUT)
        (asserts! (is-none (map-get? certificates { student: student, course-id: course-id }))
                 ERR-ALREADY-CERTIFIED)
        (ok (map-set certificates
            { student: student, course-id: course-id }
            {
                certificate-id: certificate-id,
                score: score,
                issued-on: block-height,
                issued-by: tx-sender,
                metadata-uri: metadata-uri
            }))
    )
)

;; Read-only Functions
(define-read-only (get-course-details (course-id uint))
    (map-get? courses { course-id: course-id })
)

(define-read-only (get-certificate (student principal) (course-id uint))
    (map-get? certificates { student: student, course-id: course-id })
)

(define-read-only (get-student-courses (student principal))
    (map-get? student-enrollments { student: student })
)

(define-read-only (verify-certificate (student principal) 
                                    (course-id uint))
    (let ((cert (map-get? certificates { student: student, course-id: course-id })))
        (if (is-some cert)
            (ok cert)
            (err u404))
    )
)

;; Private Helper Functions
(define-private (is-authorized (user principal))
    (is-eq user (var-get contract-owner))
)

(define-private (to-ascii (value uint))
    (concat u"" 
        (unwrap-panic 
            (element-at 
                (list 
                    u"0" u"1" u"2" u"3" u"4" u"5" u"6" u"7" u"8" u"9" 
                    u"A" u"B" u"C" u"D" u"E" u"F"
                )
                value
            )
        )
    )
)

;; Contract initialization check
(define-private (is-initialized)
    (not (is-eq (var-get contract-owner) tx-sender))
)