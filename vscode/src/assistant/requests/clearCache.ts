import { RequestHandler } from './request';

export interface ClearCacheResponse {
  success: boolean;
  message: string;
}

export async function clearCache(): Promise<ClearCacheResponse> {
  try {
    const response = await RequestHandler.makeRequest({
      url: 'https://api.neoai.com/cache/clear',
      method: 'DELETE'
    });
    
    return response.data as ClearCacheResponse;
  } catch (error) {
    console.error('Failed to clear cache:', error);
    return { 
      success: false,
      message: 'Failed to clear cache'
    };
  }
}