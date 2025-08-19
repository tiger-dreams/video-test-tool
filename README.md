# Video Test Tool (iOS, LiveKit)

An iOS SwiftUI sample app to test LiveKit video calls. Includes a tile view that always shows the local user and up to three remote participants (max 4 tiles).

## Features
- **Tile layout**: 1–4 tiles, local participant always included.
- **Controls**: Toggle mic/camera, end call.
- **Token generation**: Create a LiveKit JWT inside the app for quick testing.
- **Simulator-friendly**: Shows status and hints; camera is limited on Simulator.

## Requirements
- Xcode 15+ (iOS 17+ target recommended)
- Swift 5.9+
- A working LiveKit server endpoint (Cloud or self-hosted)
  - WebSocket URL like `wss://<your-livekit-host>`
  - API Key and API Secret for token generation

## Project Structure
- `TotalCallTest/TotalCallTestApp.swift` — App entry point.
- `TotalCallTest/ContentView.swift` — Configuration UI (Server URL, API credentials, room & user).
- `TotalCallTest/LiveKitCallView.swift` — In-call UI (tile grid + controls).
- `TotalCallTest/LiveKitManager.swift` — LiveKit room lifecycle & track management.
- `TotalCallTest/LiveKitTokenGenerator.swift` — JWT creation for LiveKit.
- `TotalCallTest/LiveKitVideoView.swift` — SwiftUI wrapper for rendering `VideoTrack`.
- `TotalCallTest/SimulatorHelpers.swift` — Simulator-specific helpers.
- `TotalCallTest/ViewExtensions.swift` — Small SwiftUI helpers.
- `TotalCallTestTests/`, `TotalCallTestUITests/` — Test targets.

## Setup
1. Open the project:
   - Double-click `TotalCallTest.xcodeproj`.
2. Ensure signing is set for your team (Targets → Signing & Capabilities).
3. Update permissions in `Info.plist` if needed (camera/mic usage descriptions). Xcode often manages these with LiveKit integrations.

## LiveKit Configuration
1. In the app (on device or simulator), go to the **Server 설정** section.
2. Enter your LiveKit **Server URL**: must be `wss://...` (not `https://`).
3. Enter **API Key** and **API Secret** of your LiveKit deployment.
4. Set **Room Name** and **Participant Name**.
5. (Optional) Enable **호스트로 참여** for elevated permissions.
6. Tap **LiveKit 토큰 생성** to generate a JWT.
7. Tap **비디오 통화 시작** to connect using the URL and token.

Notes:
- The join button is only enabled if the Server URL is a valid `ws`/`wss` URL and a token exists.
- The app trims whitespace from the URL automatically.

## Build & Run
- Select an iOS Simulator or a physical device in Xcode and press Run.
- On Simulator, camera/microphone are limited by the platform.
- On a device, grant camera and microphone permissions when prompted.

## Troubleshooting
- **URL parse failed (LiveKit Room.connect)**
  - Ensure the URL starts with `wss://` and includes a valid host (no extra spaces).
  - Example: `wss://my-livekit-host.livekit.cloud`
- **Cannot connect / Auth errors**
  - Verify API Key/Secret belong to the same LiveKit deployment as your Server URL.
  - Ensure the room name in the token matches the room you intend to join.
- **Keyboard constraint warnings (iOS logs)**
  - These are UIKit accessory bar constraints emitted when editing text fields. They are harmless. The app dismisses the keyboard on scroll to reduce noise.
- **No local video in Simulator**
  - Simulator has limited camera support. Test on a real device for full capture.
- **No remote video**
  - Check that remote participants are publishing a camera track and that your network allows WebRTC traffic.

## Security Notes
- API Key/Secret are used locally to generate a JWT. In production, move token generation to a trusted backend and only supply short-lived tokens to the client.

## License
This repository is for testing/demo purposes. Add your preferred license here.
