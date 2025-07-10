import React from 'react';
import { VideoServiceType, ServiceConfig, ConfigField } from '../types';
import { VideoServiceFactory } from '../services';

interface ConfigFormProps {
  serviceType: VideoServiceType;
  config: Partial<ServiceConfig>;
  onConfigChange: (config: Partial<ServiceConfig>) => void;
}

export const ConfigForm: React.FC<ConfigFormProps> = ({
  serviceType,
  config,
  onConfigChange
}) => {
  const service = VideoServiceFactory.getService(serviceType);

  const handleFieldChange = (fieldName: string, value: string) => {
    onConfigChange({
      ...config,
      [fieldName]: value
    });
  };

  const renderField = (field: ConfigField) => {
    const rawValue = config[field.name];
    const value = typeof rawValue === 'string' ? rawValue : '';

    return (
      <div key={field.name} className="form-field">
        <label htmlFor={field.name}>
          {field.label}
          {field.required && <span className="required">*</span>}
        </label>
        <input
          type={field.type}
          id={field.name}
          name={field.name}
          value={value}
          placeholder={field.placeholder}
          onChange={(e) => handleFieldChange(field.name, e.target.value)}
          required={field.required}
        />
        {field.description && (
          <small className="field-description">{field.description}</small>
        )}
      </div>
    );
  };

  return (
    <div className="config-form">
      <h3>Configure {service.name}</h3>
      <form>
        {service.configFields.map(renderField)}
      </form>
    </div>
  );
};