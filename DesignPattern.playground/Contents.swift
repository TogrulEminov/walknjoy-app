protocol PaymentMethodProtocol {
    func pay(amount: Double)
}
struct CreditCard: PaymentMethodProtocol {
    func pay(amount: Double) {
        print("pay credit card")
    }
}
struct PayPal: PaymentMethodProtocol {
    func pay(amount: Double) {
        print("pay paypal card")
    }
}
struct ApplePay: PaymentMethodProtocol {
    func pay(amount: Double) {
        print("apple payment ")
    }
}
enum CardsEnum {
    case paypal
    case credit
    case applepay
}

enum PaymentFactory {
    static func make(_ type: CardsEnum) -> any PaymentMethodProtocol {
        switch type {
        case .applepay: ApplePay()
        case .credit: CreditCard()
        case .paypal: PayPal()
        }
    }
}

let payment = PaymentFactory.make(.applepay)
payment.pay(amount: 50)
