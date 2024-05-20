//
//  ContentView.swift
//  MultipeerConnectivity_Otus
//
//  Created by Илья Кузнецов on 16.05.2024.
//

import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var multipeerManager = MultipeerManager()
    @State private var message: String = ""
    
    var body: some View {
        VStack {
            
            List(multipeerManager.messages, id: \.0.id) { (msg, sender) in
                HStack {
                    if sender.message == "Я" {
                        Spacer()
                        Text("\(sender.message): \(msg.message)")
                            .padding(10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Text("\(sender.message): \(msg.message)")
                            .padding(10)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        Spacer()
                    }
                }
            }
            
            HStack {
                TextField("Введите сообщение", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        multipeerManager.send(message: message)
                        message = ""
                    }
                
                Button(action: {
                    multipeerManager.send(message: message)
                    message = ""
                }) {
                    Image(systemName: "paperplane.fill")
                }
                .padding()
            }
            
            
            
            VStack {
                HStack {
                    Text(multipeerManager.connectedPeers.count > 0 ? "Статус: Подключено ✅" : "Статус: Подключение... ⏳")
                        .padding()
                }
                Button("Переподключиться") {
                    multipeerManager.resetSession()
                }
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .padding()
    }
}


