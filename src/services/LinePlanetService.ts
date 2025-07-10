import { BaseVideoService } from './BaseVideoService';
import { VideoServiceType, LinePlanetConfig, ConnectionTestResult, ConfigField } from '../types';

export class LinePlanetService extends BaseVideoService {
  type: VideoServiceType = 'lineplanet';
  name = 'LINE Planet';
  description = 'LINE Planet video communication service';
  
  configFields: ConfigField[] = [
    {
      name: 'channelId',
      label: 'Channel ID',
      type: 'text',
      required: true,
      placeholder: 'Enter your Channel ID',
      description: 'LINE Planet Channel ID'
    },
    {
      name: 'channelSecret',
      label: 'Channel Secret',
      type: 'password',
      required: true,
      placeholder: 'Enter your Channel Secret',
      description: 'Channel Secret for authentication'
    },
    {
      name: 'roomId',
      label: 'Room ID',
      type: 'text',
      required: true,
      placeholder: 'test-room-123',
      description: 'Room identifier to join'
    },
    {
      name: 'userId',
      label: 'User ID',
      type: 'text',
      required: true,
      placeholder: 'user123',
      description: 'Unique user identifier'
    }
  ];

  async connect(config: LinePlanetConfig): Promise<ConnectionTestResult> {
    try {
      if (!this.validateConfig(config, ['channelId', 'channelSecret', 'roomId', 'userId'])) {
        return this.createErrorResult('Missing required configuration fields');
      }

      const startTime = Date.now();
      
      // Mock connection delay
      await new Promise(resolve => setTimeout(resolve, 1800));
      
      const latency = Date.now() - startTime;
      
      return this.createSuccessResult('Successfully connected to LINE Planet room', {
        latency,
        quality: latency < 120 ? 'excellent' : latency < 350 ? 'good' : 'poor',
        participantCount: Math.floor(Math.random() * 8) + 1
      });
    } catch (error) {
      return this.createErrorResult(`Connection failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  async disconnect(): Promise<void> {
    await new Promise(resolve => setTimeout(resolve, 600));
  }

  async testConnection(config: LinePlanetConfig): Promise<ConnectionTestResult> {
    try {
      if (!this.validateConfig(config, ['channelId', 'channelSecret'])) {
        return this.createErrorResult('Channel ID and Channel Secret are required');
      }

      // Mock API validation
      await new Promise(resolve => setTimeout(resolve, 1100));
      
      return this.createSuccessResult('LINE Planet credentials are valid');
    } catch (error) {
      return this.createErrorResult(`Test failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }
}