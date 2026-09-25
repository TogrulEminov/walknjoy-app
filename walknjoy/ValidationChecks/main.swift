import Foundation

enum Field { case name, note, phone }
func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

let required = ValidationRule.required("required")
let email = ValidationRule.email("email")
let invalid = ValidatedField(value: " ", rules: [required, email])
check(invalid.errorMessage == "required", "First failing rule supplies the input error")

var edit = FormState(fields: [
    Field.name: ValidatedField(value: " Ada ", rules: [required], originalValue: "Ada", normalize: ValidatedField.trimmed)
], requiresChanges: true)
check(edit.isValid && !edit.hasChanges && !edit.canSubmit, "Normalized no-op edits cannot save")

edit = FormState(fields: [
    .name: ValidatedField(value: "", rules: [required], originalValue: "Ada")
], requiresChanges: true)
check(edit.hasChanges && !edit.canSubmit, "Changed but invalid edits cannot save")

var changed = FormState(fields: [
    Field.note: ValidatedField(value: "Updated", originalValue: "")
], requiresChanges: true)
check(changed.canSubmit, "Fields without rules can still track changes")
changed.isSubmitting = true
check(!changed.canSubmit, "In-flight submissions block duplicates")
changed.isSubmitting = false
changed.isBlocked = true
check(!changed.canSubmit, "External work can block submission")

let optionalPhone = ValidationRule.digits(9, optional: true, message: "phone")
check(optionalPhone.validate(""), "Optional phone can be empty")
check(!optionalPhone.validate("123"), "Partial optional phone is invalid")
check(optionalPhone.validate("501234567"), "Complete optional phone is valid")
check(!optionalPhone.validate("abcdefghi"), "Phone must contain digits")

check(!AuthForms.login(email: "", password: "").canSubmit, "Empty login is invalid")
check(AuthForms.login(email: " user@example.com ", password: "password1").canSubmit, "Valid login needs no dirty state")
check(!AuthForms.register(firstName: " ", lastName: "User", email: "user@example.com", password: "password1").canSubmit, "Registration names are required")
check(!AuthForms.resetPassword(password: "password1", isBlocked: true).canSubmit, "Missing reset token blocks submission")
check(!AuthForms.otp(code: "12345").canSubmit, "Partial OTP cannot submit")
check(!AuthForms.otp(code: "12345a").canSubmit, "Non-digit OTP cannot submit")
check(!AuthForms.otp(code: "123456", isBlocked: true).canSubmit, "Expired OTP cannot submit")
check(AuthForms.otp(code: "123456").canSubmit, "Valid OTP can submit")
print("PASS: shared form rules, errors, normalized changes, optional fields, submission gates, auth schemas")
