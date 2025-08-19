import Foundation
import LiveKit
#if targetEnvironment(simulator)
import CoreGraphics
import UIKit

extension LiveKitManager {
    // 시뮬레이터에서 카메라 대신 모의 비디오 사용
    func enableSimulatorVideo() async {
        #if targetEnvironment(simulator)
        guard let lkRoom = self.room else { return }
        
        do {
            // 시뮬레이터에서는 카메라 대신 모의 비디오 트랙 생성
            print("[Simulator] Creating mock video track...")
            
            // 실제 카메라 대신 빈 비디오 트랙으로 대체
            // 이것은 데모 목적으로만 사용
            
            _ = lkRoom // suppress unused variable for now
        } catch {
            print("[Simulator] Failed to create mock video: \(error)")
        }
        #endif
    }
}

// 시뮬레이터 감지 헬퍼
struct DeviceInfo {
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    static var deviceType: String {
        #if targetEnvironment(simulator)
        return "iOS Simulator"
        #else
        return "Physical Device"
        #endif
    }
}
#endif