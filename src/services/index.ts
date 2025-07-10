import { VideoService, VideoServiceType } from '../types';
import { AgoraService } from './AgoraService';
import { LiveKitService } from './LiveKitService';
import { ZoomService } from './ZoomService';
import { LinePlanetService } from './LinePlanetService';

export class VideoServiceFactory {
  private static services: Map<VideoServiceType, VideoService> = new Map<VideoServiceType, VideoService>([
    ['agora' as VideoServiceType, new AgoraService()],
    ['livekit' as VideoServiceType, new LiveKitService()],
    ['zoom' as VideoServiceType, new ZoomService()],
    ['lineplanet' as VideoServiceType, new LinePlanetService()]
  ]);

  static getService(type: VideoServiceType): VideoService {
    const service = this.services.get(type);
    if (!service) {
      throw new Error(`Unsupported video service type: ${type}`);
    }
    return service;
  }

  static getAllServices(): VideoService[] {
    return Array.from(this.services.values());
  }

  static getServiceTypes(): VideoServiceType[] {
    return Array.from(this.services.keys());
  }
}

export * from './BaseVideoService';
export * from './AgoraService';
export * from './LiveKitService';
export * from './ZoomService';
export * from './LinePlanetService';