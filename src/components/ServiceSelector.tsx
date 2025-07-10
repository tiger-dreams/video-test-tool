import React from 'react';
import { VideoServiceType } from '../types';
import { VideoServiceFactory } from '../services';

interface ServiceSelectorProps {
  selectedService: VideoServiceType | null;
  onServiceChange: (service: VideoServiceType) => void;
}

export const ServiceSelector: React.FC<ServiceSelectorProps> = ({
  selectedService,
  onServiceChange
}) => {
  const services = VideoServiceFactory.getAllServices();

  return (
    <div className="service-selector">
      <h3>Select Video Service</h3>
      <div className="service-grid">
        {services.map(service => (
          <div
            key={service.type}
            className={`service-card ${selectedService === service.type ? 'selected' : ''}`}
            onClick={() => onServiceChange(service.type)}
          >
            <h4>{service.name}</h4>
            <p>{service.description}</p>
          </div>
        ))}
      </div>
    </div>
  );
};