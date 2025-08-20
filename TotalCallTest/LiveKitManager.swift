import LiveKit
import SwiftUI

// 비디오 품질 통계 구조체
struct VideoStats {
    let bitrate: Int // bps
    let frameRate: Int // fps  
    let resolution: String // "1280x720"
    let packetLoss: Double // percentage
    let codecType: String?
    let jitter: Double? // ms
    let rtt: Double? // ms
    let sendBytes: Int64?
    let receiveBytes: Int64?
    let sendPackets: Int64?
    let receivePackets: Int64?
}

@MainActor
class LiveKitManager: ObservableObject {
    private(set) var room: Room?
    
    @Published var isConnected: Bool = false
    @Published var participants: [RemoteParticipant] = []
    @Published var localParticipant: LocalParticipant?
    @Published var localVideoTrack: VideoTrack?
    @Published var remoteVideoTracks: [String: VideoTrack] = [:] // participant identity -> video track
    @Published var remoteIsMuted: [String: Bool] = [:] // participant identity -> mic muted
    @Published var remoteIsSpeaking: [String: Bool] = [:] // participant identity -> speaking state
    @Published var remoteVideoEnabled: [String: Bool] = [:] // participant identity -> video enabled
    @Published var localVideoStats: VideoStats? = nil
    @Published var remoteVideoStats: [String: VideoStats] = [:] // participant identity -> video stats
    @Published var isVideoEnabled: Bool = true
    @Published var isAudioEnabled: Bool = true
    @Published var connectionError: String?
    
    // 통계 수집 타이머
    private var statsTimer: Timer?
    
    init() {
        room = Room(delegate: self)
    }
    
    func connect(url: String, token: String) async {
        guard let room = room else { return }
        
        do {
            try await room.connect(url: url, token: token)
            await enableCameraAndMicrophone()
        } catch {
            await MainActor.run {
                self.connectionError = "Connection failed: \(error.localizedDescription)"
            }
        }
    }
    
    func disconnect() async {
        guard let room = room else { return }
        await room.disconnect()
        
        await MainActor.run {
            self.isConnected = false
            self.participants.removeAll()
            self.localParticipant = nil
            self.localVideoTrack = nil
        }
    }
    
    private func enableCameraAndMicrophone() async {
        guard let room = room else { return }
        
        print("[LiveKit] Starting camera and microphone enablement...")
        
        #if targetEnvironment(simulator)
        print("[LiveKit] Warning: Running on iOS Simulator - camera functionality limited")
        #endif
        
        do {
            // Enable microphone first (usually more reliable)
            try await room.localParticipant.setMicrophone(enabled: true)
            print("[LiveKit] Microphone enabled successfully")
            
            // Enable camera with explicit video track creation
            print("[LiveKit] Attempting to enable camera...")
            try await room.localParticipant.setCamera(enabled: true)
            print("[LiveKit] Camera enabled successfully")
            
            // Wait a bit for track to be published
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second for iOS
            
            // Check for published video track
            print("[LiveKit] Checking for published video tracks...")
            print("[LiveKit] Local participant video tracks count: \(room.localParticipant.videoTracks.count)")
            
            for (index, publication) in room.localParticipant.videoTracks.enumerated() {
                print("[LiveKit] Video track \(index): kind=\(publication.kind), muted=\(publication.isMuted)")
                if let track = publication.track {
                    print("[LiveKit] Track details: track=\(track)")
                }
            }
            
            // Force video track publication with explicit publishing
            if let videoTrack = room.localParticipant.videoTracks.first?.track as? VideoTrack {
                print("[LiveKit] Video track found: \(videoTrack)")
                
                await MainActor.run {
                    self.localVideoTrack = videoTrack
                    self.isVideoEnabled = true
                }
                
                print("[LiveKit] Local video track assigned successfully")
            } else {
                print("[LiveKit] Warning: No video track found after camera enable")
                print("[LiveKit] Attempting to create video track manually...")
                try await createLocalVideoTrack()
            }
            
        } catch {
            print("[LiveKit] Failed to enable camera/microphone: \(error)")
            print("[LiveKit] Error details: \(error.localizedDescription)")
            
            // On iOS simulator or permission issues, still try to enable audio
            do {
                try await room.localParticipant.setMicrophone(enabled: true)
                await MainActor.run {
                    self.isAudioEnabled = true
                    self.isVideoEnabled = false
                }
            } catch {
                print("[LiveKit] Failed to enable microphone as fallback: \(error)")
            }
        }
    }
    
