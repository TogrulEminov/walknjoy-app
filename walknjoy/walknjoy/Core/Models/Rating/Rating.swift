//
//  Rating.swift
//  walknjoy
//

import Foundation

struct Rating: Decodable, Hashable {
    let average: Double?
    let count: Int

    init(average: Double?, count: Int) {
        self.average = average
        self.count = count
    }
}
