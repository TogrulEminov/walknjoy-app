//
//  FormValdation.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import Foundation

enum FormValdation {
    static func isNotEmpty(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    static func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

        return email.range(of: regex, options: .regularExpression) != nil
    }
    static func isValidPassword(_ password: String) -> Bool {
        let regex = #"^(?=.*[A-Za-z])(?=.*\d).{8,128}$"#

        return password.range(of: regex, options: .regularExpression) != nil
    }
    static func isPasswordMatched(password: String, confirmPassword: String)
        -> Bool
    {
        password == confirmPassword
    }
}
