import React from 'react';
import { ConnectionTestResult } from '../types';

interface TestResultsProps {
  result: ConnectionTestResult | null;
  isLoading: boolean;
}

export const TestResults: React.FC<TestResultsProps> = ({ result, isLoading }) => {
  if (isLoading) {
    return (
      <div className="test-results loading">
        <div className="spinner"></div>
        <p>Testing connection...</p>
      </div>
    );
  }

  if (!result) {
    return null;
  }

  const getStatusIcon = () => {
    return result.success ? '✅' : '❌';
  };

  const getQualityColor = (quality?: string) => {
    switch (quality) {
      case 'excellent': return '#4caf50';
      case 'good': return '#ff9800';
      case 'poor': return '#f44336';
      default: return '#666';
    }
  };

  return (
    <div className={`test-results ${result.success ? 'success' : 'error'}`}>
      <div className="result-header">
        <span className="status-icon">{getStatusIcon()}</span>
        <h4>{result.success ? 'Connection Successful' : 'Connection Failed'}</h4>
      </div>
      
      <p className="result-message">{result.message}</p>
      
      {result.details && (
        <div className="result-details">
          {result.details.latency && (
            <div className="detail-item">
              <span className="label">Latency:</span>
              <span className="value">{result.details.latency}ms</span>
            </div>
          )}
          
          {result.details.quality && (
            <div className="detail-item">
              <span className="label">Quality:</span>
              <span 
                className="value quality"
                style={{ color: getQualityColor(result.details.quality) }}
              >
                {result.details.quality.toUpperCase()}
              </span>
            </div>
          )}
          
          {result.details.participantCount && (
            <div className="detail-item">
              <span className="label">Participants:</span>
              <span className="value">{result.details.participantCount}</span>
            </div>
          )}
        </div>
      )}
    </div>
  );
};