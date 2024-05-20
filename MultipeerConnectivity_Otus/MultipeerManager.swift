//
//  MultipeerManager.swift
//  MultipeerConnectivity_Otus
//
//  Created by Илья Кузнецов on 17.05.2024.
//

import SwiftUI
import MultipeerConnectivity

class MultipeerManager: NSObject, ObservableObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    private let serviceType = "test-service"
    
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser
    private var browser: MCNearbyServiceBrowser
    
    @Published var messages: [(MessageModel, MessageModel)] = []
    @Published var connectedPeers: [MCPeerID] = []
    
    override init() {
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        super.init()
        
        self.session.delegate = self
        self.advertiser.delegate = self
        self.browser.delegate = self
        
        startServices()
    }
    
    func startServices() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
    
    func resetSession() {
        self.session.disconnect()
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        self.session.delegate = self
        print("Сброшена сессия для peerID: \(myPeerId.displayName)")
    }
    
    func send(message: String) {
        guard !session.connectedPeers.isEmpty else {
            print("Нет подключенных пиров для отправки сообщения")
            return
        }
        
        if let data = message.data(using: .utf8) {
            do {
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
                DispatchQueue.main.async {
                    self.messages.append((MessageModel(message: message), MessageModel(message: "Я")))
                }
                print("Сообщение отправлено: \(message)")
            } catch {
                print("Ошибка при отправке сообщения: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - MCSessionDelegate
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("Подключено к \(peerID.displayName)")
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
            case .connecting:
                print("Подключено к \(peerID.displayName)")
            case .notConnected:
                print("Не подключено к \(peerID.displayName)")
                if let index = self.connectedPeers.firstIndex(of: peerID) {
                    self.connectedPeers.remove(at: index)
                }
                if peerID != self.myPeerId {
                    print("Попытка переподключения к \(peerID.displayName)")
                    self.browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
                }
            @unknown default:
                print("Неизвестное состояние подключения к \(peerID.displayName)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.messages.append((MessageModel(message: message), MessageModel(message: peerID.displayName)))
            }
            print("Получено сообщение от \(peerID.displayName): \(message)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    // MARK: - MCNearbyServiceAdvertiserDelegate
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Advertising не запущен: \(error.localizedDescription)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Получено приглашение от \(peerID.displayName)")
        invitationHandler(true, session)
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Browsing не запущен: \(error.localizedDescription)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Найден пир: \(peerID.displayName)")
        if !session.connectedPeers.contains(peerID) && peerID != myPeerId {
            print("Приглашаю пир: \(peerID.displayName)")
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Пир потерян: \(peerID.displayName)")
    }
}



