//
//  ProfileStats.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 24.09.26.
//
import Foundation

nonisolated struct ProfileStats: Decodable, Equatable {
    let bookings: Int
    let favorites: Int
    let reviews: Int
}
