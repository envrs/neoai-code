import { createPromiseClient } from '@connectrpc/connect';
import { createConnectTransport } from '@connectrpc/connect-web';
import { LanguageServerService } from '../proto/language_server_connect';
import { NeoConfig } from '../models';

export const createApiClient = (config: NeoConfig) => {
  const transport = createConnectTransport({
    baseUrl: config.serverUrl,
    interceptors: [
      (next) => async (req) => {
        if (config.apiKey) {
          req.header.set('Authorization', `Bearer ${config.apiKey}`);
        }
        return next(req);
      },
    ],
  });
  return createPromiseClient(LanguageServerService, transport);
};
