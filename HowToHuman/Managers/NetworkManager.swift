//
//  Listener.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 15/08/26.
//

import Network
import SwiftUI
import Combine


class NetworkManager: ObservableObject{
    private let serviceType = "_how-to-human._tcp"
    private var listener: NWListener? // advertising & listening
    private var browser: NWBrowser? // looking for advertised connection
    
    let myPeerId: UUID = UUID()

    var discoveredRooms: [String] = []
    
    var onJoinRequest: ((JoinRequest, NWConnection) -> Void)?
    
    var onJoinResponse: ((JoinResponse, NWConnection) -> Void)?
    var onReceiveSharedData: ((SharedGameData, NWConnection) -> Void)?
    var onLeaveRequest: ((LeavingPlayer, NWConnection) -> Void)?
    var onReceivePlayerGameData: ((PlayerGameData, NWConnection) -> Void)?
    var onReceiveReaction: ((Bubble, NWConnection) -> Void)?
    
    func startAdvertising(room : Room) {
        do {
            let parameters = NWParameters.tcp
            parameters.includePeerToPeer = true
            let listener = try NWListener(using: parameters)
            
            
            let metadata = [
                "roomID": room.id.uuidString,
                "hostID": room.hostID.uuidString,
                "hostAvatar": room.players.first!.avatar,
                "playerCount": "\(room.players.count)",
                "maxPlayers": "\(room.maxPlayers)"
            ]
            
            let txtRecord = NWTXTRecord(metadata)
            
            listener.service = NWListener.Service(
                name: room.roomName,
                type: self.serviceType,
                txtRecord: txtRecord
            )
            
            listener.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("Room is being advertised")

                case .failed(let error):
                    print("Host failed:", error)

                default:
                    break
                }
            }
            
