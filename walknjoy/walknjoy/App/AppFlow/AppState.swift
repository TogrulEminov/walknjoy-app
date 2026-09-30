import Foundation
import Observation

@MainActor
@Observable

final class AppState {
    var flow: Flow = .splash {
        didSet {
            if flow == .main {
                notifications.startSession()
                if !isAppActive { notifications.suspend() }
            } else {
                notifications.endSession()
            }
        }
    }
    let notifications: NotificationViewModel
    private var isAppActive = true
    private(set) var canUseFavorites = false
    private(set) var favoriteOverrides: [String: Bool] = [:]
    private(set) var updatingFavoriteIDs: Set<String> = []
    private var favoriteSession = UUID()
    private let favoritesService = FavoritesServices()

    func loadFavoriteAccess() async {
        let session = favoriteSession
        do {
            let user = try await authService.me()
            guard session == favoriteSession else { return }
            canUseFavorites = user.role.uppercased() == "CUSTOMER"
        } catch {
            guard session == favoriteSession else { return }
            canUseFavorites = false
        }
    }

    func isFavorite(_ listing: PublicListing) -> Bool {
        favoriteOverrides[listing.id] ?? listing.isFavorite
    }

    func setFavorite(_ favorite: Bool, for listing: PublicListing) async throws
    {
        guard canUseFavorites, updatingFavoriteIDs.insert(listing.id).inserted
        else { return }
        let session = favoriteSession
        defer {
            if session == favoriteSession {
                updatingFavoriteIDs.remove(listing.id)
            }
        }
        let request = FavoriteRequest(listingId: listing.id)
        let response =
            try await
            (favorite
            ? favoritesService.addFavorites(request)
            : favoritesService.deleteFavorites(request))
        guard session == favoriteSession else { return }
        guard response.isFavorite == favorite else {
            throw NetworkError.invalidResponse
        }
        favoriteOverrides[listing.id] = response.isFavorite
    }

    var mode: Mode = .light
    private let authService: AuthServiceProtocol

    private var preferences: UserDefaultsServiceProtocol
    var language: AppLanguage

    init(
        preferences: UserDefaultsServiceProtocol,
        authService: AuthServiceProtocol? = nil
    ) {
        self.preferences = preferences
        self.authService = authService ?? AuthService()
        self.notifications = NotificationViewModel(auth: self.authService)

        self.mode = preferences.selectedMode
        self.language = preferences.selectedLanguage
        self.notifications.onSessionExpired = { [weak self] in
            self?.finishLogout()
        }
    }
    func setAppActive(_ active: Bool) {
        isAppActive = active
        guard flow == .main else { return }
        if active { notifications.resume() } else { notifications.suspend() }
    }

    func selectMode(_ mode: Mode) {
        self.mode = mode
        preferences.selectedMode = mode
    }
    func finishAuthentication() {
        flow = .main
    }
    func selectLanguage(_ language: AppLanguage) {
        self.language = language
        preferences.selectedLanguage = language
    }
    func finishLogout() {
        favoriteSession = UUID()
        canUseFavorites = false
        favoriteOverrides = [:]
        updatingFavoriteIDs = []
        flow = .auth
    }
    func start() async {
        try? await Task.sleep(for: .seconds(1.5))

        guard preferences.hasSeenOnboarding else {
            flow = .onboarding
            return
        }

        do {
            try await authService.restoreSession()

            flow = .main

        } catch {
            flow = .auth
        }
    }

    func finishOnboarding() {
        flow = .languageSelection
    }

    func finishLanguageSelection() {
        preferences.selectedLanguage = language
        preferences.hasSeenOnboarding = true
        flow = .auth
    }
}
