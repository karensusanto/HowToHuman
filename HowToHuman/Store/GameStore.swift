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
import AVFoundation
import AudioToolbox


@MainActor
final class GameStore: ObservableObject {
    let networkManager: NetworkManager
    let motionManager: MotionManager
    
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
    
    @Published var myPlayerData: Player
    @Published var myGameData: PlayerGameData
    @Published var receivedGameData: PlayerGameData?
    @Published var bubbles: [Bubble] = []
    
    @Published var readyPlayers: Int = 0
    @Published var submittedQuestions: Int = 0

    @Published var currentExperienceIndex: Int = 0
    @Published var experienceRevealed: Bool = false
    
    private var soundPlayer: AVAudioPlayer?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    init(motionManager: MotionManager) {
        self.networkManager = NetworkManager()
        self.motionManager = motionManager
        self.impactGenerator.prepare()
        
        myGameData = PlayerGameData(
            id: networkManager.myPeerId,
            question: nil,
            answer: nil,
            experience: nil,
            vote: nil
        )
        
        myPlayerData = Player(id: networkManager.myPeerId, name: "", avatar: "spaceship-yellow")
        
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
        
        networkManager.onReceiveReady = { [weak self] readiness in
            Task { @MainActor in
                self?.handleReadiness(readiness: readiness)
            }
        }

        networkManager.onReceiveVote = { [weak self] voteData in
            Task { @MainActor in
                self?.handleVote(voteData)
            }
        }

        networkManager.onReceiveReturnToLobby = { [weak self] in
            Task { @MainActor in
                // any player can trigger this independently, so more than one return-to-lobby
                // request can arrive after the first already moved state past .result - ignore
                // the duplicates instead of letting next() race through several more phases unattended
                guard self?.state == .result else { return }
                self?.next()
            }
        }
    }
    
