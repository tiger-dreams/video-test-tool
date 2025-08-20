import SwiftUI
import LiveKit

struct LiveKitVideoView: UIViewRepresentable {
    let track: VideoTrack?
    
    func makeUIView(context: Context) -> VideoView {
        let videoView = VideoView()
        videoView.layoutMode = .fit
        videoView.backgroundColor = .black
        videoView.isUserInteractionEnabled = false
        print("[LiveKitVideoView] Created VideoView")
        return videoView
    }
    
    func updateUIView(_ videoView: VideoView, context: Context) {
        print("[LiveKitVideoView] Updating view with track: \(track?.description ?? "nil")")
        
        if let track = track {
            print("[LiveKitVideoView] Setting track: \(track)")
            videoView.track = track
            
            // Force layout update
            DispatchQueue.main.async {
                videoView.setNeedsLayout()
                videoView.layoutIfNeeded()
            }
        } else {
            print("[LiveKitVideoView] Clearing track")
            videoView.track = nil
        }
    }
}