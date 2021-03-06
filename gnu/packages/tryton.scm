;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017 Adriano Peluso <catonano@gmail.com>
;;; Copyright © 2020 Vinicius Monego <monego@posteo.net>
;;; Copyright © 2021 Maxime Devos <maximedevos@telenet.be>
;;; Copyright © 2021 Hartmut Goebel <h.goebel@crazy-compilers.com>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages tryton)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages check)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages finance)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-crypto)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages time)
  #:use-module (gnu packages xml)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix build-system python))

(define-public trytond
  (package
    (name "trytond")
    (version "6.0.6")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond" version))
       (sha256
        (base32 "1jp5cadqpwkcnml8r1hj6aak5kc8an2d5ai62p96x77nn0dp3ny4"))))
    (build-system python-build-system)
    (propagated-inputs
     `(("python-dateutil" ,python-dateutil)
       ("python-genshi" ,python-genshi)
       ("python-lxml" ,python-lxml)
       ("python-magic" ,python-magic)
       ("python-passlib" ,python-passlib)
       ("python-polib" ,python-polib)
       ("python-psycopg2" ,python-psycopg2)
       ("python-relatorio" ,python-relatorio)
       ("python-sql" ,python-sql)
       ("python-werkzeug" ,python-werkzeug)
       ("python-wrapt" ,python-wrapt)))
    (native-inputs
     `(("python-mock" ,python-mock)
       ("python-pillow" ,python-pillow)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-before 'check 'preparations
           (lambda _
             (setenv "DB_NAME" ":memory:")
             (setenv "HOME" "/tmp")
             #t)))))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton Server")
    (description "Tryton is a three-tier high-level general purpose
application platform using PostgreSQL as its main database engine.  It is the
core base of a complete business solution providing modularity, scalability
and security.")
    (license license:gpl3+)))

(define-public python-trytond
  (deprecated-package "python-trytond" trytond))

(define-public tryton
  (package
    (name "tryton")
    (version "6.0.5")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "tryton" version))
       (sha256
        (base32 "15cbp2r25pkr7lp4yliqgb6d0n779z70d4gckv56bx5aw4z27f66"))))
    (build-system python-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-before 'check 'change-home
           (lambda _
             ;; Change from /homeless-shelter to /tmp for write permission.
             (setenv "HOME" "/tmp")))
         (add-after 'install 'wrap-gi-python
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let ((out               (assoc-ref outputs "out"))
                   (gi-typelib-path   (getenv "GI_TYPELIB_PATH")))
               (wrap-program (string-append out "/bin/tryton")
                 `("GI_TYPELIB_PATH" ":" prefix (,gi-typelib-path))))
             #t)))))
    (native-inputs
     `(("glib-compile-schemas" ,glib "bin")
       ("gobject-introspection" ,gobject-introspection)))
    (propagated-inputs
     `(("gdk-pixbuf" ,gdk-pixbuf+svg)
       ("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
       ("gtk+" ,gtk+)
       ("python-dateutil" ,python-dateutil)
       ("python-pycairo" ,python-pycairo)
       ("python-pygobject" ,python-pygobject)))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton Client")
    (description
     "This package provides the Tryton GTK client.")
    (license license:gpl3+)))

(define-public python-proteus
  (package
    (name "python-proteus")
    (version "6.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "proteus" version))
       (sha256
        (base32 "0qr7rir7ysxvy2kyfzp2d2kcw9qzq4vdkddbwswzgddxjpycksdh"))))
    (build-system python-build-system)
    ;; Tests require python-trytond-party which requires python-proteus.
    (arguments
     `(#:tests? #f))
    (propagated-inputs
     `(("python-dateutil" ,python-dateutil)))
    (home-page "http://www.tryton.org/")
    (synopsis "Library to access a Tryton server as a client")
    (description
     "This package provides a library to access Tryton server as a client.")
    (license license:lgpl3+)))

(define (tryton-phases module . extra-arguments)
  "Return the phases for building and testing a Tryton module named MODULE.
If present, pass EXTRA-ARGUMENTS to runtest as well."
  `(modify-phases %standard-phases
     (replace 'check
       (lambda* (#:key inputs outputs tests? #:allow-other-keys)
         (let ((runtest
                (string-append
                 (assoc-ref inputs "trytond")
                 "/lib/python"
                 ,(version-major+minor (package-version python))
                 "/site-packages/trytond/tests/run-tests.py")))
           (when tests?
             (add-installed-pythonpath inputs outputs)
             (invoke "python" runtest "-m" ,module ,@extra-arguments)))))))

(define (tryton-arguments module . extra-arguments)
  "Like ’tryton-phases’, but directly return all arguments for
the build system."
  `(#:phases ,(apply tryton-phases module extra-arguments)))

;;;
;;;  Tryton modules - please sort alphabetically
;;;

(define %standard-trytond-native-inputs
  ;; native-inputs required by most of the tryton module for running the test
  `(("python-dateutil" ,python-dateutil)
    ("python-genshi" ,python-genshi)
    ("python-lxml" ,python-lxml)
    ("python-magic" ,python-magic)
    ("python-passlib" ,python-passlib)
    ("python-polib" ,python-polib)
    ("python-proteus" ,python-proteus)
    ("python-relatorio" ,python-relatorio)
    ("python-sql" ,python-sql)
    ("python-werkzeug" ,python-werkzeug)
    ("python-wrapt" ,python-wrapt)))

(define-public trytond-account
  (package
    (name "trytond-account")
    (version "6.0.3")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account" version))
       (sha256
        (base32 "0j1mn8sd5n8rkwgfvcy9kf8s7s3qxvnilnc72i83ac573zj922xc"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account"))
    (native-inputs `(,@%standard-trytond-native-inputs))
    (propagated-inputs
     `(("python-simpleeval" ,python-simpleeval)
       ("trytond" ,trytond)
       ("trytond-company" ,trytond-company)
       ("trytond-currency" ,trytond-currency)
       ("trytond-party" ,trytond-party)))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for accounting")
    (description
     "This package provides a Tryton module that defines the fundamentals for
most of accounting needs.")
    (license license:gpl3+)))

(define-public python-trytond-account
  (deprecated-package "python-trytond-account" trytond-account))

(define-public trytond-account-invoice
  (package
    (name "trytond-account-invoice")
    (version "6.0.3")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_invoice" version))
       (sha256
        (base32 "0r8zigb4qmv40kf835x8jd7049nnhk5g7g0aibvfd0y9p28lspnz"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_invoice"))
    (native-inputs `(,@%standard-trytond-native-inputs))
    (propagated-inputs
     `(("trytond" ,trytond)
       ("trytond-account" ,trytond-account)
       ("trytond-account-product" ,trytond-account-product)
       ("trytond-company" ,trytond-company)
       ("trytond-currency" ,trytond-currency)
       ("trytond-party" ,trytond-party)
       ("trytond-product" ,trytond-product)))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for invoicing")
    (description
     "This package provides a Tryton module that adds the invoice, payment
term.")
    (license license:gpl3+)))

(define-public python-trytond-account-invoice
  (deprecated-package "python-trytond-account-invoice" trytond-account-invoice))

(define-public trytond-account-invoice-stock
  (package
    (name "trytond-account-invoice-stock")
    (version "6.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_invoice_stock" version))
       (sha256
        (base32 "1228n6vsx0rdjsy3idvpyssa3n21nhvz9gqaacwa46c0hp2251bp"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_invoice_stock"))
    (native-inputs `(,@%standard-trytond-native-inputs))
    (propagated-inputs
     `(("trytond" ,trytond)
       ("trytond-account-invoice" ,trytond-account-invoice)
       ("trytond-product" ,trytond-product)
       ("trytond-stock" ,trytond-stock)))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module to link stock and invoice")
    (description
     "This package provides a Tryton module that adds link between invoice
lines and stock moves.  The unit price of the stock move is updated with the
average price of the posted invoice lines that are linked to it.")
    (license license:gpl3+)))

(define-public python-trytond-account-invoice-stock
  (deprecated-package
   "python-trytond-account-invoice-stock" trytond-account-invoice-stock))

(define-public trytond-account-product
  (package
    (name "trytond-account-product")
    (version "6.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_account_product" version))
       (sha256
        (base32 "1z0dn1p22smzb4a9v451224wrpxcw94inl7jxkarc0q088gasn7d"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "account_product"))
    (native-inputs `(,@%standard-trytond-native-inputs))
    (propagated-inputs
     `(("trytond" ,trytond)
       ("trytond-account" ,trytond-account)
       ("trytond-analytic-account" ,trytond-analytic-account)
       ("trytond-company" ,trytond-company)
       ("trytond-product" ,trytond-product)))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module to add accounting on product")
    (description
     "This package provides a Tryton module that adds accounting on product
and category.")
    (license license:gpl3+)))

(define-public python-trytond-account-product
  (deprecated-package "python-trytond-account-product" trytond-account-product))

(define-public trytond-analytic-account
  (package
    (name "trytond-analytic-account")
    (version "6.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_analytic_account" version))
       (sha256
        (base32 "09j9xz41n5hk3j7w63xbw1asd3p00prqvl652qcm9x1nrlmqiw3r"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "analytic_account"))
    (native-inputs `(,@%standard-trytond-native-inputs))
    (propagated-inputs
     `(("trytond" ,trytond)
       ("trytond-account" ,trytond-account)
       ("trytond-company" ,trytond-company)
       ("trytond-currency" ,trytond-currency)
       ("trytond-party" ,trytond-party)))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for analytic accounting")
    (description
     "This package provides a Tryton module that adds the fundamentals
required to analyse accounting using multiple different axes.")
    (license license:gpl3+)))

(define-public python-trytond-analytic-account
  (deprecated-package
   "python-trytond-analytic-account" trytond-analytic-account))

(define-public trytond-company
  (package
    (name "trytond-company")
    (version "6.0.3")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_company" version))
       (sha256
        (base32 "1q4qdyg32dn00pn3pj2yjl3jhxaqpv7a1cv5s5c95cpy5p46p02n"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "company"))
    (native-inputs `(,@%standard-trytond-native-inputs))
    (propagated-inputs
     `(("trytond" ,trytond)
       ("trytond-currency" ,trytond-currency)
       ("trytond-party" ,trytond-party)))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module with companies and employees")
    (description
     "This package provides a Tryton module that defines the concepts of
company and employee and extend the user model.")
    (license license:gpl3+)))

(define-public python-trytond-company
  (deprecated-package "python-trytond-company" trytond-company))

(define-public trytond-country
  (package
    (name "trytond-country")
    (version "6.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_country" version))
       (sha256
        (base32 "1ksinysac7p0k8avsz8xqzfkmm21s6i93qyrsma5h4y5477cwmw7"))))
    (build-system python-build-system)
    ;; Doctest contains one test that requires internet access.
    (arguments (tryton-arguments "country" "--no-doctest"))
    (native-inputs `(,@%standard-trytond-native-inputs))
    (propagated-inputs
     `(("python-pycountry" ,python-pycountry)
       ("trytond" ,trytond)))
    (home-page "http://www.tryton.org/")
    (synopsis "Tryton module with countries")
    (description
     "This package provides a Tryton module with countries.")
    (license license:gpl3+)))

(define-public python-trytond-country
  (deprecated-package "python-trytond-country" trytond-country))

(define-public trytond-currency
  (package
    (name "trytond-currency")
    (version "6.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_currency" version))
       (sha256
        (base32 "0fs2wvhgvc0l4yzs5m9l8z4lbzazr42hgz0859malhnlp1sya2kq"))))
    (build-system python-build-system)
    ;; Doctest 'scenario_currency_rate_update.rst' fails.
    (arguments (tryton-arguments "currency" "--no-doctest"))
    (native-inputs
     `(,@%standard-trytond-native-inputs
       ("python-forex-python" ,python-forex-python)
       ("python-pycountry" ,python-pycountry)))
    (propagated-inputs
     `(("python-sql" ,python-sql)
       ("trytond" ,trytond)))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module with currencies")
    (description
     "This package provides a Tryton module that defines the concepts of
currency and rate.")
    (license license:gpl3+)))

(define-public python-trytond-currency
  (deprecated-package "python-trytond-currency" trytond-currency))

(define-public trytond-party
  (package
    (name "trytond-party")
    (version "6.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_party" version))
       (sha256
        (base32 "0aikzpr0ambc98v76dl6xqa42b08dy3b011y33lvxjp5mcha3f7y"))))
    (build-system python-build-system)
    ;; Doctest 'scenario_party_phone_number.rst' fails.
    (arguments (tryton-arguments "party" "--no-doctest"))
    (native-inputs `(,@%standard-trytond-native-inputs))
    (propagated-inputs
     `(("python-stdnum" ,python-stdnum)
       ("trytond" ,trytond)
       ("trytond-country" ,trytond-country)))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for parties and addresses")
    (description
     "This package provides a Tryton module for (counter)parties and
addresses.")
    (license license:gpl3+)))

(define-public python-trytond-party
  (deprecated-package "python-trytond-party" trytond-party))

(define-public trytond-product
  (package
    (name "trytond-product")
    (version "6.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_product" version))
       (sha256
        (base32 "1xvvqxkvzyqy6fn2sj5h3zj0g17igzwx6s18sxkdz72vqz6kpv0l"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "product"))
    (native-inputs `(,@%standard-trytond-native-inputs))
    (propagated-inputs
     `(("python-stdnum" ,python-stdnum)
       ("trytond" ,trytond)
       ("trytond-company" ,trytond-company)))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module with products")
    (description
     "This package provides a Tryton module that defines two concepts: Product
Template and Product.")
    (license license:gpl3+)))

(define-public python-trytond-product
  (deprecated-package "python-trytond-product" trytond-product))

(define-public trytond-purchase
  (package
    (name "trytond-purchase")
    (version "6.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_purchase" version))
       (sha256
        (base32 "12drjw30ik3alckn6xrny4814vzi3ysh17wgiawiy9319yahsvay"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "purchase"))
    (native-inputs `(,@%standard-trytond-native-inputs))
    (propagated-inputs
     `(("trytond" ,trytond)
       ("trytond-account" ,trytond-account)
       ("trytond-account-invoice" ,trytond-account-invoice)
       ("trytond-account-invoice-stock" ,trytond-account-invoice-stock)
       ("trytond-account-product" ,trytond-account-product)
       ("trytond-company" ,trytond-company)
       ("trytond-currency" ,trytond-currency)
       ("trytond-party" ,trytond-party)
       ("trytond-product" ,trytond-product)
       ("trytond-stock" ,trytond-stock)))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for purchase")
    (description
     "This package provides a Tryton module that defines the Purchase model.")
    (license license:gpl3+)))

(define-public python-trytond-purchase
  (deprecated-package "python-trytond-purchase" trytond-purchase))

(define-public trytond-purchase-request
  (package
    (name "trytond-purchase-request")
    (version "6.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_purchase_request" version))
       (sha256
        (base32 "0yhf3lh5b24qpk80r5pbmmswf5757bxa0s7ckl40vf6lkjkccv5i"))))
    (build-system python-build-system)
    ;; Doctest 'scenario_purchase_request.rst' fails.
    (arguments (tryton-arguments "purchase_request" "--no-doctest"))
    (native-inputs `(,@%standard-trytond-native-inputs))
    (propagated-inputs
     `(("trytond" ,trytond)
       ("trytond-product" ,trytond-product)
       ("trytond-purchase" ,trytond-purchase)))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for purchase requests")
    (description
     "This package provides a Tryton module that introduces the concept of
Purchase Requests which are central points to collect purchase requests
generated by other process from Tryton.")
    (license license:gpl3+)))

(define-public python-trytond-purchase-request
  (deprecated-package
   "python-trytond-purchase-request" trytond-purchase-request))

(define-public trytond-stock
  (package
    (name "trytond-stock")
    (version "6.0.6")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock" version))
       (sha256
        (base32 "1v6pvkwj6vhjqbz2zn0609kb7kx4g0dsn1xhvax4z2dqigh7ywpx"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock"))
    (native-inputs `(,@%standard-trytond-native-inputs))
    (propagated-inputs
     `(("python-simpleeval" ,python-simpleeval)
       ("trytond" ,trytond)
       ("trytond-company" ,trytond-company)
       ("trytond-currency" ,trytond-currency)
       ("trytond-party" ,trytond-party)
       ("trytond-product" ,trytond-product)))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for stock and inventory")
    (description
     "This package provides a Tryton module that defines the fundamentals for
all stock management situations: Locations where products are stored, moves
between these locations, shipments for product arrivals and departures and
inventory to control and update stock levels.")
    (license license:gpl3+)))

(define-public python-trytond-stock
  (deprecated-package "python-trytond-stock" trytond-stock))

(define-public trytond-stock-lot
  (package
    (name "trytond-stock-lot")
    (version "6.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_lot" version))
       (sha256
        (base32 "18cwrvnrzjk1wb765gr6hp3plpdpwz1a7cwimjhxi47iw7w5c84g"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_lot"))
    (native-inputs `(,@%standard-trytond-native-inputs))
    (propagated-inputs
     `(("trytond" ,trytond)
       ("trytond-product" ,trytond-product)
       ("trytond-stock" ,trytond-stock)))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for lot of products")
    (description
     "This package provides a Tryton module that defines lot of products.")
    (license license:gpl3+)))

(define-public python-trytond-stock-lot
  (deprecated-package "python-trytond-stock-lot" trytond-stock-lot))

(define-public trytond-stock-supply
  (package
    (name "trytond-stock-supply")
    (version "6.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "trytond_stock_supply" version))
       (sha256
        (base32 "1p5l3yjjy6l25kk9xnhbl691l3v8gfg9fhc87jc6qszhxlqxk730"))))
    (build-system python-build-system)
    (arguments (tryton-arguments "stock_supply"))
    (native-inputs `(,@%standard-trytond-native-inputs))
    (propagated-inputs
     `(("trytond" ,trytond)
       ("trytond-account" ,trytond-account)
       ("trytond-party" ,trytond-party)
       ("trytond-product" ,trytond-product)
       ("trytond-purchase" ,trytond-purchase)
       ("trytond-purchase-request" ,trytond-purchase-request)
       ("trytond-stock" ,trytond-stock)))
    (home-page "https://www.tryton.org/")
    (synopsis "Tryton module for stock supply")
    (description
     "This package provides a Tryton module that adds automatic supply
mechanisms and introduces the concepts of order point.")
    (license license:gpl3+)))

(define-public python-trytond-stock-supply
  (deprecated-package "python-trytond-stock-supply" trytond-stock-supply))
