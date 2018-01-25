#lang braidbot/insta

(require braidbot/util)

(define bot-id (or (getenv "BOT_ID") "5a693a60-008c-4e96-b26a-1ff8df38de9f"))
(define bot-token (or (getenv "BOT_TOKEN") "bBjo9Jl1jW244In_9hpquG70rUeY1O2kY8ewFPH9"))
(define braid-api-url (or (getenv "BRAID_API_URL") "http://localhost:5557"))
(define braid-frontend-url (or (getenv "BRAID_FRONTEND_URL") "http://localhost:5555"))

(listen-port 9192)

(define (parse-roll roll-txt)
  (if-let [matches (regexp-match #rx"^([0-9]*)d([0-9]+)([-+][0-9]+)?$" roll-txt)]
    (let ([ndice (~> matches cadr string->number (or 1))]
          [nsides (~> matches caddr string->number)]
          [bonus (or (some~> matches cadddr string->number) 0)])
      (+ (for/sum ([_ (range ndice)])
           (+ 1 (random nsides)))
         bonus))
    #f))

(define (reply msg txt)
  (reply-to msg txt
            #:bot-id bot-id
            #:bot-token bot-token
            #:braid-url braid-api-url))

(define (act-on-message msg)
  (let ([roll-req (~> (hash-ref msg '#:content)
                      (string-replace "/roll " "" #:all? #f))])
    (~>>
     (if-let [result (parse-roll roll-req)]
       (format "~s = ~v" roll-req result)
       (~> (list
            (format "Couldn't parse request ~v" roll-req)
            "Try something like `/roll d6`, `/roll 3d4`, `/roll 2d20+3`")
           (string-join "\n")))
     (reply msg))))