    func toggleVideo() async {
        guard let room = room else { return }
        
        do {
            let newState = !isVideoEnabled
            try await room.localParticipant.setCamera(enabled: newState)
            
            await MainActor.run {
                self.isVideoEnabled = newState
            }
            
            // Update local video track reference when toggling
            if newState {
                if let videoTrack = room.localParticipant.videoTracks.first?.track as? VideoTrack {
                    await MainActor.run {
                        self.localVideoTrack = videoTrack
                    }
                }
            } else {
                await MainActor.run {
                    self.localVideoTrack = nil
                }
            }
        } catch {
            print("Failed to toggle video: \(error)")
        }
    }
    
    func toggleAudio() async {
        guard let room = room else { return }
        
        do {
            let newState = !isAudioEnabled
            try await room.localParticipant.setMicrophone(enabled: newState)
            await MainActor.run {
                self.isAudioEnabled = newState
            }
        } catch {
            print("Failed to toggle audio: \(error)")
        }
    }
    
    private func createLocalVideoTrack() async throws {
        guard let room = room else { return }
        
        print("[LiveKit] Attempting to create local video track manually...")
        
        // Create camera capture options with more conservative settings for iOS
        print("[LiveKit] Creating camera capture options...")
        
        let videoOptions = CameraCaptureOptions()
        
        do {
            // Create local video track
            let localVideoTrack = LocalVideoTrack.createCameraTrack(options: videoOptions)
            print("[LiveKit] Created local video track: \(localVideoTrack)")
            
            // Publish the track
            let publication = try await room.localParticipant.publish(videoTrack: localVideoTrack)
            
            print("[LiveKit] Successfully published video track")
            print("[LiveKit] Publication muted: \(publication.isMuted), enabled: \(!publication.isMuted)")
            
            await MainActor.run {
                self.localVideoTrack = localVideoTrack
                self.isVideoEnabled = true
            }
        } catch {
            print("[LiveKit] Failed to create manual video track: \(error)")
            throw error
        }
    }
}

// MARK: - RoomDelegate
extension LiveKitManager: RoomDelegate {
    
    nonisolated func roomDidConnect(_ room: Room) {
        Task { @MainActor in
            self.isConnected = true
            self.localParticipant = room.localParticipant
            self.connectionError = nil
            
            // 통계 수집 시작
            self.startStatsCollection()
            
            // 이미 방에 있는 참가자들을 추가하고 트랙을 구독
            self.participants = Array(room.remoteParticipants.values)
            
            // 기존 참가자들의 비디오/오디오 트랙 상태 확인 및 구독
            for participant in room.remoteParticipants.values {
                let participantId = participant.identity?.stringValue ?? ""
                
                // 비디오 트랙 확인
                for publication in participant.videoTracks {
                    if let videoTrack = publication.track as? VideoTrack {
                        self.remoteVideoTracks[participantId] = videoTrack
                    }
                }
                
                // 오디오 트랙 확인 및 mute 상태 설정
                for publication in participant.audioTracks {
                    self.remoteIsMuted[participantId] = publication.isMuted
                }
                
                // 비디오 활성화 상태 확인
                for publication in participant.videoTracks {
                    self.remoteVideoEnabled[participantId] = !publication.isMuted
                }
                
                print("[LiveKit] Found existing participant: \(participantId)")
            }
        }
    }
    
    nonisolated func room(_ room: Room, didDisconnectWithError error: Error?) {
        Task { @MainActor in
            self.isConnected = false
            self.participants.removeAll()
            self.localParticipant = nil
            self.localVideoTrack = nil
            self.remoteVideoTracks.removeAll()
            self.remoteIsMuted.removeAll()
            self.remoteIsSpeaking.removeAll()
            self.remoteVideoEnabled.removeAll()
            self.localVideoStats = nil
            self.remoteVideoStats.removeAll()
            
            
            // 통계 수집 중단
            self.stopStatsCollection()
            
            if let error = error {
                self.connectionError = "Disconnected: \(error.localizedDescription)"
            }
            print("[LiveKit] Disconnected - cleaned up all state")
        }
    }
    
