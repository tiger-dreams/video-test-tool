import { BaseVideoService } from './BaseVideoService';
import { VideoServiceType, AgoraConfig, ConnectionTestResult, ConfigField } from '../types';

export class AgoraService extends BaseVideoService {
  type: VideoServiceType = 'agora';
  name = 'Agora RTC';
  description = 'Agora Real-Time Communication platform for video calls';
  
  configFields: ConfigField[] = [
    {
      name: 'appId',
      label: 'App ID',
      type: 'text',
      required: true,
      placeholder: 'Enter your Agora App ID',
      description: 'Agora App ID from console'
    },
    {
      name: 'appCertificate',
      label: 'App Certificate',
      type: 'password',
      required: true,
      placeholder: 'Enter your App Certificate',
      description: 'App Certificate for token generation'
    },
    {
      name: 'channel',
      label: 'Channel Name',
      type: 'text',
      required: true,
      placeholder: 'test-channel',
      description: 'Channel name to join'
    },
    {
      name: 'token',
      label: 'Token (Optional)',
      type: 'password',
      required: false,
      placeholder: 'Leave empty for testing without token',
      description: 'Temporary token for secure access'
    }
  ];

  async connect(config: AgoraConfig): Promise<ConnectionTestResult> {
    try {
      if (!this.validateConfig(config, ['appId', 'appCertificate', 'channel'])) {
        return this.createErrorResult('Missing required configuration fields');
      }

      // Simulate Agora connection
      const startTime = Date.now();
      
      // Mock connection delay
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      const latency = Date.now() - startTime;
      
      return this.createSuccessResult('Successfully connected to Agora RTC', {
        latency,
        quality: latency < 100 ? 'excellent' : latency < 300 ? 'good' : 'poor',
        participantCount: 1
      });
    } catch (error) {
      return this.createErrorResult(`Connection failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  async disconnect(): Promise<void> {
    // Simulate disconnect
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  async testConnection(config: AgoraConfig): Promise<ConnectionTestResult> {
    try {
      if (!this.validateConfig(config, ['appId', 'channel'])) {
        return this.createErrorResult('App ID and Channel are required for connection test');
      }

      // Mock API validation
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      return this.createSuccessResult('Agora configuration is valid');
    } catch (error) {
      return this.createErrorResult(`Test failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }
}