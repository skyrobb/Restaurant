//
//  Order.swift
//  Restaurant
//
//  Created by Skyler Robbins on 1/9/25.
//

import Foundation

struct Order: Codable {
    var menuItems: [MenuItem]
    
    init(menuItems: [MenuItem] = []) {
        self.menuItems = menuItems
    }
}
