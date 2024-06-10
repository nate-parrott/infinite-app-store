//
//  String.swift
//  InfiniteAppStore
//
//  Created by nate parrott on 6/8/24.
//

import Foundation

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
