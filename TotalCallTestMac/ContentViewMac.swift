//
//  ContentView.swift
//  TotalCallTest
//
//  Created by AL03041390 on 8/19/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var liveKitManager = LiveKitManager()
    @State private var serverURL = "wss://alllogo-lu7k4qum.livekit.cloud"
    @State private var apiKey = "APIi9kdC6vaC3Zb"
    @State private var apiSecret = "eiwzpboeOcSrL11eWtjBMrKzPXClOfaA5G0ZsJ6hQddA"
    @State private var roomName = "test-room"
    @State private var participantName = "User-\(Int.random(in: 1000...9999))"
    @State private var isHost = false
    @State private var generatedToken = ""
    @State private var isGeneratingToken = false
    @State private var tokenError: String?
    @State private var showingVideoCall = false
    @State private var showVideoStats = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("LiveKit Video Call")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Server Configuration
                    VStack(alignment: .leading, spacing: 12) {
                        Text("서버 설정")
                            .font(.headline)
                        
                        TextField("Server URL (wss://your-livekit-server.com)", text: $serverURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // API Configuration
                    VStack(alignment: .leading, spacing: 12) {
                        Text("API 설정")
                            .font(.headline)
                        
                        TextField("API Key", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        SecureField("API Secret", text: $apiSecret)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textSelection(.disabled)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Room Configuration
                    VStack(alignment: .leading, spacing: 12) {
                        Text("방 설정")
                            .font(.headline)
                        
                        TextField("Room Name", text: $roomName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Participant Name", text: $participantName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Toggle("호스트로 참여", isOn: $isHost)
                            .padding(.top, 8)
                        
                        Toggle("비디오 품질 정보 표시", isOn: $showVideoStats)
                            .padding(.top, 8)
                        
                        if isHost {
                            Text("⚡ 호스트 권한: 참가자 관리, 방 설정 변경")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        if showVideoStats {
                            Text("📊 비디오 해상도, FPS, 비트레이트, 패킷 손실률 등 품질 정보 표시")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Token Generation
                    VStack(alignment: .leading, spacing: 12) {
                        Text("토큰 생성")
                            .font(.headline)
                        
                        Button(action: generateToken) {
                            HStack {
                                if isGeneratingToken {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "key.fill")
                                }
                                Text(isGeneratingToken ? "토큰 생성 중..." : "LiveKit 토큰 생성")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(canGenerateToken ? Color.blue : Color.gray)
                            .cornerRadius(8)
                        }
                        .disabled(!canGenerateToken || isGeneratingToken)
                        
                        if let error = tokenError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        if !generatedToken.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("생성된 토큰:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    Text(generatedToken)
                                        .font(.system(size: 10, design: .monospaced))
                                        .padding(8)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                
                                if let expiration = LiveKitTokenGenerator.getTokenExpiration(generatedToken) {
                                    Text("만료: \(expiration, style: .date) \(expiration, style: .time)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Button("토큰 복사") {
                                    copyToClipboard(generatedToken)
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Join Call Button
                    Button("비디오 통화 시작") {
                        showingVideoCall = true
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(isReadyToJoin ? Color.green : Color.gray)
                    .cornerRadius(10)
                    .disabled(!isReadyToJoin)
                    
                    if let error = liveKitManager.connectionError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("Status: \(liveKitManager.isConnected ? "Connected" : "Disconnected")")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    #if targetEnvironment(simulator)
                    VStack(spacing: 8) {
                        Text("📱 시뮬레이터 모드")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        
                        Text("⚠️ 카메라/마이크 제한: 실제 디바이스에서 전체 기능 테스트 가능")
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    #endif
                }
                .padding()
            }
            .sheet(isPresented: $showingVideoCall) {
                LiveKitCallView(
                    liveKitManager: liveKitManager,
                    roomURL: serverURL.trimmingCharacters(in: .whitespacesAndNewlines),
                    token: generatedToken,
                    isPresented: $showingVideoCall,
                    showVideoStats: showVideoStats
                )
                .frame(minWidth: 800, minHeight: 600)
            }
        }
    }
    
    private var canGenerateToken: Bool {
        !apiKey.isEmpty && !apiSecret.isEmpty && !roomName.isEmpty && !participantName.isEmpty
    }
    
    private var isReadyToJoin: Bool {
        isServerURLValid && !generatedToken.isEmpty
    }
    
    private var isServerURLValid: Bool {
        let trimmed = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return false }
        return ["ws", "wss"].contains(url.scheme?.lowercased()) && !(url.host ?? "").isEmpty
    }
    
    private func generateToken() {
        tokenError = nil
        isGeneratingToken = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let token = try LiveKitTokenGenerator.generateToken(
                    apiKey: apiKey,
                    apiSecret: apiSecret,
                    roomName: roomName,
                    participantName: participantName,
                    expirationTimeInSeconds: 3600, // 1 hour
                    isHost: isHost
                )
                
                DispatchQueue.main.async {
                    self.generatedToken = token
                    self.isGeneratingToken = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.tokenError = "토큰 생성 실패: \(error.localizedDescription)"
                    self.isGeneratingToken = false
                }
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.setString(text, forType: .string)
        // macOS doesn't have haptic feedback like iOS
    }
}

#Preview {
    ContentView()
}
