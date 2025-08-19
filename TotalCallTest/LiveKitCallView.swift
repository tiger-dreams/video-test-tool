import SwiftUI
import LiveKit

struct LiveKitCallView: View {
    @ObservedObject var liveKitManager: LiveKitManager
    let roomURL: String
    let token: String
    @Binding var isPresented: Bool
    
    @State private var isConnecting = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Video container (always includes local, plus up to first 3 remotes = max 4 tiles)
                let remoteList = Array(liveKitManager.participants.prefix(max(0, 4 - 1)))
                let tileIds: [String] = ["local"] + remoteList.compactMap { $0.identity?.stringValue }
                let tilesCount = tileIds.count
                let columns: [GridItem] = {
                    switch tilesCount {
                    case 1:
                        return [GridItem(.flexible())]
                    case 2:
                        return [GridItem(.flexible()), GridItem(.flexible())]
                    default: // 3 or 4
                        return [GridItem(.flexible()), GridItem(.flexible())]
                    }
                }()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(tileIds, id: \.self) { id in
                            Group {
                                if id == "local" {
                                    LocalParticipantView(videoTrack: liveKitManager.localVideoTrack)
                                } else {
                                    let participant = liveKitManager.participants.first { $0.identity?.stringValue == id }
                                    let name = participant?.identity?.stringValue ?? id
                                    RemoteParticipantView(
                                        displayName: name,
                                        videoTrack: liveKitManager.remoteVideoTracks[id]
                                    )
                                }
                            }
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Control buttons
                HStack(spacing: 40) {
                    // Audio toggle
                    Button(action: {
                        Task {
                            await liveKitManager.toggleAudio()
                        }
                    }) {
                        Image(systemName: liveKitManager.isAudioEnabled ? "mic.fill" : "mic.slash.fill")
                            .font(.title)
                            .foregroundColor(liveKitManager.isAudioEnabled ? .white : .red)
                            .frame(width: 60, height: 60)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    // End call
                    Button(action: {
                        Task {
                            await liveKitManager.disconnect()
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "phone.down.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    
                    // Video toggle
                    Button(action: {
                        Task {
                            await liveKitManager.toggleVideo()
                        }
                    }) {
                        Image(systemName: liveKitManager.isVideoEnabled ? "video.fill" : "video.slash.fill")
                            .font(.title)
                            .foregroundColor(liveKitManager.isVideoEnabled ? .white : .red)
                            .frame(width: 60, height: 60)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 50)
            }
            
            // Connection status
            if !liveKitManager.isConnected && isConnecting {
                VStack {
                    ProgressView()
                        .scaleEffect(2)
                        .tint(.white)
                    Text("Connecting...")
                        .foregroundColor(.white)
                        .font(.title2)
                        .padding(.top)
                }
            }
            
            // Error message
            if let error = liveKitManager.connectionError {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                        .font(.title2)
                        .padding(.top)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .onAppear {
            isConnecting = true
            Task {
                await liveKitManager.connect(url: roomURL, token: token)
                isConnecting = false
            }
        }
        .onDisappear {
            Task {
                await liveKitManager.disconnect()
            }
        }
    }
}

struct RemoteParticipantView: View {
    let displayName: String
    let videoTrack: VideoTrack?
    
    var body: some View {
        ZStack {
            if let track = videoTrack {
                LiveKitVideoView(track: track)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .overlay(
                        VStack {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            Text(displayName.isEmpty ? "Unknown" : displayName)
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    )
            }
        }
    }
}

struct LocalParticipantView: View {
    let videoTrack: VideoTrack?
    
    var body: some View {
        ZStack {
            if let track = videoTrack {
                LiveKitVideoView(track: track)
            } else {
                Rectangle()
                    .fill(Color.blue.opacity(0.5))
                    .overlay(
                        VStack {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                            Text("You")
                                .foregroundColor(.white)
                                .font(.caption2)
                        }
                    )
            }
        }
    }
}

#Preview {
    LiveKitCallView(
        liveKitManager: LiveKitManager(),
        roomURL: "wss://your-livekit-server.com",
        token: "your-token",
        isPresented: .constant(true)
    )
}