            listener.newConnectionHandler = { connection in
                print("Someone joined the room")

                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        print("Guest connected")
                        print("Listening to new player")
                        self.startListening(on: connection)

                    case .failed(let error):
                        print("Connection failed:", error)

                    case .cancelled:
                        print("Guest disconnected")

                    default:
                        break
                    }
                }

                connection.start(queue: .main)
            }

            self.listener = listener
            listener.start(queue: .main)
            
        } catch {
            print("Failed to start listener: \(error)")
        }
        
    }
    
    func receive(on connection: NWConnection) {
        var type : MessageType = .none
        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: 4096
        ) { data, _, isComplete, error in
            print("📥 RECEIVED \(data?.count ?? 0) BYTES")
            print(String(data: data ?? Data(), encoding: .utf8) ?? "not UTF8")
            
            if data != nil{
                
                do{
                    let envelope = try JSONDecoder().decode(
                        MessageEnvelope.self,
                        from: data!
                    )
                    type = envelope.type
                    switch type {
                    case .joinRequest:
                        let request = try JSONDecoder().decode(
                            JoinRequest.self,
                            from: envelope.data
                        )
                        
                        self.onJoinRequest?(request, connection)
                        
                        print("Join request from:", request.player.id)
                        
                    case .joinResponse:
                        let response = try JSONDecoder().decode(
                            JoinResponse.self,
                            from: envelope.data
                        )
                        
                        print("Host responded:", response)
                        
                        switch response {
                        case .accepted:
                            print("🎉 Joined room!")
                            self.onJoinResponse?(.accepted, connection)
                            
                        case .roomFull:
                            print("❌ Room is full")
                            self.onJoinResponse?(.roomFull, connection)
                            connection.cancel()
                            
                        case .readmitted:
                            print("You have been admitted, updating UI")
                            self.onJoinResponse?(.readmitted, connection)
                            
                        case .kicked:
                            print("You have been kicked from the room")
                            self.onJoinResponse?(.readmitted, connection)
                        }
                        
                        
                        
                    case .leaveNotice:
                        print("Received player leave notice")
                        let player = try JSONDecoder().decode(
                            LeavingPlayer.self,
                            from: envelope.data
                        )
                        
                        self.onLeaveRequest?(player, connection)
                        
                    case .playerGameData:
                        print("Received player game data")
                        let gameData = try JSONDecoder().decode(
                            PlayerGameData.self,
                            from: envelope.data
                        )
                        
                        self.onReceivePlayerGameData?(gameData, connection)
                        
                    case .sharedGameData:
                        print("Received shared game data")
                        let sharedData = try JSONDecoder().decode(
                            SharedGameData.self,
                            from: envelope.data
                        )
                        
                        self.onReceiveSharedData?(sharedData, connection)
                    case .none:
                        print("Listening for data...")
                    case .reaction:
                        print("Received reaction")
                        let bubble = try JSONDecoder().decode(
                            Bubble.self,
                            from: envelope.data
                        )
                        
                        self.onReceiveReaction?(bubble, connection)
                    }
                    
                    
                }catch{
                    switch type {
                    case .joinRequest:
                        print("Failed to decode join request.")
                        connection.cancel()
                        
                    case .joinResponse:
                        print("Failed to decode join response.")
                        
                    case .leaveNotice:
                        print("Failed to decode player's leave notice.")
                        
                    case .playerGameData:
                        print("Failed to decode player's game data.")
                        
                    case .sharedGameData:
                        print("Failed to decode shared game data.")
                    case .none:
                        print("Listening for data...")
                    case .reaction:
                        print("Failed to decode reaction.")
                    }
                    
                }
                
            }
            
            if !isComplete && error == nil {
                self.receive(on: connection)
            }
        }
    }
    
    func startListening(on connection: NWConnection){
        receive(on: connection)
    }
    
    func send(data: Data, over connection: NWConnection, errMsg: String,
              completion: (() -> Void)? = nil){
        connection.send(
            content: data,
            completion: .contentProcessed { error in
                if let error {
                    print(errMsg, ":", error)
                }
                
                completion?()
            }
        )
    }
    
    
    func stop() {
        listener?.cancel()
        listener = nil
    }
    
    func startBrowsing(onRoomFound: @escaping ([DiscoveredRoom]) -> Void) {
        let browser = NWBrowser(for: .bonjourWithTXTRecord(type: self.serviceType, domain: nil), using: .tcp)
        
        browser.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Searching for rooms...")

            case .failed(let error):
                print("Browser failed:", error)

            default:
                break
            }
        }

        browser.browseResultsChangedHandler = { results, changes in
            var discoveredRooms : [DiscoveredRoom] = []
            for change in changes {
                print("Change: \(change)")
            }
            for result in results {
                guard case .service( // if result.endpoint is a bonjour service, extract name
                    let name,
                    _,
                    _,
                    _
                ) = result.endpoint else {
                    continue
                }
                print("Found room:", name)
                
                guard case .bonjour(let txtRecord) = result.metadata else {
                    continue
                }
                
                guard
                    let roomIDString = txtRecord["roomID"],
                    let roomID = UUID(uuidString: roomIDString)
                else {
                    continue
                }
                guard
                    let hostIDString = txtRecord["hostID"],
                    let hostID = UUID(uuidString: hostIDString)
                else {
                    continue
                }
                guard
                    let hostAvatar = txtRecord["hostAvatar"]
                else {
                    continue
                }
                guard
                    let playerCount = txtRecord["playerCount"]
                else {
                    continue
                }
                guard
                    let maxPlayers = txtRecord["maxPlayers"]
                else {
                    continue
                }
                print("room id:", roomIDString)
            
                let room = DiscoveredRoom(
                    id: roomID,
                    roomName: name,
                    roomEndpoint: result.endpoint,
                    hostID: hostID,
                    hostAvatar: hostAvatar,
                    playerCount: playerCount,
                    maxPlayers: maxPlayers
                )
                discoveredRooms.append(room)
                
            }
            onRoomFound(discoveredRooms)
        }

        self.browser = browser
        browser.start(queue: .main)
    }
    
    func stopBrowsing(){
        self.browser?.cancel()
        self.browser = nil
    }
    
    func join(room: DiscoveredRoom, player: Player) {
        let connection = NWConnection(
            to: room.roomEndpoint,
            using: .tcp
        )

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Sending connection request!")
                let request = JoinRequest(
                    player: player
                )

                do {
                    let data = try JSONEncoder().encode(request)
                    let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .joinRequest, data: data))
                    connection.send(
                        content: envelopedData,
                        completion: .contentProcessed { error in
                            if let error {
                                print("Send failed:", error)
                            }
                            
                            self.startListening(on: connection)
                        }
                    )
                } catch {
                    print("Encoding failed:", error)
                }

            case .failed(let error):
                print("Connection failed:", error)

            case .cancelled:
                print("Connection cancelled")

            default:
                break
            }
        }

        connection.start(queue: .main)
    }
    
}


