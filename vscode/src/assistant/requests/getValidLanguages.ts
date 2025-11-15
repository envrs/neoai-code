import { RequestHandler } from './request';

export interface ValidLanguagesResponse {
  languages: string[];
  supported: boolean;
}

export async function getValidLanguages(): Promise<ValidLanguagesResponse> {
  try {
    const response = await RequestHandler.makeRequest({
      url: 'https://api.neoai.com/languages',
      method: 'GET'
    });
    
    return response.data as ValidLanguagesResponse;
  } catch (error) {
    console.error('Failed to get valid languages:', error);
    return { 
      languages: ['typescript', 'javascript', 'python', 'java', 'cpp', 'c', 'csharp', 'php', 'ruby', 'go'],
      supported: true
    };
  }
}