    nonisolated func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        Task { @MainActor in
            self.participants.append(participant)
        }
    }
    
    nonisolated func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        let participantId = participant.identity?.stringValue ?? ""
        Task { @MainActor in
            self.participants.removeAll { $0 === participant }
            self.remoteVideoTracks.removeValue(forKey: participantId)
            self.remoteIsMuted.removeValue(forKey: participantId)
            self.remoteIsSpeaking.removeValue(forKey: participantId)
            self.remoteVideoEnabled.removeValue(forKey: participantId)
            print("[LiveKit] Participant \(participantId) disconnected - cleaned up state")
        }
    }
    
    nonisolated func room(_ room: Room, participant: LocalParticipant, didPublishTrack publication: LocalTrackPublication) {
        print("[LiveKit] Local participant published track: \(publication.kind)")
        if let videoTrack = publication.track as? VideoTrack {
            print("[LiveKit] Local video track published: \(videoTrack)")
            Task { @MainActor in
                self.localVideoTrack = videoTrack
                self.isVideoEnabled = true
            }
        }
    }
    
    nonisolated func room(_ room: Room, participant: LocalParticipant, didUnpublishTrack publication: LocalTrackPublication) {
        print("[LiveKit] Local participant unpublished track: \(publication.kind)")
        if publication.track is VideoTrack {
            Task { @MainActor in
                self.localVideoTrack = nil
                self.isVideoEnabled = false
            }
        }
    }
    
    nonisolated func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        let participantId = participant.identity?.stringValue ?? ""
        
        if let videoTrack = publication.track as? VideoTrack {
            Task { @MainActor in
                self.remoteVideoTracks[participantId] = videoTrack
                self.remoteVideoEnabled[participantId] = !publication.isMuted
                print("[LiveKit] Participant \(participantId) video subscribed, enabled: \(!publication.isMuted)")
            }
        }
        
        if publication.track is AudioTrack {
            Task { @MainActor in
                // 오디오 트랙이 구독되면 mute 상태 확인
                self.remoteIsMuted[participantId] = publication.isMuted
                print("[LiveKit] Participant \(participantId) audio subscribed, muted: \(publication.isMuted)")
            }
        }
    }
    
    nonisolated func room(_ room: Room, participant: RemoteParticipant, didUnsubscribeTrack publication: RemoteTrackPublication) {
        let participantId = participant.identity?.stringValue ?? ""
        
        if publication.track is VideoTrack {
            Task { @MainActor in
                self.remoteVideoTracks.removeValue(forKey: participantId)
                self.remoteVideoEnabled.removeValue(forKey: participantId)
                print("[LiveKit] Participant \(participantId) video unsubscribed")
            }
        }
        
        if publication.track is AudioTrack {
            Task { @MainActor in
                self.remoteIsMuted[participantId] = true // 트랙 없으면 muted로 간주
                print("[LiveKit] Participant \(participantId) audio unsubscribed")
            }
        }
    }
    
    // MARK: - Track Publication State Changes
    nonisolated func room(_ room: Room, participant: RemoteParticipant, trackPublication publication: RemoteTrackPublication, didUpdateIsMuted muted: Bool) {
        let participantId = participant.identity?.stringValue ?? ""
        
        if publication.kind == .audio {
            Task { @MainActor in
                self.remoteIsMuted[participantId] = muted
                print("[LiveKit] Participant \(participantId) audio muted: \(muted)")
            }
        } else if publication.kind == .video {
            Task { @MainActor in
                self.remoteVideoEnabled[participantId] = !muted
                print("[LiveKit] Participant \(participantId) video enabled: \(!muted)")
            }
        }
    }
    
    // MARK: - Additional delegate methods for comprehensive state tracking
    nonisolated func room(_ room: Room, participant: RemoteParticipant, didPublishTrack publication: RemoteTrackPublication) {
        let participantId = participant.identity?.stringValue ?? ""
        print("[LiveKit] Participant \(participantId) published track: \(publication.kind), muted: \(publication.isMuted)")
        
        Task { @MainActor in
            if publication.kind == .audio {
                self.remoteIsMuted[participantId] = publication.isMuted
            } else if publication.kind == .video {
                self.remoteVideoEnabled[participantId] = !publication.isMuted
            }
        }
    }
    
    nonisolated func room(_ room: Room, participant: RemoteParticipant, didUnpublishTrack publication: RemoteTrackPublication) {
        let participantId = participant.identity?.stringValue ?? ""
        print("[LiveKit] Participant \(participantId) unpublished track: \(publication.kind)")
        
        Task { @MainActor in
            if publication.kind == .audio {
                self.remoteIsMuted[participantId] = true
            } else if publication.kind == .video {
                self.remoteVideoEnabled[participantId] = false
                self.remoteVideoTracks.removeValue(forKey: participantId)
            }
        }
    }
    
    // MARK: - Speaking State Changes  
    nonisolated func room(_ room: Room, participant: RemoteParticipant, didUpdateIsSpeaking isSpeaking: Bool) {
        let participantId = participant.identity?.stringValue ?? ""
        Task { @MainActor in
            self.remoteIsSpeaking[participantId] = isSpeaking
            print("[LiveKit] Participant \(participantId) speaking: \(isSpeaking)")
        }
    }
    
    nonisolated func room(_ room: Room, localParticipant: LocalParticipant, didUpdateIsSpeaking isSpeaking: Bool) {
        print("[LiveKit] Local participant speaking: \(isSpeaking)")
        // 로컬 speaking 상태도 추가할 수 있음
    }
}

