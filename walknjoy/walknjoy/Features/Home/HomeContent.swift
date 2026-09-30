//
//  HomeContent.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 28.09.26.
//

struct HomeContent: Equatable {
    let cities: [ListingCity]
    let categories: [CategoryModel]
    let stays: [ListingResponse]
    let tours: [ListingResponse]
    let activities: [ListingResponse]
    let experiences: [ListingResponse]
}
