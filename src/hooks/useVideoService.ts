import { useState, useCallback } from 'react';
import { VideoServiceType, ServiceConfig, ConnectionTestResult, AppState } from '../types';
import { VideoServiceFactory } from '../services';

export const useVideoService = () => {
  const [state, setState] = useState<AppState>({
    selectedService: null,
    config: {},
    isConnecting: false,
    lastTestResult: null,
    currentMode: 'setup'
  });

  const selectService = useCallback((serviceType: VideoServiceType) => {
    setState(prev => ({
      ...prev,
      selectedService: serviceType,
      config: {},
      lastTestResult: null
    }));
  }, []);

  const updateConfig = useCallback((config: Partial<ServiceConfig>) => {
    setState(prev => ({
      ...prev,
      config
    }));
  }, []);

  const testConnection = useCallback(async () => {
    if (!state.selectedService) return;

    setState(prev => ({ ...prev, isConnecting: true }));

    try {
      const service = VideoServiceFactory.getService(state.selectedService);
      const result = await service.testConnection(state.config as ServiceConfig);
      
      setState(prev => ({
        ...prev,
        isConnecting: false,
        lastTestResult: result
      }));

      return result;
    } catch (error) {
      const errorResult: ConnectionTestResult = {
        success: false,
        message: error instanceof Error ? error.message : 'Unknown error occurred'
      };

      setState(prev => ({
        ...prev,
        isConnecting: false,
        lastTestResult: errorResult
      }));

      return errorResult;
    }
  }, [state.selectedService, state.config]);

  const connect = useCallback(async () => {
    if (!state.selectedService) return;

    setState(prev => ({ ...prev, isConnecting: true }));

    try {
      const service = VideoServiceFactory.getService(state.selectedService);
      const result = await service.connect(state.config as ServiceConfig);
      
      if (result.success) {
        setState(prev => ({
          ...prev,
          isConnecting: false,
          lastTestResult: result,
          currentMode: 'calling'
        }));
      } else {
        setState(prev => ({
          ...prev,
          isConnecting: false,
          lastTestResult: result,
          currentMode: 'error',
          errorMessage: result.message
        }));
      }

      return result;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      const errorResult: ConnectionTestResult = {
        success: false,
        message: errorMessage
      };

      setState(prev => ({
        ...prev,
        isConnecting: false,
        lastTestResult: errorResult,
        currentMode: 'error',
        errorMessage
      }));

      return errorResult;
    }
  }, [state.selectedService, state.config]);

  const disconnect = useCallback(async () => {
    if (!state.selectedService) return;

    try {
      const service = VideoServiceFactory.getService(state.selectedService);
      await service.disconnect();
      
      setState(prev => ({
        ...prev,
        lastTestResult: null
      }));
    } catch (error) {
      console.error('Disconnect error:', error);
    }
  }, [state.selectedService]);

  const clearResults = useCallback(() => {
    setState(prev => ({
      ...prev,
      lastTestResult: null
    }));
  }, []);

  const endCall = useCallback(async () => {
    if (state.selectedService) {
      try {
        const service = VideoServiceFactory.getService(state.selectedService);
        await service.disconnect();
      } catch (error) {
        console.error('Disconnect error:', error);
      }
    }
    
    setState(prev => ({
      ...prev,
      currentMode: 'setup',
      lastTestResult: null,
      errorMessage: undefined
    }));
  }, [state.selectedService]);

  const handleCallError = useCallback((errorMessage: string) => {
    setState(prev => ({
      ...prev,
      currentMode: 'error',
      errorMessage
    }));
  }, []);

  const returnToSetup = useCallback(() => {
    setState(prev => ({
      ...prev,
      currentMode: 'setup',
      errorMessage: undefined
    }));
  }, []);

  return {
    ...state,
    selectService,
    updateConfig,
    testConnection,
    connect,
    disconnect,
    clearResults,
    endCall,
    handleCallError,
    returnToSetup
  };
};