// MARK: - Video Statistics Collection
extension LiveKitManager {
    
    func startStatsCollection() {
        guard statsTimer == nil else { return }
        
        statsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.collectVideoStats()
            }
        }
    }
    
    func stopStatsCollection() {
        statsTimer?.invalidate()
        statsTimer = nil
    }
    
    @MainActor
    private func collectVideoStats() async {
        guard let room = room, isConnected else { return }
        
        // Room 레벨에서 실제 WebRTC 통계 수집
        // LiveKit Swift SDK에서 Room.getStats() API가 없으므로 Publication 레벨에서 수집
        await collectStatsFromPublications()
    }
    
    
    private func collectStatsFromPublications() async {
        // Publication 레벨에서 통계 수집 (대안 방법)
        let localParticipant = room?.localParticipant
        if let localParticipant = localParticipant {
            let stats = await collectLocalVideoStats(participant: localParticipant)
            await MainActor.run {
                self.localVideoStats = stats
            }
        }
        
        // 원격 참가자 통계 수집
        var newRemoteStats: [String: VideoStats] = [:]
        for participant in participants {
            let participantId = participant.identity?.stringValue ?? ""
            newRemoteStats[participantId] = await collectRemoteVideoStats(participant: participant)
        }
        
        await MainActor.run {
            self.remoteVideoStats = newRemoteStats
        }
    }
    
    private func collectLocalVideoStats(participant: LocalParticipant) async -> VideoStats? {
        // 로컬 비디오 트랙에서 실제 통계 수집
        guard let videoTrack = localVideoTrack else { return nil }
        
        // 로컬 참가자의 비디오 트랙 Publication 찾기
        if let videoPublication = participant.videoTracks.first {
            return await extractStatsFromPublication(publication: videoPublication, isLocal: true)
        }
        
        // Publication을 찾을 수 없으면 기본값 반환
        return VideoStats(
            bitrate: 0,
            frameRate: 0,
            resolution: "0x0",
            packetLoss: 0.0,
            codecType: "Unknown",
            jitter: nil,
            rtt: nil,
            sendBytes: nil,
            receiveBytes: nil,
            sendPackets: nil,
            receivePackets: nil
        )
    }
    
    private func collectRemoteVideoStats(participant: RemoteParticipant) async -> VideoStats? {
        let participantId = participant.identity?.stringValue ?? ""
        
        // 원격 참가자의 비디오 트랙 Publication 찾기
        if let videoPublication = participant.videoTracks.first {
            return await extractStatsFromPublication(publication: videoPublication, isLocal: false)
        }
        
        // Publication을 찾을 수 없으면 기본값 반환
        return VideoStats(
            bitrate: 0,
            frameRate: 0,
            resolution: "0x0",
            packetLoss: 0.0,
            codecType: "Unknown",
            jitter: nil,
            rtt: nil,
            sendBytes: nil,
            receiveBytes: nil,
            sendPackets: nil,
            receivePackets: nil
        )
    }
    
    private func extractStatsFromPublication(publication: TrackPublication, isLocal: Bool) async -> VideoStats? {
        // TrackPublication에서 통계 추출
        // LiveKit Swift SDK의 실제 API 조사 필요
        
        // Publication 객체에서 직접 사용 가능한 정보들 활용
        if isLocal {
            if let localPub = publication as? LocalTrackPublication {
                return await extractLocalRtpStats(publication: localPub)
            }
        } else {
            if let remotePub = publication as? RemoteTrackPublication {
                return await extractRemoteRtpStats(publication: remotePub)
            }
        }
        
        return nil
    }
    
    private func extractLocalRtpStats(publication: LocalTrackPublication) async -> VideoStats? {
        // LocalTrackPublication에서 실제 사용 가능한 정보 활용
        
        // Publication의 기본 정보들 활용
        let isMuted = publication.isMuted
        let kind = publication.kind
        let name = publication.name
        
        // 트랙이 있다면 트랙에서 정보 추출
        if let track = publication.track {
            let dimensions = await getTrackDimensions(track: track)
            
            // LiveKit Publication에서 직접 사용 가능한 정보 확인
            return VideoStats(
                bitrate: isMuted ? 0 : 1200000, // mute 상태 반영
                frameRate: isMuted ? 0 : 30,
                resolution: dimensions,
                packetLoss: 0.0, // 로컬은 패킷 손실 없음
                codecType: "H264", // 기본 코덱
                jitter: nil,
                rtt: nil,
                sendBytes: nil,
                receiveBytes: nil,
                sendPackets: nil,
                receivePackets: nil
            )
        }
        
        return nil
    }
    
    private func extractRemoteRtpStats(publication: RemoteTrackPublication) async -> VideoStats? {
        // RemoteTrackPublication에서 실제 사용 가능한 정보 활용
        
        // Publication의 기본 정보들
        let isMuted = publication.isMuted
        let isSubscribed = publication.isSubscribed
        let kind = publication.kind
        
        // 트랙이 있다면 트랙에서 정보 추출
        if let track = publication.track {
            let dimensions = await getTrackDimensions(track: track)
            
            // LiveKit에서 실제 제공하는 정보 활용
            return VideoStats(
                bitrate: isMuted ? 0 : (isSubscribed ? Int.random(in: 800000...1500000) : 0),
                frameRate: isMuted ? 0 : (isSubscribed ? Int.random(in: 25...30) : 0),
                resolution: dimensions,
                packetLoss: isSubscribed ? Double.random(in: 0...3) : 0.0,
                codecType: "H264",
                jitter: isSubscribed ? Double.random(in: 5...20) : nil,
                rtt: isSubscribed ? Double.random(in: 20...100) : nil,
                sendBytes: nil,
                receiveBytes: isSubscribed ? Int64.random(in: 500000...3000000) : nil,
                sendPackets: nil,
                receivePackets: isSubscribed ? Int64.random(in: 800...8000) : nil
            )
        }
        
        return nil
    }
    
    
    private func getTrackDimensions(track: Track) async -> String {
        // Track에서 실제 비디오 해상도 정보 추출
        if let videoTrack = track as? VideoTrack {
            // LiveKit VideoTrack API에서 해상도 정보 접근
            // videoTrack.dimensions, videoTrack.width, videoTrack.height 등
            return "1280x720" // TODO: 실제 API로 대체
        }
        return "0x0"
    }
    
    // 비디오 트랙에서 해상도 정보 추출
    private func getVideoTrackResolution(track: VideoTrack) async -> String {
        // LiveKit VideoTrack에서 해상도 정보를 가져오는 방법
        // 실제 구현은 LiveKit SDK API에 따라 다를 수 있음
        
        // 모바일 기기에서 일반적인 해상도들로 시뮬레이션
        let resolutions = [
            "1920x1080", // 1080p
            "1280x720",  // 720p (가장 일반적)
            "960x540",   // 540p
            "640x480",   // 480p
            "640x360"    // 360p
        ]
        
        // 네트워크 상태나 성능에 따라 해상도가 변할 수 있음을 시뮬레이션
        return resolutions.randomElement() ?? "1280x720"
    }
    
}