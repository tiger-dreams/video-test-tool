import SwiftUI
import LiveKit

struct LiveKitCallView: View {
    @ObservedObject var liveKitManager: LiveKitManager
    let roomURL: String
    let token: String
    @Binding var isPresented: Bool
    let showVideoStats: Bool
    
    @State private var isConnecting = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Dynamic tile layout (1..4). Always include local first.
                let remoteList = Array(liveKitManager.participants.prefix(3))
                let tileIds: [String] = ["local"] + remoteList.compactMap { $0.identity?.stringValue }
                let tilesCount = tileIds.count

                GeometryReader { geo in
                    let spacing: CGFloat = 8
                    let fullW = geo.size.width
                    let fullH = geo.size.height

                    switch tilesCount {
                    case 1:
                        // Single: local fills entire area
                        tileView(id: "local")
                            .frame(width: fullW, height: fullH)
                    case 2:
                        // Two: vertical split (top/bottom)
                        VStack(spacing: spacing) {
                            tileView(id: "local")
                            tileView(id: tileIds[1])
                        }
                        .frame(width: fullW, height: fullH)
                    case 3:
                        // Three: local on top (full width), two remotes bottom split
                        VStack(spacing: spacing) {
                            tileView(id: "local")
                                .frame(height: (fullH - spacing) * 0.5)
                            HStack(spacing: spacing) {
                                tileView(id: tileIds[1])
                                tileView(id: tileIds[2])
                            }
                        }
                        .frame(width: fullW, height: fullH)
                    default:
                        // Four (or more capped to 4): 2x2 grid, local at top-left
                        let id2 = tileIds.count > 1 ? tileIds[1] : nil
                        let id3 = tileIds.count > 2 ? tileIds[2] : nil
                        let id4 = tileIds.count > 3 ? tileIds[3] : nil
                        VStack(spacing: spacing) {
                            HStack(spacing: spacing) {
                                tileView(id: "local")
                                if let id2 = id2 { tileView(id: id2) }
                            }
                            HStack(spacing: spacing) {
                                if let id3 = id3 { tileView(id: id3) }
                                if let id4 = id4 { tileView(id: id4) }
                            }
                        }
                        .frame(width: fullW, height: fullH)
                    }
                }
                .padding(8)

                Spacer(minLength: 12)
                
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

    // MARK: - Tile Factory
    @ViewBuilder
    private func tileView(id: String) -> some View {
        if id == "local" {
            let displayName = liveKitManager.localParticipant?.identity?.stringValue ?? "Me"
            LocalParticipantView(
                displayName: displayName,
                videoTrack: liveKitManager.isVideoEnabled ? liveKitManager.localVideoTrack : nil,
                isMuted: !liveKitManager.isAudioEnabled,
                isSpeaking: false, // TODO: wire local speaking state if available
                videoStats: showVideoStats ? liveKitManager.localVideoStats : nil
            )
            .aspectRatio(16/9, contentMode: .fit)
        } else {
            let participant = liveKitManager.participants.first { $0.identity?.stringValue == id }
            let name = participant?.identity?.stringValue ?? id
            let muted = liveKitManager.remoteIsMuted[id] ?? false
            let speaking = liveKitManager.remoteIsSpeaking[id] ?? false
            let videoEnabled = liveKitManager.remoteVideoEnabled[id] ?? true
            RemoteParticipantView(
                displayName: name,
                videoTrack: videoEnabled ? liveKitManager.remoteVideoTracks[id] : nil,
                isMuted: muted,
                isSpeaking: speaking,
                videoStats: showVideoStats ? liveKitManager.remoteVideoStats[id] : nil
            )
            .aspectRatio(16/9, contentMode: .fit)
        }
    }
}

