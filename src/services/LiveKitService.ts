import { BaseVideoService } from './BaseVideoService';
import { VideoServiceType, LiveKitConfig, ConnectionTestResult, ConfigField } from '../types';

export class LiveKitService extends BaseVideoService {
  type: VideoServiceType = 'livekit';
  name = 'LiveKit';
  description = 'LiveKit open-source platform for real-time video';
  
  configFields: ConfigField[] = [
    {
      name: 'url',
      label: 'Server URL',
      type: 'text',
      required: true,
      placeholder: 'wss://your-livekit-server.com',
      description: 'LiveKit server WebSocket URL'
    },
    {
      name: 'apiKey',
      label: 'API Key',
      type: 'text',
      required: true,
      placeholder: 'Enter your API Key',
      description: 'LiveKit API Key'
    },
    {
      name: 'apiSecret',
      label: 'API Secret',
      type: 'password',
      required: true,
      placeholder: 'Enter your API Secret',
      description: 'LiveKit API Secret for token generation'
    },
    {
      name: 'roomName',
      label: 'Room Name',
      type: 'text',
      required: true,
      placeholder: 'test-room',
      description: 'Room name to join'
    },
    {
      name: 'participantName',
      label: 'Participant Name',
      type: 'text',
      required: true,
      placeholder: 'Test User',
      description: 'Your display name in the room'
    }
  ];

  async connect(config: LiveKitConfig): Promise<ConnectionTestResult> {
    try {
      if (!this.validateConfig(config, ['url', 'apiKey', 'apiSecret', 'roomName', 'participantName'])) {
        return this.createErrorResult('Missing required configuration fields');
      }

      const startTime = Date.now();
      
      // Mock connection delay
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      const latency = Date.now() - startTime;
      
      return this.createSuccessResult('Successfully connected to LiveKit room', {
        latency,
        quality: latency < 150 ? 'excellent' : latency < 400 ? 'good' : 'poor',
        participantCount: Math.floor(Math.random() * 5) + 1
      });
    } catch (error) {
      return this.createErrorResult(`Connection failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  async disconnect(): Promise<void> {
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  async testConnection(config: LiveKitConfig): Promise<ConnectionTestResult> {
    try {
      if (!this.validateConfig(config, ['url', 'apiKey', 'apiSecret'])) {
        return this.createErrorResult('Server URL, API Key, and API Secret are required');
      }

      // Mock server validation
      await new Promise(resolve => setTimeout(resolve, 1200));
      
      return this.createSuccessResult('LiveKit server is accessible and credentials are valid');
    } catch (error) {
      return this.createErrorResult(`Test failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }
}