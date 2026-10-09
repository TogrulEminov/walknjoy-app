//
//  HomeViewModel.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 28.09.26.
//

import Foundation
import Observation


@Observable
@MainActor
final class HomeViewModel {
    private let listingServices: ListingServicesProtocol
    private let categoryServices: CategoryServicesProtocol
    private let discoveryServices: DiscoveryServicesProtocol

    static var makeDefault: () -> HomeViewModel = { HomeViewModel() }

    var state: LoadState<HomeContent> = .idle
    private var locale = "az"
    private var generation = UUID()

    func load(locale: String) async {
        if self.locale != locale {
            self.locale = locale
            state = .idle
        }
        await load()
    }

    init(
        listingService: ListingServicesProtocol? = nil,
        categoryService: CategoryServicesProtocol? = nil,
        discoveryService: DiscoveryServicesProtocol? = nil
    ) {
        self.listingServices = listingService ?? ListingServices()
        self.categoryServices = categoryService ?? CategoryServices()
        self.discoveryServices = discoveryService ?? DiscoveryServices()
    }

    func load() async {
        guard state == .idle else {
            return
        }
        state = .loading
        await loadListings()
    }

    func refresh() async {
        let keepCurrentContent: Bool
        if case .loaded = state {
            keepCurrentContent = true
        } else {
            state = .loading
            keepCurrentContent = false
        }
        await loadListings(keepCurrentContentOnError: keepCurrentContent)
    }

    private func loadListings(keepCurrentContentOnError: Bool = false) async {
        generation = UUID()
        let request = generation
        do {
            async let stayRequest = listingServices.getListings(
                query: makeQuery(for: .stay)
            )
            async let toursRequest = listingServices.getListings(
                query: makeQuery(for: .tour)
            )
            async let activityRequestRequest = listingServices.getListings(
                query: makeQuery(for: .activity)
            )
            async let experiencesRequest = listingServices.getListings(
                query: makeQuery(for: .experience)
            )
            async let categoriesRequest = categoryServices.getCategories()
            async let citiesRequest = discoveryServices.getCities()

            let (
                staysResponse, toursResponse, activitiesResponse,
                experiencesResponse, categoriesResponse, citiesResponse
            ) = try await (
                stayRequest, toursRequest, activityRequestRequest,
                experiencesRequest, categoriesRequest, citiesRequest
            )

            let content = HomeContent(
                cities: citiesResponse,
                categories: categoriesResponse,
                stays: staysResponse,
                tours: toursResponse,
                activities: activitiesResponse,
                experiences: experiencesResponse
            )
            try Task.checkCancellation()
            guard generation == request else { return }
            state = .loaded(content)
        } catch {
            guard generation == request else { return }
            if error is CancellationError { state = .idle; return }
            if !keepCurrentContentOnError {
                state = .error(error.localizedDescription)
            }
        }
    }
}
extension HomeViewModel {
    func makeQuery(
        for type: ListingType
    ) -> ListingQuery {
        ListingQuery(
            locale: locale,
            type: type,
            page: 1,
            limit: 6
        )
    }
}
