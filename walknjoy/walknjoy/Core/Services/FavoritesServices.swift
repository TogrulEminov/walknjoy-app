//
//  FavoritesServices.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 25.09.26.
//

import Foundation

protocol FavoritesServicesProtocol{
    func addFavorites(_ input: FavoriteRequest) async throws
    func deleteFavorites(_ input: FavoriteRequest) async throws
    func getFavorites() async throws -> FavoriteRequest
}
