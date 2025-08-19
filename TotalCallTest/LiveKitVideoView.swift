import SwiftUI
import LiveKit

struct LiveKitVideoView: UIViewRepresentable {
    let track: VideoTrack?
    
    func makeUIView(context: Context) -> VideoView {
        let videoView = VideoView()
        videoView.layoutMode = .fit
        videoView.backgroundColor = .black
        return videoView
    }
    
    func updateUIView(_ videoView: VideoView, context: Context) {
        if let track = track {
            videoView.track = track
        } else {
            videoView.track = nil
        }
    }
}