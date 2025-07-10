import { VideoService, VideoServiceType, ServiceConfig, ConnectionTestResult, ConfigField } from '../types';

export abstract class BaseVideoService implements VideoService {
  abstract type: VideoServiceType;
  abstract name: string;
  abstract description: string;
  abstract configFields: ConfigField[];

  abstract connect(config: ServiceConfig): Promise<ConnectionTestResult>;
  abstract disconnect(): Promise<void>;
  abstract testConnection(config: ServiceConfig): Promise<ConnectionTestResult>;

  protected validateConfig(config: ServiceConfig, requiredFields: string[]): boolean {
    return requiredFields.every(field => {
      const value = config[field];
      return value !== undefined && value !== null && value !== '';
    });
  }

  protected createSuccessResult(message: string, details?: any): ConnectionTestResult {
    return {
      success: true,
      message,
      details
    };
  }

  protected createErrorResult(message: string): ConnectionTestResult {
    return {
      success: false,
      message
    };
  }
}