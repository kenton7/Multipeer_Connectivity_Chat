//
//  MessageModel.swift
//  MultipeerConnectivity_Otus
//
//  Created by Илья Кузнецов on 20.05.2024.
//

import Foundation

struct MessageModel: Identifiable {
    var id = UUID().uuidString
    var message: String
}
