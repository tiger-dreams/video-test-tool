interface RoomParticipant {
  id: string;
  name: string;
  joinedAt: number;
  lastSeen: number;
  roomId: string;
  deviceInfo: string;
}

export class RoomService {
  private static readonly STORAGE_KEY = 'video-test-participants';
  private static readonly HEARTBEAT_INTERVAL = 2000; // 2초마다 하트비트
  private static readonly PARTICIPANT_TIMEOUT = 10000; // 10초 후 타임아웃
  
  private participantId: string;
  private roomId: string;
  private heartbeatInterval?: NodeJS.Timeout;
  private participantCheckInterval?: NodeJS.Timeout;
  private onParticipantsChange?: (participants: RoomParticipant[]) => void;

  constructor(roomId: string, participantName: string = 'User') {
    this.roomId = roomId;
    this.participantId = this.generateParticipantId();
    
    // 참여자 정보 생성
    const participant: RoomParticipant = {
      id: this.participantId,
      name: participantName,
      joinedAt: Date.now(),
      lastSeen: Date.now(),
      roomId: this.roomId,
      deviceInfo: this.getDeviceInfo()
    };

    this.addParticipant(participant);
  }

  private generateParticipantId(): string {
    return `participant-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  private getDeviceInfo(): string {
    const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
    const isTablet = /iPad/i.test(navigator.userAgent);
    
    if (isTablet) return 'iPad';
    if (isMobile) return 'Mobile';
    return 'Desktop';
  }

  private getStorageKey(): string {
    return `${RoomService.STORAGE_KEY}-${this.roomId}`;
  }

  private addParticipant(participant: RoomParticipant): void {
    const participants = this.getParticipants();
    const existingIndex = participants.findIndex(p => p.id === participant.id);
    
    if (existingIndex >= 0) {
      participants[existingIndex] = participant;
    } else {
      participants.push(participant);
    }
    
    localStorage.setItem(this.getStorageKey(), JSON.stringify(participants));
  }

  private getParticipants(): RoomParticipant[] {
    try {
      const stored = localStorage.getItem(this.getStorageKey());
      return stored ? JSON.parse(stored) : [];
    } catch {
      return [];
    }
  }

  private updateLastSeen(): void {
    const participants = this.getParticipants();
    const participant = participants.find(p => p.id === this.participantId);
    
    if (participant) {
      participant.lastSeen = Date.now();
      localStorage.setItem(this.getStorageKey(), JSON.stringify(participants));
    }
  }

  private removeInactiveParticipants(): RoomParticipant[] {
    const now = Date.now();
    const participants = this.getParticipants();
    const activeParticipants = participants.filter(
      p => (now - p.lastSeen) < RoomService.PARTICIPANT_TIMEOUT
    );
    
    if (activeParticipants.length !== participants.length) {
      localStorage.setItem(this.getStorageKey(), JSON.stringify(activeParticipants));
    }
    
    return activeParticipants;
  }

  public joinRoom(onParticipantsChange: (participants: RoomParticipant[]) => void): void {
    console.log(`🚪 Joining room: ${this.roomId} as ${this.participantId}`);
    console.log(`🔑 Storage key: ${this.getStorageKey()}`);
    
    this.onParticipantsChange = onParticipantsChange;
    
    // 하트비트 시작 (내 존재 알리기)
    this.heartbeatInterval = setInterval(() => {
      this.updateLastSeen();
      console.log(`💓 Heartbeat sent for ${this.participantId}`);
    }, RoomService.HEARTBEAT_INTERVAL);

    // 참여자 변경 감지
    this.participantCheckInterval = setInterval(() => {
      const activeParticipants = this.removeInactiveParticipants();
      console.log(`👥 Active participants in room ${this.roomId}:`, activeParticipants.map(p => `${p.name} (${p.deviceInfo}) - ${p.id.slice(-6)}`));
      console.log(`📊 Total participants: ${activeParticipants.length}`);
      this.onParticipantsChange?.(activeParticipants);
    }, RoomService.HEARTBEAT_INTERVAL);

    // 초기 참여자 목록 전달
    const initialParticipants = this.removeInactiveParticipants();
    console.log(`🎬 Initial participants:`, initialParticipants.map(p => `${p.name} (${p.deviceInfo})`));
    this.onParticipantsChange(initialParticipants);
  }

  public leaveRoom(): void {
    // 내 정보 제거
    const participants = this.getParticipants();
    const filteredParticipants = participants.filter(p => p.id !== this.participantId);
    localStorage.setItem(this.getStorageKey(), JSON.stringify(filteredParticipants));

    // 인터벌 정리
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
    }
    if (this.participantCheckInterval) {
      clearInterval(this.participantCheckInterval);
    }
  }

  public getMyParticipantId(): string {
    return this.participantId;
  }

  public getRoomId(): string {
    return this.roomId;
  }

  // 방 전체 정리 (개발용)
  public static clearRoom(roomId: string): void {
    localStorage.removeItem(`${RoomService.STORAGE_KEY}-${roomId}`);
  }
}