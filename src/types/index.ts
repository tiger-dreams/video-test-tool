export type VideoServiceType = 'agora' | 'livekit' | 'zoom' | 'lineplanet';

export interface BaseServiceConfig {
  [key: string]: string | number | boolean | undefined;
}

export interface AgoraConfig extends BaseServiceConfig {
  appId: string;
  appCertificate: string;
  channel: string;
  token?: string;
}

export interface LiveKitConfig extends BaseServiceConfig {
  url: string;
  apiKey: string;
  apiSecret: string;
  roomName: string;
  participantName: string;
}

export interface ZoomConfig extends BaseServiceConfig {
  apiKey: string;
  apiSecret: string;
  meetingNumber: string;
  password?: string;
  userName: string;
}

export interface LinePlanetConfig extends BaseServiceConfig {
  channelId: string;
  channelSecret: string;
  roomId: string;
  userId: string;
}

export type ServiceConfig = AgoraConfig | LiveKitConfig | ZoomConfig | LinePlanetConfig;

export interface ConnectionTestResult {
  success: boolean;
  message: string;
  details?: {
    latency?: number;
    quality?: 'excellent' | 'good' | 'poor';
    participantCount?: number;
  };
}

export interface VideoService {
  type: VideoServiceType;
  name: string;
  description: string;
  configFields: ConfigField[];
  connect(config: ServiceConfig): Promise<ConnectionTestResult>;
  disconnect(): Promise<void>;
  testConnection(config: ServiceConfig): Promise<ConnectionTestResult>;
}

export interface ConfigField {
  name: string;
  label: string;
  type: 'text' | 'password' | 'number';
  required: boolean;
  placeholder?: string;
  description?: string;
}

export type AppMode = 'setup' | 'calling' | 'error';

export interface AppState {
  selectedService: VideoServiceType | null;
  config: Partial<ServiceConfig>;
  isConnecting: boolean;
  lastTestResult: ConnectionTestResult | null;
  currentMode: AppMode;
  errorMessage?: string;
}