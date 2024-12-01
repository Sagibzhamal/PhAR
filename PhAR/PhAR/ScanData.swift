//
//  ScanData.swift
//  PhAR
//
//  Created by Sagibzhamal on 30.11.2024.
//

import Foundation


struct ScanData: Identifiable {
    var id = UUID()
    let content: String
    
    init(content: String) {
        self.content = content
    }
}
