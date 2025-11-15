import * as vscode from 'vscode';

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
  warnings: string[];
}

export class DocumentValidator {
  public static validateDocument(document: vscode.TextDocument): ValidationResult {
    const result: ValidationResult = {
      isValid: true,
      errors: [],
      warnings: []
    };
    
    // Check if document is too large
    if (document.getText().length > 1000000) {
      result.isValid = false;
      result.errors.push('Document is too large for processing (>1MB)');
    }
    
    // Check if document is empty
    if (document.getText().trim().length === 0) {
      result.warnings.push('Document is empty');
    }
    
    // Check file type
    const supportedLanguages = ['typescript', 'javascript', 'python', 'java', 'cpp', 'c'];
    if (!supportedLanguages.includes(document.languageId)) {
      result.warnings.push(`Language '${document.languageId}' may not be fully supported`);
    }
    
    return result;
  }
  
  public static validateSelection(document: vscode.TextDocument, selection: vscode.Selection): ValidationResult {
    const result: ValidationResult = {
      isValid: true,
      errors: [],
      warnings: []
    };
    
    const selectedText = document.getText(selection);
    
    // Check if selection is empty
    if (selectedText.trim().length === 0) {
      result.isValid = false;
      result.errors.push('No text selected');
    }
    
    // Check if selection is too large
    if (selectedText.length > 10000) {
      result.warnings.push('Large selection may take longer to process');
    }
    
    return result;
  }
}