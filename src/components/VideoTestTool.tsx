import React from 'react';
import { ServiceSelector } from './ServiceSelector';
import { ConfigForm } from './ConfigForm';
import { TestResults } from './TestResults';
import { VideoCallScreen } from './VideoCallScreen';
import { useVideoService } from '../hooks/useVideoService';
import { VideoServiceFactory } from '../services';

export const VideoTestTool: React.FC = () => {
  const {
    selectedService,
    config,
    isConnecting,
    lastTestResult,
    currentMode,
    errorMessage,
    selectService,
    updateConfig,
    testConnection,
    connect,
    clearResults,
    endCall,
    handleCallError,
    returnToSetup
  } = useVideoService();

  const handleTestConnection = async () => {
    clearResults();
    await testConnection();
  };

  const handleConnect = async () => {
    clearResults();
    await connect();
  };

  const isConfigValid = () => {
    if (!selectedService) return false;
    
    try {
      const service = VideoServiceFactory.getService(selectedService);
      const requiredFields = service.configFields
        .filter(field => field.required)
        .map(field => field.name);
      
      return requiredFields.every(field => {
        const value = config[field];
        return value !== undefined && value !== null && value !== '';
      });
    } catch {
      return false;
    }
  };

  // 화상회의 중일 때
  if (currentMode === 'calling' && selectedService) {
    return (
      <VideoCallScreen
        serviceType={selectedService}
        config={config as any}
        onEndCall={endCall}
        onError={handleCallError}
      />
    );
  }

  // 에러 화면
  if (currentMode === 'error') {
    return (
      <div className="video-test-tool">
        <header className="app-header">
          <h1>🎥 Video Conference Test Tool</h1>
          <p>Connection Error</p>
        </header>
        <main className="app-main">
          <div className="section error-section">
            <div className="error-message">
              <h3>❌ Connection Failed</h3>
              <p>{errorMessage}</p>
              <button 
                className="btn btn-primary"
                onClick={returnToSetup}
              >
                Return to Setup
              </button>
            </div>
          </div>
        </main>
      </div>
    );
  }

  // 설정 화면 (기본)
  return (
    <div className="video-test-tool">
      <header className="app-header">
        <h1>🎥 Video Conference Test Tool</h1>
        <p>Test your video conferencing service connections</p>
      </header>

      <main className="app-main">
        <div className="section">
          <ServiceSelector
            selectedService={selectedService}
            onServiceChange={selectService}
          />
        </div>

        {selectedService && (
          <div className="section">
            <ConfigForm
              serviceType={selectedService}
              config={config}
              onConfigChange={updateConfig}
            />
          </div>
        )}

        {selectedService && (
          <div className="section actions">
            <div className="action-buttons">
              <button
                type="button"
                onClick={handleTestConnection}
                disabled={isConnecting || !isConfigValid()}
                className="btn btn-secondary"
              >
                {isConnecting ? 'Testing...' : 'Test Connection'}
              </button>
              
              <button
                type="button"
                onClick={handleConnect}
                disabled={isConnecting || !isConfigValid()}
                className="btn btn-primary"
              >
                {isConnecting ? 'Connecting...' : 'Connect'}
              </button>
            </div>
          </div>
        )}

        {(lastTestResult || isConnecting) && currentMode === 'setup' && (
          <div className="section">
            <TestResults
              result={lastTestResult}
              isLoading={isConnecting}
            />
          </div>
        )}
      </main>
    </div>
  );
};