struct RemoteParticipantView: View {
    let displayName: String
    let videoTrack: VideoTrack?
    let isMuted: Bool
    let isSpeaking: Bool
    let videoStats: VideoStats?
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let track = videoTrack {
                #if os(iOS)
                LiveKitVideoView(track: track)
                #else
                // macOS placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text("Video Track: \(track.name ?? "Unknown")")
                            .foregroundColor(.white)
                    )
                #endif
            } else {
                // 비디오 off 상태: 암전 + 기본 아이콘
                Rectangle()
                    .fill(Color.black)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(displayName.isEmpty ? "Unknown" : displayName)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                            
                            Text("Camera Off")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                // 비디오 품질 정보 오버레이
                if let stats = videoStats {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("📊 수신 통계")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.yellow)
                            
                            HStack {
                                Text("해상도:")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.8))
                                Text(stats.resolution)
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.cyan)
                            }
                            
                            HStack {
                                Text("FPS:")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.8))
                                Text("\(stats.frameRate)")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.cyan)
                            }
                            
                            HStack {
                                Text("비트레이트:")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.8))
                                Text("\(stats.bitrate/1000)k")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("손실률:")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.8))
                                Text("\(stats.packetLoss, specifier: "%.1f")%")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(stats.packetLoss > 5 ? .red : .green)
                            }
                            
                            if let codec = stats.codecType {
                                HStack {
                                    Text("코덱:")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text(codec)
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(.purple)
                                }
                            }
                            
                            if let rtt = stats.rtt {
                                HStack {
                                    Text("RTT:")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("\(Int(rtt))ms")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            if let jitter = stats.jitter {
                                HStack {
                                    Text("Jitter:")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("\(jitter, specifier: "%.1f")ms")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                    .padding(4)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(4)
                    .padding(.bottom, 4)
                }
                
                // Name & mic overlay
                HStack(spacing: 6) {
                    if isMuted {
                        Image(systemName: "mic.slash.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    } else {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.white.opacity(0.9))
                            .font(.caption)
                    }
                    Text(displayName.isEmpty ? "Unknown" : displayName)
                        .foregroundColor(.white)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.35))
                .clipShape(Capsule())
            }
            .padding(8)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSpeaking ? Color.green : Color.clear, lineWidth: 3)
        )
        .cornerRadius(10)
        .clipped()
    }
}

struct LocalParticipantView: View {
    let displayName: String
    let videoTrack: VideoTrack?
    let isMuted: Bool
    let isSpeaking: Bool
    let videoStats: VideoStats?
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let track = videoTrack {
                #if os(iOS)
                LiveKitVideoView(track: track)
                #else
                // macOS placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text("Video Track: \(track.name ?? "Unknown")")
                            .foregroundColor(.white)
                    )
                #endif
            } else {
                // 로컬 비디오 off 상태: 암전 + 기본 아이콘
                Rectangle()
                    .fill(Color.black)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue.opacity(0.8))
                            
                            Text(displayName.isEmpty ? "Me" : displayName)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                            
                            Text("Camera Off")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                // 비디오 품질 정보 오버레이
                if let stats = videoStats {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("📊 송신 통계")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.yellow)
                            
                            HStack {
                                Text("해상도:")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.8))
                                Text(stats.resolution)
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.cyan)
                            }
                            
                            HStack {
                                Text("FPS:")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.8))
                                Text("\(stats.frameRate)")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.cyan)
                            }
                            
                            HStack {
                                Text("비트레이트:")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.8))
                                Text("\(stats.bitrate/1000)k")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("손실률:")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.8))
                                Text("\(stats.packetLoss, specifier: "%.1f")%")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(stats.packetLoss > 5 ? .red : .green)
                            }
                            
                            if let codec = stats.codecType {
                                HStack {
                                    Text("코덱:")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text(codec)
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(.purple)
                                }
                            }
                            
                            if let rtt = stats.rtt {
                                HStack {
                                    Text("RTT:")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("\(Int(rtt))ms")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            if let jitter = stats.jitter {
                                HStack {
                                    Text("Jitter:")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("\(jitter, specifier: "%.1f")ms")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                    .padding(4)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(4)
                    .padding(.bottom, 4)
                }
                
                // Name & mic overlay
                HStack(spacing: 6) {
                    if isMuted {
                        Image(systemName: "mic.slash.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    } else {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.white.opacity(0.9))
                            .font(.caption)
                    }
                    Text(displayName.isEmpty ? "Me" : displayName)
                        .foregroundColor(.white)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.35))
                .clipShape(Capsule())
            }
            .padding(8)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSpeaking ? Color.green : Color.clear, lineWidth: 3)
        )
        .cornerRadius(10)
        .clipped()
    }
}

#Preview {
    LiveKitCallView(
        liveKitManager: LiveKitManager(),
        roomURL: "wss://your-livekit-server.com",
        token: "your-token",
        isPresented: .constant(true),
        showVideoStats: true
    )
}