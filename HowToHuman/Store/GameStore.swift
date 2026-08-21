//
//  GameStore.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//

import Combine
import Foundation
import SwiftUI
import Network

enum AppState: Codable {
    case home
    case howToPlay
    case lobbySearch
    case customizeAlien
    case lobby
    case transition
    case askHuman
    case answerAlien
    case narrateExperience
    case reviewExperience
    case voting
}

enum GamePhase: Codable {
    case none
    case askHuman
    case answerAlien
    case narrateExperience
    case reviewExperience
    case voting
}

@MainActor
final class GameStore: ObservableObject {
    let networkManager: NetworkManager
    
    @Published var state: AppState = .home
    @Published var phase: GamePhase = .none
    
    @Published var currRoom: Room?
    @Published var joiningRoom: DiscoveredRoom?
    @Published var availableRooms: [DiscoveredRoom] = []
    @Published var currentConnections: [UUID: NWConnection] = [:]
    @Published var connectionToHost: NWConnection?
    
    @Published var showExitRoomPopUp: Bool = false
    @Published var showRoomFullPopUp: Bool = false
    @Published var showSettingPopUp: Bool = false
    @Published var showKickPlayerPopUp: Bool = false
    @Published var playerGameDataList: [PlayerGameData] = []
    @Published var voteResult: Float?
    
    @Published var myGameData: PlayerGameData
    @Published var receivedGameData: PlayerGameData?
    @Published var bubbles: [Bubble] = []
    
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    init() {
        networkManager = NetworkManager()
        
        myGameData = PlayerGameData(
            id: networkManager.myPeerId,
            question: nil,
            answer: "The human didn't respond",
            experience: "Contact lost",
            vote: nil
        )
        
        networkManager.onJoinRequest = { [weak self] request, connection in
            
            Task { @MainActor in
                self?.handleJoinRequest(
                    request,
                    connection: connection
                )
            }
        }
        networkManager.onJoinResponse = { [weak self] response, connection in
            Task { @MainActor in
                self?.handleJoinResponse(
                    response,
                    connection: connection
                )
            }
        }
        networkManager.onLeaveRequest = { [weak self] leavingPlayer, connection in
            Task { @MainActor in
                self?.handleLeaveRequest(
                    leavingPlayer,
                    connection: connection
                )
            }
        }
        networkManager.onReceiveSharedData = { [weak self] sharedData, connection in
            Task { @MainActor in
                self?.handleSharedData(
                    sharedData,
                    connection: connection
                )
            }
        }
        networkManager.onReceivePlayerGameData = { [weak self] gameData, connection in
            Task { @MainActor in
                self?.handlePlayerGameData(
                    gameData,
                    connection: connection
                )
            }
        }
        
        networkManager.onReceiveReaction = { [weak self] bubble, connection in
            Task { @MainActor in
                self?.handleReaction(
                    bubble,
                    connection: connection
                )
            }
        }
    }
    
    func startBrowsing() {
        networkManager.startBrowsing(){rooms in
            self.availableRooms = rooms
        }
    }
    
    func startOrStopListening(stop: Bool = false) {
        
        for con in currentConnections.values{
            startOrStopListeningToOne(on: con, stop: stop)
        }
        if connectionToHost != nil{
            startOrStopListeningToOne(on: connectionToHost!, stop: stop)
        }

    }
    
    func startOrStopListeningToOne(on connection: NWConnection, stop: Bool) {
        if stop {
            connection.cancel()
        }
        else{
            networkManager.startListening(on: connection)
        }
    }
    
