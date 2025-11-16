import React, { createContext, useContext, useMemo } from 'react';
import { createApiClient } from '../api/client';
import { NeoConfig } from '../models';

// API Client type from createApiClient return type
type ApiClient = ReturnType<typeof createApiClient>;

interface NeoContextValue {
  config: NeoConfig;
  apiClient: ApiClient;
}

const NeoContext = createContext<NeoContextValue | null>(null);

export interface NeoProviderProps {
  config: NeoConfig;
  children: React.ReactNode;
}

export const NeoProvider: React.FC<NeoProviderProps> = ({ config, children }) => {
  const apiClient = useMemo(() => createApiClient(config), [config]);

  const contextValue = {
    config,
    apiClient,
  };

  return <NeoContext.Provider value={contextValue}>{children}</NeoContext.Provider>;
};

export const useNeo = (): NeoContextValue => {
  const context = useContext(NeoContext);
  if (!context) {
    throw new Error('useNeo must be used within a NeoProvider');
  }
  return context;
};
