import Foundation
import UIKit

// Struct class ferqi  , Address class deyilde struct olanda person 2 let ile immutable olur, bunun ucun var la teyin etmek lazmdir
class Address {
    var city: String
    init(city: String) {
        self.city = city
    }

}
struct Person {
    var name: String
    var address: Address
}
let person1 = Person(name: "Togrul", address: Address(city: "Baku"))
let person2 = person1
person2.address.city = "Goycay"

print("address", person1.address.city)  // Goycay

// ARC
class Owner {
    var pet: Pet?
    deinit { print("Owner deinit") }
}
class Pet {
    weak var owner: Owner?
    deinit { print("Pet deinit") }
}
var owner: Owner = Owner()
var pet: Pet? = Pet()
owner.pet = pet
pet?.owner = owner
owner.pet = nil
print(owner.pet)



class ProfileViewModel {
    var onUpdate: (() -> Void)?
    func setUp() {
        onUpdate = { [weak self] in
            self?.refresh()
        }
    }
    func refresh() {}
    deinit { print("update deinit") }
}

var vm: ProfileViewModel? = ProfileViewModel()

vm?.setUp()
vm?.onUpdate?()

vm = nil
