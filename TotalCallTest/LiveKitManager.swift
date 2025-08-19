import LiveKit
import SwiftUI

class LiveKitManager: ObservableObject {
    private(set) var room: Room?
    
    @Published var isConnected: Bool = false
    @Published var participants: [RemoteParticipant] = []
    @Published var localParticipant: LocalParticipant?
    @Published var localVideoTrack: VideoTrack?
    @Published var remoteVideoTracks: [String: VideoTrack] = [:] // participant identity -> video track
    @Published var isVideoEnabled: Bool = true
    @Published var isAudioEnabled: Bool = true
    @Published var connectionError: String?
    
    init() {
        room = Room(delegate: self)
    }
    
    func connect(url: String, token: String) async {
        guard let room = room else { return }
        
        do {
            try await room.connect(url: url, token: token)
            await enableCameraAndMicrophone()
        } catch {
            DispatchQueue.main.async {
                self.connectionError = "Connection failed: \(error.localizedDescription)"
            }
        }
    }
    
    func disconnect() async {
        guard let room = room else { return }
        await room.disconnect()
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.participants.removeAll()
            self.localParticipant = nil
            self.localVideoTrack = nil
        }
    }
    
    private func enableCameraAndMicrophone() async {
        guard let room = room else { return }
        
        do {
            // Enable camera
            try await room.localParticipant.setCamera(enabled: true)
            // Enable microphone  
            try await room.localParticipant.setMicrophone(enabled: true)
        } catch {
            print("Failed to enable camera/microphone: \(error)")
        }
    }
    
    func toggleVideo() async {
        guard let room = room else { return }
        
        do {
            let newState = !isVideoEnabled
            try await room.localParticipant.setCamera(enabled: newState)
            DispatchQueue.main.async {
                self.isVideoEnabled = newState
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
            DispatchQueue.main.async {
                self.isAudioEnabled = newState
            }
        } catch {
            print("Failed to toggle audio: \(error)")
        }
    }
}

// MARK: - RoomDelegate
extension LiveKitManager: RoomDelegate {
    
    func roomDidConnect(_ room: Room) {
        DispatchQueue.main.async {
            self.isConnected = true
            self.localParticipant = room.localParticipant
            self.connectionError = nil
        }
    }
    
    func room(_ room: Room, didDisconnectWithError error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.participants.removeAll()
            self.localParticipant = nil
            self.localVideoTrack = nil
            self.remoteVideoTracks.removeAll()
            
            if let error = error {
                self.connectionError = "Disconnected: \(error.localizedDescription)"
            }
        }
    }
    
    func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        DispatchQueue.main.async {
            self.participants.append(participant)
        }
    }
    
    func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        DispatchQueue.main.async {
            self.participants.removeAll { $0 === participant }
            self.remoteVideoTracks.removeValue(forKey: participant.identity?.stringValue ?? "")
        }
    }
    
    func room(_ room: Room, participant: LocalParticipant, didPublishTrack publication: LocalTrackPublication) {
        if let videoTrack = publication.track as? VideoTrack {
            DispatchQueue.main.async {
                self.localVideoTrack = videoTrack
            }
        }
    }
    
    func room(_ room: Room, participant: LocalParticipant, didUnpublishTrack publication: LocalTrackPublication) {
        if publication.track is VideoTrack {
            DispatchQueue.main.async {
                self.localVideoTrack = nil
            }
        }
    }
    
    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        if let videoTrack = publication.track as? VideoTrack {
            DispatchQueue.main.async {
                self.remoteVideoTracks[participant.identity?.stringValue ?? ""] = videoTrack
            }
        }
    }
    
    func room(_ room: Room, participant: RemoteParticipant, didUnsubscribeTrack publication: RemoteTrackPublication) {
        if publication.track is VideoTrack {
            DispatchQueue.main.async {
                self.remoteVideoTracks.removeValue(forKey: participant.identity?.stringValue ?? "")
            }
        }
    }
}