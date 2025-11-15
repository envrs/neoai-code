import { RequestHandler } from './request';

export interface ValidExtensionsResponse {
  extensions: string[];
  supported: boolean;
}

export async function getValidExtensions(): Promise<ValidExtensionsResponse> {
  try {
    const response = await RequestHandler.makeRequest({
      url: 'https://api.neoai.com/extensions',
      method: 'GET'
    });
    
    return response.data as ValidExtensionsResponse;
  } catch (error) {
    console.error('Failed to get valid extensions:', error);
    return { 
      extensions: ['.ts', '.js', '.py', '.java', '.cpp', '.c', '.cs', '.php', '.rb', '.go'],
      supported: true
    };
  }
}