    func handleJoinRequest(_ request: JoinRequest, connection: NWConnection)  {
        print("Handling Join Request")
        // kl ketemu player yg sama persis jg jgn accept lagi, mending update ui si player itu aja
        if currRoom!.players.count >= currRoom!.maxPlayers{
            do{
                let data = try JSONEncoder().encode(JoinResponse.roomFull)
                let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .joinResponse, data: data))
                
                networkManager.send(data: envelopedData, over: connection, errMsg: "Send join response failed")
                
            }catch {
                print("Encoding failed: ", error)
            }
            return
        }
        else if currRoom!.players.contains(where: { $0.id == request.player.id }) == true{
            do{
                let data = try JSONEncoder().encode(JoinResponse.readmitted)
                let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .joinResponse, data: data))
                
                networkManager.send(data: envelopedData, over: connection, errMsg: "Send join response failed")
                
            }catch {
                print("Encoding failed: ", error)
            }
            return
        }

        currRoom!.players.append(request.player)

        do{
            let data = try JSONEncoder().encode(JoinResponse.accepted)
            let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .joinResponse, data: data))
            networkManager.send(data: envelopedData, over: connection, errMsg: "Send join response failed")
            
        }catch {
            print("Encoding failed: ", error)
        }
        
        // host store connection
        currentConnections[request.player.id] = connection
        
        print("Start listening to newly connected player")
        startOrStopListeningToOne(on: connection, stop: false)
        // send game data
        sendDataToPlayers()
    }
    
    func handleJoinResponse(_ response: JoinResponse, connection: NWConnection){
        print("Handling Join Response")
        switch response {
        case .accepted:
            connectionToHost = connection
            print("Start listening to host")
            startOrStopListeningToOne(on: connectionToHost!, stop: false)
            state = .lobby
        case .roomFull:
            showRoomFullPopUp = true
            state = .lobbySearch
        case .readmitted:
            state = .lobby
        case .kicked:
            clearGame()
        }
        
    
    }
    
    func handleLeaveRequest(_ leavingPlayer: LeavingPlayer, connection: NWConnection){
        // delete game if still in asking phase
        print("Handling Player Leave Request")
        if phase == .askHuman {
            playerGameDataList.removeAll(where: { $0.id == leavingPlayer.id })
        }
        currRoom!.removePlayer(id: leavingPlayer.id)
        startOrStopListeningToOne(on: connection, stop: true)
        currentConnections.removeValue(forKey: leavingPlayer.id)
        sendDataToPlayers()
    }
    
    func handleSharedData(_ sharedData: SharedGameData, connection: NWConnection){
        print("Handling Received Shared Data")
        self.currRoom = sharedData.room
        if phase != sharedData.gamePhase {//changed phase
            self.phase = sharedData.gamePhase
            self.state = .transition
        }
        if state != sharedData.gameState {//changed state
            self.state = sharedData.gameState
        }
        print("Migrate host: ", sharedData.migrateHost)
        print("New host? ", sharedData.room.hostID == networkManager.myPeerId)
        if sharedData.migrateHost == true && currRoom!.hostID == networkManager.myPeerId {
            print("Stop connection with previous host")
            connection.cancel() // cancel the connection with previous host
            connectionToHost = nil
            print("Receive hostship, begin advertising")
            networkManager.startAdvertising(room: currRoom!)
        }
        if sharedData.connectToNewHost{
            networkManager.startBrowsing(){rooms in
                self.availableRooms = rooms
                for r in self.availableRooms{
                    if r.hostID == sharedData.room.hostID{// found connection advertised by the new host
                        print("Found new host")
                        self.networkManager.stopBrowsing()
                        print("Stop connection with previous host")
                        connection.cancel() // cancel the connection with previous host
                        self.connectionToHost = nil
                        let player = sharedData.room.players.first(where: { $0.id == self.networkManager.myPeerId })!
                        self.networkManager.join(room: r, player: player)
                        
                        break
                    }
                }
            }
        }
        if sharedData.assignedQuestionPlayerId != nil{
            receivedGameData = sharedData.playerGameDataList.first(where: {$0.id == sharedData.assignedQuestionPlayerId})
        }
        self.playerGameDataList = sharedData.playerGameDataList
        self.voteResult = sharedData.voteResult
    }
    
    func handlePlayerGameData(_ gameData: PlayerGameData, connection: NWConnection){
        if let index = playerGameDataList.firstIndex(where: { $0.id == gameData.id }) {
            playerGameDataList[index] = PlayerGameData(
                id: gameData.id,
                question: gameData.question,
                answer: gameData.answer,
                experience: gameData.experience,
                vote: gameData.vote
            )
        }
    }
    
     
    func handleReaction(_ bubble: Bubble, connection: NWConnection){
        showReaction(bubble, store: self)
        if currRoom?.hostID == networkManager.myPeerId{
            sendReaction(bubble: bubble)
        }
    }
    
    func sendReaction(bubble: Bubble){
        let bubbleEncoded = try! JSONEncoder().encode(bubble)
        let envelopedData = try! JSONEncoder().encode(MessageEnvelope(type: .reaction, data: bubbleEncoded))
        if currRoom?.hostID != networkManager.myPeerId{// if player, send to host
            networkManager.send(data: envelopedData, over: connectionToHost!, errMsg: "Send reaction failed")
        }
        else{// if host, send to everyone
            for (playerID, con) in currentConnections{
                guard playerID != bubble.sender else { continue }
                networkManager.send(data: envelopedData, over: con, errMsg: "Send reaction failed")
            }
        }
    }
    
    func sendDataToOnePlayer(on connection: NWConnection, voteResult: Float? = nil, migrateHost: Bool = false, connectToNewHost: Bool = false){
        let sharedData = SharedGameData(
            gamePhase: phase, gameState: state, room: currRoom!, playerGameDataList: playerGameDataList, migrateHost: migrateHost, connectToNewHost: connectToNewHost
        )
        do{
            let data = try JSONEncoder().encode(sharedData)
            let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .sharedGameData, data: data))
            networkManager.send(data: envelopedData, over: connection, errMsg: "Send shared data to one player failed"){
                if migrateHost{
                    self.clearGame() // clear all connections, hopefully all transfer to new host messages have been sent to the players
                }
            }
        }catch {
            print("Encoding failed: ", error)
        }
    }
    
    func sendDataToPlayers(voteResult: Float? = nil, migrateHost: Bool = false, connectToNewHost: Bool = false, questionAssignmentList: [UUID:UUID]? = nil){
        
        for (playerId, con) in currentConnections { // send updated shared data to all players
            var sharedData = SharedGameData(
                gamePhase: phase, gameState: state, room: currRoom!, playerGameDataList: playerGameDataList, migrateHost: migrateHost, connectToNewHost: connectToNewHost
            )
            if questionAssignmentList != nil {
                sharedData.assignedQuestionPlayerId = questionAssignmentList?[playerId]
            }
            do{
                let data = try JSONEncoder().encode(sharedData)
                let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .sharedGameData, data: data))
                networkManager.send(data: envelopedData, over: con, errMsg: "Send shared data failed")
            }catch {
                print("Encoding failed: ", error)
            }
        }
    }
    
    func sendToHost(data: PlayerGameData){
        do{
            let data = try JSONEncoder().encode(data)
            let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .playerGameData, data: data))
            networkManager.send(data: envelopedData, over: connectionToHost!, errMsg: "Send player game data failed")
        }catch {
            print("Encoding failed: ", error)
        }
    }
    
    func clearGame(){
        self.currRoom = nil
        self.state = .lobbySearch
        self.joiningRoom = nil
        self.currentConnections.removeAll()
        self.showSettingPopUp = false
        self.showExitRoomPopUp = false
        self.showRoomFullPopUp = false
        self.phase = .none
        self.playerGameDataList.removeAll()
        self.availableRooms.removeAll()
        connectionToHost?.cancel()
        self.connectionToHost = nil
        self.voteResult = nil
        self.myGameData.answer = nil
        self.myGameData.question = nil
        self.myGameData.experience = nil
        self.myGameData.vote = nil
        self.receivedGameData = nil
        networkManager.stop()
    }
    
    func disconnectGracefully(){
        // 1. Request extra background execution time from iOS
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "GameDisconnect") {
            self.endBackgroundTask()
        }
        
        if connectionToHost == nil{
            leaveRoomAsHost(){ [weak self] in
                self?.endBackgroundTask()
            }
        }
        else{
            guard let connection = connectionToHost else {
                endBackgroundTask()
                return
            }
            
            leaveRoomAsParticipant(on: connection){ [weak self] in
                self?.endBackgroundTask()
            }
        }
                
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    func leaveRoomAsHost(completion: (() -> Void)? = nil){
        // delete player's game data if still in asking phase
        if phase == .askHuman {
            playerGameDataList.removeAll(where: { $0.id == networkManager.myPeerId })
        }
        
        currRoom?.changeHost()
        
        print("Send data to other players to start browsing for the new host")
        for (playerID, conn) in currentConnections{
            guard playerID != currRoom!.hostID else { continue }
            sendDataToOnePlayer(on: conn, connectToNewHost: true)
        }
        
        print("Send data to new host")
        sendDataToOnePlayer(on: currentConnections[currRoom!.hostID]!, migrateHost: true)
        completion?()
    }
    
    func leaveRoomAsParticipant(on connection: NWConnection, completion: @escaping () -> Void){
        sendLeaveRoomMsg(on: connection)
        completion()
    }
    
    func sendLeaveRoomMsg(on connection: NWConnection) {
        do{
            let player = LeavingPlayer(id: networkManager.myPeerId)
            let data = try JSONEncoder().encode(player)
            let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .leaveNotice, data: data))
            
            networkManager.send(data: envelopedData, over: connection, errMsg: "Send leave room message failed")
        }catch{
            print("Encoding failed:", error)
        }
    }
    
    func kickPlayer(_ player: Player){
        do{
            let data = try JSONEncoder().encode(JoinResponse.kicked)
            let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .joinResponse, data: data))
            
            networkManager.send(data: envelopedData, over: currentConnections[player.id]!, errMsg: "Send kick player action failed")
            
        }catch {
            print("Encoding failed: ", error)
        }
        currRoom?.players.removeAll() { $0.id == player.id }
        currentConnections.removeValue(forKey: player.id)
        sendDataToPlayers()
    }
    
    func assignQuestions(){
        var assignmentList: [UUID: UUID] = [:]
        for (i, gameData) in playerGameDataList.enumerated(){
            if i < playerGameDataList.count - 1 {
                assignmentList[gameData.id] = playerGameDataList[i+1].id
            }
            else if i == currRoom!.players.count - 1 {
                assignmentList[gameData.id] = playerGameDataList[0].id
            }
        }
        sendDataToPlayers(questionAssignmentList: assignmentList)
    }
}
