import Foundation
import Observation

@MainActor
@Observable
final class ProviderProfileFormViewModel {
    private let original: ProviderProfile?

    var businessName: String
    var legalName: String
    var description: String
    var phone: String
    var email: String
    var website: String
    var logoUrl: String
    var taxId: String
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    init(profile: ProviderProfile? = nil) {
        original = profile
        businessName = profile?.businessName ?? ""
        legalName = profile?.legalName ?? ""
        description = profile?.description ?? ""
        phone = profile?.phone ?? ""
        email = profile?.email ?? ""
        website = profile?.website ?? ""
        logoUrl = profile?.logoUrl ?? ""
        taxId = profile?.taxId ?? ""
    }

    var validationMessage: String? {
        if businessName.trimmed.isEmpty {
            return String(localized: "provider.validation.businessName")
        }
        if !phone.trimmed.isEmpty && !phone.trimmed.isE164 {
            return String(localized: "provider.validation.phone")
        }
        if !email.trimmed.isEmpty && !FormValdation.isValidEmail(email) {
            return String(localized: "provider.validation.email")
        }
        if !website.trimmed.isEmpty && !website.trimmed.isHTTPURL {
            return String(localized: "provider.validation.website")
        }
        if !logoUrl.trimmed.isEmpty && !logoUrl.trimmed.isHTTPURL {
            return String(localized: "provider.validation.logo")
        }
        return nil
    }

    var canSubmit: Bool {
        !isSubmitting && validationMessage == nil
            && (original == nil || hasChanges)
    }

    func submit(using flow: ProviderFlowViewModel) async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            if let original {
                try await flow.updateProfile(
                    updateInput(comparedWith: original)
                )
            } else {
                try await flow.submitApplication(applicationInput)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private var applicationInput: ProviderApplicationInput {
        ProviderApplicationInput(
            businessName: businessName.trimmed,
            legalName: legalName.nilIfBlank,
            description: description.nilIfBlank,
            phone: phone.nilIfBlank,
            email: email.nilIfBlank,
            website: website.nilIfBlank,
            taxId: taxId.nilIfBlank
        )
    }

    private var hasChanges: Bool {
        guard let original else { return true }
        return businessName.trimmed != original.businessName
            || legalName.nilIfBlank != original.legalName
            || description.nilIfBlank != original.description
            || phone.nilIfBlank != original.phone
            || email.nilIfBlank != original.email
            || website.nilIfBlank != original.website
            || logoUrl.nilIfBlank != original.logoUrl
            || taxId.nilIfBlank != original.taxId
    }

    private func updateInput(comparedWith profile: ProviderProfile)
        -> UpdateProviderProfileInput
    {
        UpdateProviderProfileInput(
            businessName: businessName.trimmed != profile.businessName
                ? businessName.trimmed : nil,
            legalName: patch(legalName.nilIfBlank, original: profile.legalName),
            description: patch(
                description.nilIfBlank,
                original: profile.description
            ),
            phone: patch(phone.nilIfBlank, original: profile.phone),
            email: patch(email.nilIfBlank, original: profile.email),
            website: patch(website.nilIfBlank, original: profile.website),
            logoUrl: patch(logoUrl.nilIfBlank, original: profile.logoUrl),
            taxId: patch(taxId.nilIfBlank, original: profile.taxId)
        )
    }

    private func patch(_ value: String?, original: String?) -> String?? {
        value == original ? nil : .some(value)
    }
}

extension String {
    fileprivate var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    fileprivate var nilIfBlank: String? { trimmed.isEmpty ? nil : trimmed }
    fileprivate var isE164: Bool {
        range(of: #"^\+[1-9][0-9]{7,14}$"#, options: .regularExpression) != nil
    }
    fileprivate var isHTTPURL: Bool {
        guard let components = URLComponents(string: self),
            let scheme = components.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else { return false }
        return components.host?.isEmpty == false
    }
}
