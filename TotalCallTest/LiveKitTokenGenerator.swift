import Foundation
import CryptoKit

struct LiveKitTokenGenerator {
    
    struct TokenPayload: Codable {
        let iss: String // API Key
        let nbf: Int    // Not Before
        let exp: Int    // Expiration
        let iat: Int    // Issued At
        let sub: String // Participant Name
        let video: VideoPermissions
        
        struct VideoPermissions: Codable {
            let roomJoin: Bool
            let room: String
            let canPublish: Bool
            let canSubscribe: Bool
            let canUpdateOwnMetadata: Bool
            let roomAdmin: Bool?
            let canPublishData: Bool?
            let canUpdateMetadata: Bool?
        }
    }
    
    static func generateToken(
        apiKey: String,
        apiSecret: String,
        roomName: String,
        participantName: String,
        expirationTimeInSeconds: Int = 3600,
        isHost: Bool = false
    ) throws -> String {
        
        let now = Int(Date().timeIntervalSince1970)
        let exp = now + expirationTimeInSeconds
        
        // Create JWT Header
        let header = [
            "alg": "HS256",
            "typ": "JWT"
        ]
        
        // Create JWT Payload
        var videoPermissions = TokenPayload.VideoPermissions(
            roomJoin: true,
            room: roomName,
            canPublish: true,
            canSubscribe: true,
            canUpdateOwnMetadata: true,
            roomAdmin: nil,
            canPublishData: nil,
            canUpdateMetadata: nil
        )
        
        // Add host permissions if needed
        if isHost {
            videoPermissions = TokenPayload.VideoPermissions(
                roomJoin: true,
                room: roomName,
                canPublish: true,
                canSubscribe: true,
                canUpdateOwnMetadata: true,
                roomAdmin: true,
                canPublishData: true,
                canUpdateMetadata: true
            )
        }
        
        let payload = TokenPayload(
            iss: apiKey,
            nbf: now,
            exp: exp,
            iat: now,
            sub: participantName,
            video: videoPermissions
        )
        
        // Encode header and payload to base64
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let payloadData = try JSONEncoder().encode(payload)
        
        let encodedHeader = headerData.base64URLEncodedString()
        let encodedPayload = payloadData.base64URLEncodedString()
        
        // Create signature
        let signingInput = "\(encodedHeader).\(encodedPayload)"
        let signature = try createHMACSignature(message: signingInput, secret: apiSecret)
        let encodedSignature = signature.base64URLEncodedString()
        
        return "\(signingInput).\(encodedSignature)"
    }
    
    private static func createHMACSignature(message: String, secret: String) throws -> Data {
        guard let messageData = message.data(using: .utf8),
              let secretData = secret.data(using: .utf8) else {
            throw TokenGenerationError.invalidInput
        }
        
        let key = SymmetricKey(data: secretData)
        let signature = HMAC<SHA256>.authenticationCode(for: messageData, using: key)
        return Data(signature)
    }
    
    static func getTokenExpiration(_ token: String) -> Date? {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else { return nil }
        
        guard let payloadData = Data(base64URLEncoded: parts[1]) else { return nil }
        
        do {
            let json = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any]
            if let exp = json?["exp"] as? Int {
                return Date(timeIntervalSince1970: TimeInterval(exp))
            }
        } catch {
            print("Error parsing token: \(error)")
        }
        
        return nil
    }
}

enum TokenGenerationError: Error {
    case invalidInput
    case encodingError
    
    var localizedDescription: String {
        switch self {
        case .invalidInput:
            return "Invalid input parameters"
        case .encodingError:
            return "Failed to encode token data"
        }
    }
}

// Base64URL encoding extension
extension Data {
    func base64URLEncodedString() -> String {
        let base64 = self.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        self.init(base64Encoded: base64)
    }
}