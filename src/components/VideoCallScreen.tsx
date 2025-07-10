import React, { useEffect, useRef, useState } from 'react';
import { VideoServiceType, ServiceConfig, ConnectionTestResult } from '../types';
import { VideoServiceFactory } from '../services';

interface Participant {
  id: string;
  name: string;
  stream?: MediaStream;
  isMuted?: boolean;
  isVideoOff?: boolean;
}

interface VideoCallScreenProps {
  serviceType: VideoServiceType;
  config: ServiceConfig;
  onEndCall: () => void;
  onError: (error: string) => void;
}

export const VideoCallScreen: React.FC<VideoCallScreenProps> = ({
  serviceType,
  config,
  onEndCall,
  onError
}) => {
  const [isConnected, setIsConnected] = useState(false);
  const [connectionTime, setConnectionTime] = useState(0);
  const [participants, setParticipants] = useState<Participant[]>([]);
  const [localStream, setLocalStream] = useState<MediaStream | null>(null);
  const [isMuted, setIsMuted] = useState(false);
  const [isVideoOff, setIsVideoOff] = useState(false);
  const [permissionGranted, setPermissionGranted] = useState(false);
  
  const localVideoRef = useRef<HTMLVideoElement>(null);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  const service = VideoServiceFactory.getService(serviceType);

  useEffect(() => {
    initializeMediaAndConnect();
    return () => {
      cleanup();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // 로컬 스트림이 변경될 때마다 비디오 엘리먼트에 설정
  useEffect(() => {
    if (localStream && localVideoRef.current) {
      console.log('🔗 Setting video stream to element');
      localVideoRef.current.srcObject = localStream;
      
      // 비디오 재생 확인
      localVideoRef.current.onloadedmetadata = () => {
        console.log('📺 Video metadata loaded');
        localVideoRef.current?.play().then(() => {
          console.log('▶️ Video playing successfully');
        }).catch(error => {
          console.error('❌ Video play error:', error);
        });
      };
      
      localVideoRef.current.onerror = (error) => {
        console.error('❌ Video element error:', error);
      };
    }
  }, [localStream]);

  const initializeMediaAndConnect = async () => {
    try {
      console.log('🎥 Requesting camera and microphone access...');
      
      // 미디어 권한 요청
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { width: 1280, height: 720 },
        audio: true
      });
      
      console.log('✅ Media stream obtained:', stream);
      console.log('📹 Video tracks:', stream.getVideoTracks());
      console.log('🎤 Audio tracks:', stream.getAudioTracks());
      
      setLocalStream(stream);
      setPermissionGranted(true);

      // 서비스 연결
      await connectToService();
      
    } catch (error) {
      console.error('❌ Media access error:', error);
      onError('Camera/microphone access denied. Please allow permissions and try again.');
    }
  };

  const connectToService = async () => {
    try {
      console.log('🔌 Connecting to service...');
      const result: ConnectionTestResult = await service.connect(config);
      
      if (result.success) {
        console.log('✅ Service connected successfully');
        setIsConnected(true);
        
        // 초기 참가자 설정 (나만)
        const localParticipant = {
          id: 'local',
          name: 'You',
          stream: localStream || undefined,
          isMuted: false,
          isVideoOff: false
        };
        
        console.log('👤 Setting local participant:', localParticipant);
        setParticipants([localParticipant]);
        
        // 연결 시간 카운터 시작
        intervalRef.current = setInterval(() => {
          setConnectionTime(prev => prev + 1);
        }, 1000);

        // 시뮬레이션: 2-5초 후 랜덤하게 참가자 추가
        setTimeout(() => {
          addRandomParticipants();
        }, Math.random() * 3000 + 2000);
        
      } else {
        console.error('❌ Service connection failed:', result.message);
        onError(result.message);
      }
    } catch (error) {
      console.error('❌ Connection error:', error);
      onError(error instanceof Error ? error.message : 'Connection failed');
    }
  };

  const addRandomParticipants = () => {
    const participantNames = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve', 'Frank'];
    const numToAdd = Math.floor(Math.random() * 3) + 1; // 1-3명 추가
    
    const newParticipants: Participant[] = [];
    for (let i = 0; i < numToAdd; i++) {
      const name = participantNames[Math.floor(Math.random() * participantNames.length)];
      newParticipants.push({
        id: `remote-${Date.now()}-${i}`,
        name,
        isMuted: Math.random() > 0.7, // 30% 확률로 뮤트
        isVideoOff: Math.random() > 0.8 // 20% 확률로 비디오 오프
      });
    }
    
    setParticipants(prev => [...prev, ...newParticipants]);
  };

  const cleanup = () => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }
    
    if (localStream) {
      localStream.getTracks().forEach(track => track.stop());
    }
    
    service.disconnect().catch(console.error);
  };

  const handleEndCall = async () => {
    cleanup();
    onEndCall();
  };

  const toggleMute = () => {
    if (localStream) {
      const audioTrack = localStream.getAudioTracks()[0];
      if (audioTrack) {
        audioTrack.enabled = isMuted;
      }
    }
    
    setIsMuted(!isMuted);
    
    // 로컬 참가자 상태 업데이트
    setParticipants(prev => 
      prev.map(p => 
        p.id === 'local' ? { ...p, isMuted: !isMuted } : p
      )
    );
  };

  const toggleVideo = () => {
    if (localStream) {
      const videoTrack = localStream.getVideoTracks()[0];
      if (videoTrack) {
        videoTrack.enabled = isVideoOff;
      }
    }
    
    setIsVideoOff(!isVideoOff);
    
    // 로컬 참가자 상태 업데이트
    setParticipants(prev => 
      prev.map(p => 
        p.id === 'local' ? { ...p, isVideoOff: !isVideoOff } : p
      )
    );
  };

  const formatTime = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const getGridLayout = (count: number) => {
    if (count <= 1) return 'grid-1';
    if (count <= 4) return 'grid-4';
    if (count <= 9) return 'grid-9';
    return 'grid-many';
  };

  const renderParticipant = (participant: Participant, index: number) => {
    const isLocal = participant.id === 'local';
    
    console.log(`🎬 Rendering participant: ${participant.name}, isLocal: ${isLocal}, hasStream: ${!!localStream}`);
    
    return (
      <div key={participant.id} className={`participant-video ${isLocal ? 'local' : 'remote'}`}>
        {isLocal && localStream ? (
          <div style={{ position: 'relative', width: '100%', height: '100%' }}>
            <video
              ref={localVideoRef}
              autoPlay
              muted
              playsInline
              className="video-element"
              style={{ 
                width: '100%', 
                height: '100%', 
                objectFit: 'cover',
                background: '#000' 
              }}
              onLoadedData={() => console.log('📺 Video loaded and ready')}
              onPlay={() => console.log('▶️ Video is playing')}
              onError={(e) => console.error('❌ Video error:', e)}
            />
            {/* 디버그 정보 오버레이 */}
            <div style={{
              position: 'absolute',
              top: '10px',
              left: '10px',
              background: 'rgba(0,0,0,0.7)',
              color: 'white',
              padding: '5px',
              fontSize: '12px',
              borderRadius: '3px'
            }}>
              Stream: {localStream ? '✅' : '❌'}
            </div>
          </div>
        ) : (
          <div className="mock-video" style={{
            background: `linear-gradient(45deg, hsl(${index * 60}, 70%, 60%), hsl(${index * 60 + 40}, 70%, 70%))`
          }}>
            <div className="participant-placeholder">
              {participant.isVideoOff ? '📷' : participant.name}
            </div>
          </div>
        )}
        
        {/* 참가자 정보 오버레이 */}
        <div className="participant-info">
          <span className="participant-name">{participant.name}</span>
          {participant.isMuted && (
            <span className="mute-icon">🔇</span>
          )}
        </div>
        
        {/* 비디오 오프 오버레이 */}
        {participant.isVideoOff && (
          <div className="video-off-overlay">
            <span className="video-off-icon">📷</span>
          </div>
        )}
      </div>
    );
  };

  if (!permissionGranted || !isConnected) {
    return (
      <div className="video-call-screen connecting">
        <div className="connecting-message">
          <div className="spinner"></div>
          <h3>
            {!permissionGranted 
              ? 'Requesting camera and microphone access...'
              : `Connecting to ${service.name}...`
            }
          </h3>
          <p>
            {!permissionGranted
              ? 'Please allow camera and microphone permissions'
              : 'Please wait while we establish the connection'
            }
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="video-call-screen">
      <div className="call-header">
        <div className="call-info">
          <h3>{service.name} Call</h3>
          <div className="call-stats">
            <span className="duration">⏱️ {formatTime(connectionTime)}</span>
            <span className="participants">👥 {participants.length} participant{participants.length !== 1 ? 's' : ''}</span>
          </div>
        </div>
      </div>

      <div className={`video-grid ${getGridLayout(participants.length)}`}>
        {participants.map((participant, index) => renderParticipant(participant, index))}
      </div>

      <div className="call-controls">
        <button
          className={`control-btn ${isMuted ? 'muted' : ''}`}
          onClick={toggleMute}
          title={isMuted ? 'Unmute' : 'Mute'}
        >
          {isMuted ? '🔇' : '🎤'}
        </button>
        
        <button
          className={`control-btn ${isVideoOff ? 'video-off' : ''}`}
          onClick={toggleVideo}
          title={isVideoOff ? 'Turn on camera' : 'Turn off camera'}
        >
          {isVideoOff ? '📷' : '📹'}
        </button>
        
        <button
          className="control-btn end-call"
          onClick={handleEndCall}
          title="End call"
        >
          📞
        </button>
      </div>
    </div>
  );
};