    func initAudioPlayer(sound: String) {
        guard let url = Bundle.main.url(forResource: sound, withExtension: "mp3") else { return }
        print("init audio player")
        soundPlayer = try? AVAudioPlayer(contentsOf: url)
        soundPlayer?.prepareToPlay()
    }
    func initChimeAudioPlayer() {
        guard let url = Bundle.main.url(forResource: "chime", withExtension: "mp3") else { return }
        print("init audio player")
        soundPlayer = try? AVAudioPlayer(contentsOf: url)
        soundPlayer?.prepareToPlay()
    }
    func playChime() {
        soundPlayer?.currentTime = 0
        soundPlayer?.play()
    }
    func vibrate(){
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    func join(){
        networkManager.join(room: joiningRoom!, player: myPlayerData)
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
    
    func handleReadiness(readiness: String){
        if readiness == "Ready" {
            readyPlayers += 1
        }
        else{
            readyPlayers -= 1
        }
        // ReadyButton only appears on askHuman/answerAlien/narrateExperience - a "Ready" message
        // delayed by network latency can arrive after the host already moved past that phase
        // (e.g. its own timer fired first), and would otherwise trigger an unrelated next() call
        guard [GamePhase.askHuman, .answerAlien, .narrateExperience].contains(phase) else { return }
        if readyPlayers == currRoom!.inGamePlayers.count{
            next()
        }
    }

    // host-only: records one player's vote and, once everyone who's still in the room has voted, resolves it
    func handleVote(_ voteData: PlayerGameData){
        if let index = playerGameDataList.firstIndex(where: { $0.id == voteData.id }) {
            playerGameDataList[index].vote = voteData.vote
        }
        checkVotingComplete()
    }

    private var castVotes: [Float] {
        playerGameDataList.filter { data in currRoom?.inGamePlayers.contains(where: { $0.id == data.id }) == true }.compactMap(\.vote)
    }

    func checkVotingComplete(){
        if castVotes.count >= currRoom?.inGamePlayers.count ?? 0 {
            resolveVote()
        } else {
            shareGameData() // keep everyone's "X/Y voted" progress live
        }
    }

    // host-only: tallies votes cast so far (non-voters excluded) as a yes-fraction, 0.5 exactly is a tie
    func resolveVote(){
        let yesCount = castVotes.filter { $0 == 1.0 }.count
        let result: Float = castVotes.isEmpty ? 0.5 : Float(yesCount) / Float(castVotes.count)
        next(voteResult: result)
    }

    func next(voteResult: Float? = nil, questionAssignmentList: [UUID:UUID]? = nil){
        print("next")
        //only move to next phase after transition is done or when game started
        if state == AppState.lobby {// game is starting
            currRoom?.inGamePlayers = currRoom?.joinedPlayers ?? []
            currRoom?.isPlaying = true
        }
        // .result is an interstitial state like the transitionTo* screens, not a genuine phase
        // advance - the real advance for the next round happens below when .lobby -> transitionToAskHuman
        // fires. Without this exclusion, phase runs permanently one step ahead of state for the
        // rest of the game: it eventually wraps to .none while state is mid-round, and TransitionScreen
        // renders phase .none as an empty instructions list - a blank screen with just the exit button.
        if !AppState.transitions().contains(state) && state != .result {
            print("Phase before next: ", phase)
            phase = phase.next
        }
        if state == .transitionToShareExperience {
            currentExperienceIndex = 0
            experienceRevealed = false
        }
        if state == .result {
            // someone tapped to head back to the lobby: reset for a new round
            self.voteResult = nil
            currentExperienceIndex = 0
            experienceRevealed = false
            currRoom?.isPlaying = false
            currRoom?.inGamePlayers.removeAll()
            for index in playerGameDataList.indices {
                playerGameDataList[index].question = nil
                playerGameDataList[index].answer = nil
                playerGameDataList[index].experience = nil
                playerGameDataList[index].vote = nil
            }
            myGameData = playerGameDataList.first(where: { $0.id == myGameData.id }) ?? myGameData
            receivedGameData = nil
            submittedQuestions = 0
        }
        state = state.next
        readyPlayers = 0
        print("next() -> phase:", phase, "state:", state, "inGamePlayers:", currRoom?.inGamePlayers.count ?? -1)
        shareGameData(voteResult: voteResult, questionAssignmentList: questionAssignmentList)
    }

    // host-only: reveals the current player's narrated experience after the steps recap
    func revealExperience(){
        experienceRevealed = true
        shareGameData()
    }

    // host-only: moves on to the next player's experience, or into voting once everyone's been shown
    func advanceExperience(){
        print("advanceExperience() currentExperienceIndex:", currentExperienceIndex, "playerGameDataList.count:", playerGameDataList.count, "inGamePlayers.count:", currRoom?.inGamePlayers.count ?? -1)
        if currentExperienceIndex < playerGameDataList.count - 1{
            currentExperienceIndex += 1
            experienceRevealed = false
            shareGameData()
        }
        else{
            next()
        }
    }
    
    func handleJoinRequest(_ request: JoinRequest, connection: NWConnection)  {
        print("Handling Join Request")
        
        // kl ketemu player yg sama persis jg jgn accept lagi, mending update ui si player itu aja
        if currRoom!.joinedPlayers.contains(where: { $0.id == request.player.id }) == true{
            do{
                let data = try JSONEncoder().encode(JoinResponse.readmitted)
                let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .joinResponse, data: data))
                
                networkManager.send(data: envelopedData, over: connection, errMsg: "Send join response failed")
                
            }catch {
                print("Encoding failed: ", error)
            }
            return
        }
        else if currRoom!.joinedPlayers.count >= currRoom!.maxPlayers{
            do{
                let data = try JSONEncoder().encode(JoinResponse.roomFull)
                let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .joinResponse, data: data))
                
                networkManager.send(data: envelopedData, over: connection, errMsg: "Send join response failed")
                
            }catch {
                print("Encoding failed: ", error)
            }
            return
        }

        currRoom!.joinedPlayers.append(request.player)
        playerGameDataList.append(PlayerGameData(id: request.player.id))

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
        networkManager.updateRoomAdvertisement(room: currRoom!)
        // send game data
        shareGameData()
    }
    
    func handleJoinResponse(_ response: JoinResponse, connection: NWConnection){
        print("Handling Join Response")
        switch response {
        case .accepted:
            connectionToHost = connection
            print("Start listening to host")
            startOrStopListeningToOne(on: connectionToHost!, stop: false)
            joiningRoom = nil
            state = .lobby
        case .roomFull:
            showRoomFullPopUp = true
            state = .lobbySearch
        case .readmitted:
            state = .lobby
        case .kicked:
            clearGame(stopAdvertising: true)
        }
        
    
    }
    
    func handleLeaveRequest(_ leavingPlayer: Player, connection: NWConnection){
        // delete game if still in asking phase
        print("Handling Player Leave Request")
        if phase == .askHuman {
            playerGameDataList.removeAll(where: { $0.id == leavingPlayer.id })
        }
        currRoom!.removePlayer(id: leavingPlayer.id)
        startOrStopListeningToOne(on: connection, stop: true)
        currentConnections.removeValue(forKey: leavingPlayer.id)
        
        if currRoom?.inGamePlayers.count == 1 && phase != .none{ // game started, only host left in the game
            clearGame(stopAdvertising: false)
        }
        networkManager.updateRoomAdvertisement(room: currRoom!)
        shareGameData()
    }
    
    func handleSharedData(_ sharedData: SharedGameData, connection: NWConnection){
        print("Handling Received Shared Data - incoming phase:", sharedData.gamePhase, "state:", sharedData.gameState, "| local phase:", phase, "state:", state)
        self.currRoom = sharedData.room
        if phase != sharedData.gamePhase {//changed phase
            self.phase = sharedData.gamePhase
            if self.state != sharedData.gameState {self.state = state.next} //in case player already go to the next page first before host (players' timer are not in sync)
        }
        if state != sharedData.gameState {//changed state
            self.state = sharedData.gameState
        }
        print("Handling Received Shared Data - resolved phase:", phase, "state:", state)
        
        self.playerGameDataList = sharedData.playerGameDataList
        self.currentExperienceIndex = sharedData.currentExperienceIndex
        self.experienceRevealed = sharedData.experienceRevealed

        if let myAssignedID = sharedData.assignedQuestionPlayerId{
            print("Received question assignment")
            receivedGameData = playerGameDataList.first(where: { $0.id == myAssignedID})
        }
        
        self.myGameData = playerGameDataList.first(where: {$0.id == myGameData.id}) ?? myGameData
        self.voteResult = sharedData.voteResult
        
        print("Migrate host: ", sharedData.migrateHost)
        print("New host? ", sharedData.room.hostID == networkManager.myPeerId)
        if sharedData.migrateHost == true && currRoom!.hostID == networkManager.myPeerId {
            print("Stop connection with previous host")
            connection.cancel() // cancel the connection with previous host
            connectionToHost = nil
            
            if currRoom?.inGamePlayers.count == 1{// if hostship transfer happens in the middle of the game, leaving only the new host as the only player in the game
                clearGame(stopAdvertising: false, newHost: true) // game stopped, back to room's lobby as the new host
            }
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
                        self.networkManager.join(room: r, player: self.myPlayerData)
                        
                        break
                    }
                }
            }
        }
        
    }
    
    func handlePlayerGameData(_ gameData: PlayerGameData, connection: NWConnection){
        if let index = playerGameDataList.firstIndex(where: { $0.id == gameData.id }) {
            playerGameDataList[index] = gameData
            
            submittedQuestions += 1
        }
        
        // once all players submitted, shuffle questions so each player receive other player's game data
        startAssigningQuestions()
    }
    
    func startAssigningQuestions(){
        if submittedQuestions == currRoom?.inGamePlayers.count ?? 0 && receivedGameData == nil{
            let assignmentList = assignQuestions()
            if let myAssignedID = assignmentList[myPlayerData.id]{
                print("Host assigned a question")
                receivedGameData = playerGameDataList.first(where: { $0.id == myAssignedID})
            }
            shareGameData(voteResult: voteResult, questionAssignmentList: assignmentList)
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
            guard let connectionToHost else { return } // no host connection yet (e.g. mid host migration)
            networkManager.send(data: envelopedData, over: connectionToHost, errMsg: "Send reaction failed")
        }
        else{// if host, send to everyone
            let inGamePlayerIds = currRoom?.inGamePlayers.map(\.id) ?? []
            for (playerID, con) in currentConnections{
                guard playerID != bubble.sender else { continue }
                if inGamePlayerIds.contains(playerID) {networkManager.send(data: envelopedData, over: con, errMsg: "Send reaction failed")}
            }
        }
    }
    
    func sendDataToOnePlayer(on connection: NWConnection, migrateHost: Bool = false, connectToNewHost: Bool = false, playerId: UUID){
        
        let inGamePlayerIds = currRoom?.inGamePlayers.map(\.id) ?? []
        var sharedData = SharedGameData(
            gamePhase: .none, gameState: .lobby, room: currRoom!, voteResult: self.voteResult, playerGameDataList: playerGameDataList, migrateHost: migrateHost, connectToNewHost: connectToNewHost, currentExperienceIndex: currentExperienceIndex, experienceRevealed: experienceRevealed
        )
        if inGamePlayerIds.contains(playerId){
            sharedData.gamePhase = phase
            sharedData.gameState = state
        }
        do{
            let data = try JSONEncoder().encode(sharedData)
            let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .sharedGameData, data: data))
            networkManager.send(data: envelopedData, over: connection, errMsg: "Send shared data to one player failed")
        }catch {
            print("Encoding failed: ", error)
        }
    }
    
    func shareGameData(voteResult: Float? = nil, migrateHost: Bool = false, connectToNewHost: Bool = false, questionAssignmentList: [UUID:UUID]? = nil){
        if let voteResult { self.voteResult = voteResult }

        //before sharing, make sure host's own game data is its most updated version
        //playergamedatalist has the most updated version of every player's data because it's the one that's always updated, due to it being the variable that will be shared to players
        myGameData = playerGameDataList.first(where: {$0.id == myGameData.id}) ?? myGameData
        
        let inGamePlayerIds = currRoom?.inGamePlayers.map(\.id) ?? []
        for (playerId, con) in currentConnections { // send updated shared data to all players
            var sharedData = SharedGameData(
                gamePhase: .none, gameState: .lobby, room: currRoom!, voteResult: self.voteResult, playerGameDataList: playerGameDataList, migrateHost: migrateHost, connectToNewHost: connectToNewHost, currentExperienceIndex: currentExperienceIndex, experienceRevealed: experienceRevealed
            )
            
            if inGamePlayerIds.contains(playerId){
                sharedData.gamePhase = phase
                sharedData.gameState = state
            }
            
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
    
    func submitGameData(data: PlayerGameData){
        print("submitting game data")
        if connectionToHost == nil{
            if let index = playerGameDataList.firstIndex(where: { $0.id == data.id }) {
                playerGameDataList[index] = data
                
                submittedQuestions += 1
            }
            
            startAssigningQuestions()
            
        }
        else{
            do{
                let data = try JSONEncoder().encode(data)
                let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .playerGameData, data: data))
                networkManager.send(data: envelopedData, over: connectionToHost!, errMsg: "Send player game data failed")
            }catch {
                print("Encoding failed: ", error)
            }
        }
    }
    
    func clearGame(stopAdvertising: Bool = true, newHost: Bool = false){
        
        if stopAdvertising {
            self.currRoom = nil
            self.state = .lobbySearch
            self.myPlayerData.name = ""
            self.myPlayerData.avatar = ""
        }
        else{
            self.state = .lobby
            self.currRoom?.isPlaying = false
            self.currRoom?.inGamePlayers.removeAll()
            if newHost{
                self.currRoom?.joinedPlayers.removeAll()
                self.currRoom?.joinedPlayers.append(myPlayerData)
            }
        }
        
        if !stopAdvertising && !newHost{
            self.currentConnections = self.currentConnections
        }
        else{
            self.currentConnections.removeAll()
        }
        self.joiningRoom = nil
        self.showSettingPopUp = false
        self.showExitRoomPopUp = false
        self.showRoomFullPopUp = false
        self.phase = .none
        self.playerGameDataList.removeAll()
        self.availableRooms.removeAll()
        connectionToHost?.cancel()
        self.connectionToHost = nil
        self.voteResult = nil
        self.myGameData.question = nil
        self.myGameData.answer = nil
        self.myGameData.experience = nil
        self.myGameData.vote = nil
        self.playerGameDataList.append(myGameData)
        self.receivedGameData = nil
        self.readyPlayers = 0
        self.submittedQuestions = 0
        self.currentExperienceIndex = 0
        self.experienceRevealed = false
        if stopAdvertising{
            networkManager.stop()
        }
    }
    
    func disconnectGracefully(){
        // 1. Request extra background execution time from iOS
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "GameDisconnect") {
            self.endBackgroundTask()
        }
        
        if connectionToHost == nil{
            leaveRoomAsHost(){ [weak self] in
                self?.clearGame()
                self?.state = .home
                self?.endBackgroundTask()
            }
        }
        else{
            guard let connection = connectionToHost else {
                endBackgroundTask()
                return
            }
            
            leaveRoomAsParticipant(on: connection){ [weak self] in
                self?.clearGame()
                self?.state = .home
                self?.endBackgroundTask()
            }
        }
                
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            motionManager.stopUpdates()
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
            sendDataToOnePlayer(on: conn, connectToNewHost: true, playerId: playerID)
        }
        
        print("Send data to new host")
        sendDataToOnePlayer(on: currentConnections[currRoom!.hostID]!, migrateHost: true, playerId: currRoom!.hostID)
        completion?()
    }
    
    func leaveRoomAsParticipant(on connection: NWConnection, completion: @escaping () -> Void){
        do{
            let player = myPlayerData
            let data = try JSONEncoder().encode(player)
            let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .leaveNotice, data: data))
            
            networkManager.send(data: envelopedData, over: connection, errMsg: "Send leave room message failed")
        }catch{
            print("Encoding failed:", error)
        }
        completion()
    }
    
    func kickPlayer(_ player: Player){
        do{
            let data = try JSONEncoder().encode(JoinResponse.kicked)
            let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .joinResponse, data: data))
            
            networkManager.send(data: envelopedData, over: currentConnections[player.id]!, errMsg: "Send kick player action failed")
            
        }catch {
            print("Encoding failed: ", error)
        }
        currRoom?.removePlayer(id: player.id)
        currentConnections.removeValue(forKey: player.id)
        shareGameData()
    }
    
    func sendReadyStatus(_ ready: Bool){
        if connectionToHost == nil{
            if ready {
                readyPlayers += 1
            }else{
                readyPlayers -= 1
            }
            
            if readyPlayers == currRoom!.inGamePlayers.count{
                next()
            }
        }
        else{
            do{
                let text = ready ? "Ready" : "Not Ready"
                let data = text.data(using: .utf8)!
                let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .readiness, data: data))
                
                networkManager.send(data: envelopedData, over: connectionToHost!, errMsg: "Send readiness status")
                
            }catch {
                print("Encoding failed: ", error)
            }
        }
    }

    func submitVote(yes: Bool){
        var data = myGameData
        data.vote = yes ? 1.0 : 0.0
        if connectionToHost == nil{
            handleVote(data)
        }
        else{
            do{
                let encoded = try JSONEncoder().encode(data)
                let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .vote, data: encoded))
                networkManager.send(data: envelopedData, over: connectionToHost!, errMsg: "Send vote failed")
            }catch {
                print("Encoding failed: ", error)
            }
        }
    }

    // any single player - host or participant, no consensus needed - sends the whole room back to the lobby
    func requestReturnToLobby(){
        if connectionToHost == nil{
            // guard mirrors onReceiveReturnToLobby's: the host's own tap can race with an
            // already-processed request from someone else
            guard state == .result else { return }
            next()
        }
        else{
            do{
                let data = "ReturnToLobby".data(using: .utf8)!
                let envelopedData = try JSONEncoder().encode(MessageEnvelope(type: .returnToLobby, data: data))
                networkManager.send(data: envelopedData, over: connectionToHost!, errMsg: "Send return-to-lobby request failed")
            }catch {
                print("Encoding failed: ", error)
            }
        }
    }

    func assignQuestions() -> [UUID: UUID]{
        var assignmentList: [UUID: UUID] = [:]
        let inGamePlayerIds = currRoom?.inGamePlayers.map(\.id) ?? []
        let filteredGameDataList = playerGameDataList.filter { gameData in
            inGamePlayerIds.contains(gameData.id)
        }
        for (i, gameData) in filteredGameDataList.enumerated(){
            if i < filteredGameDataList.count - 1 {
                assignmentList[gameData.id] = filteredGameDataList[i+1].id
            }
            else if i == filteredGameDataList.count - 1 {
                assignmentList[gameData.id] = filteredGameDataList[0].id
            }
        }
        return assignmentList
    }
}
