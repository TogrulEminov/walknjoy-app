import Foundation

struct ValidationRule {
    let message: String
    let validate: (String) -> Bool

    static func required(_ message: String) -> Self {
        Self(message: message, validate: FormValdation.isNotEmpty)
    }

    static func email(_ message: String) -> Self {
        Self(message: message, validate: FormValdation.isValidEmail)
    }

    static func password(_ message: String) -> Self {
        Self(message: message, validate: FormValdation.isValidPassword)
    }

    static func digits(_ count: Int, optional: Bool = false, message: String) -> Self {
        Self(message: message) { value in
            (optional && value.isEmpty) || (value.count == count && value.allSatisfy(\.isNumber))
        }
    }
}

/// No rules means an input is tracked for changes but does not require validation.
/// Supply originalValue only for edit forms. Passwords use exact comparison by default.
struct ValidatedField {
    let value: String
    var rules: [ValidationRule] = []
    var originalValue: String? = nil
    var normalize: (String) -> String = { $0 }

    var errorMessage: String? {
        rules.first { !$0.validate(value) }?.message
    }

    var isValid: Bool { errorMessage == nil }
    var hasChanges: Bool {
        guard let originalValue else { return false }
        return normalize(value) != normalize(originalValue)
    }

    static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension ValidatedField {
    /// Toggle choices need change tracking, but no text validation.
    static func toggle(_ value: Bool, originalValue: Bool) -> Self {
        Self(value: String(value), originalValue: String(originalValue))
    }
}

/// A fresh value derived from the current inputs; no shared mutable singleton.
struct FormState<Field: Hashable> {
    let fields: [Field: ValidatedField]
    var isSubmitting = false
    var isBlocked = false
    var requiresChanges = false

    subscript(_ field: Field) -> ValidatedField {
        guard let value = fields[field] else {
            preconditionFailure("Field is missing from the form schema")
        }
        return value
    }

    var isValid: Bool { fields.values.allSatisfy(\.isValid) }
    var hasChanges: Bool { fields.values.contains(where: \.hasChanges) }
    var canSubmit: Bool {
        isValid && !isSubmitting && !isBlocked && (!requiresChanges || hasChanges)
    }
}

enum AuthField {
    case firstName, lastName, email, password, code
}

/// Both views and request methods use these schemas, so rules are declared once.
enum AuthForms {
    static func login(email: String, password: String, isSubmitting: Bool = false) -> FormState<AuthField> {
        FormState(fields: [
            .email: ValidatedField(value: email, rules: [.email("login.validation.email")]),
            .password: ValidatedField(value: password, rules: [.password("login.validation.password")])
        ], isSubmitting: isSubmitting)
    }

    static func register(firstName: String, lastName: String, email: String, password: String, isSubmitting: Bool = false) -> FormState<AuthField> {
        FormState(fields: [
            .firstName: ValidatedField(value: firstName, rules: [.required("register.validation.firstName")]),
            .lastName: ValidatedField(value: lastName, rules: [.required("register.validation.lastName")]),
            .email: ValidatedField(value: email, rules: [.email("register.validation.email")]),
            .password: ValidatedField(value: password, rules: [.password("register.validation.password")])
        ], isSubmitting: isSubmitting)
    }

    static func forgotPassword(email: String, isSubmitting: Bool = false) -> FormState<AuthField> {
        FormState(fields: [
            .email: ValidatedField(value: email, rules: [.email("forgot.validation.email")])
        ], isSubmitting: isSubmitting)
    }

    static func resetPassword(password: String, isSubmitting: Bool = false, isBlocked: Bool = false) -> FormState<AuthField> {
        FormState(fields: [
            .password: ValidatedField(value: password, rules: [.password("reset.validation.passwordInvalid")])
        ], isSubmitting: isSubmitting, isBlocked: isBlocked)
    }

    static func otp(code: String, isSubmitting: Bool = false, isBlocked: Bool = false) -> FormState<AuthField> {
        FormState(fields: [
            .code: ValidatedField(value: code, rules: [.digits(6, message: "otp.validation.code")])
        ], isSubmitting: isSubmitting, isBlocked: isBlocked)
    }
}
