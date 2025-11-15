# Python Example for NeoAI
# This file demonstrates various Python code patterns that NeoAI can help with

import os
import sys
from typing import List, Dict, Optional
import json
import logging

# Function with type hints and docstring
def calculate_average(numbers: List[float]) -> Optional[float]:
    """
    Calculate the average of a list of numbers.
    
    Args:
        numbers: List of numbers to average
        
    Returns:
        Average value or None if list is empty
        
    Raises:
        ValueError: If any number is invalid
    """
    if not numbers:
        return None
    
    try:
        return sum(numbers) / len(numbers)
    except (TypeError, ValueError) as e:
        logging.error(f"Error calculating average: {e}")
        raise ValueError("Invalid numbers in list")

# Class definition with methods
class DataProcessor:
    """A class for processing data files."""
    
    def __init__(self, config_path: str):
        self.config_path = config_path
        self.config = self._load_config()
        self.data = []
    
    def _load_config(self) -> Dict:
        """Load configuration from file."""
        try:
            with open(self.config_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            logging.warning(f"Config file not found: {self.config_path}")
            return {}
    
    def process_data(self, data: List[Dict]) -> List[Dict]:
        """Process data according to configuration."""
        processed = []
        for item in data:
            if self._validate_item(item):
                processed.append(self._transform_item(item))
        return processed
    
    def _validate_item(self, item: Dict) -> bool:
        """Validate a data item."""
        required_fields = self.config.get('required_fields', [])
        return all(field in item for field in required_fields)
    
    def _transform_item(self, item: Dict) -> Dict:
        """Transform a data item."""
        transformations = self.config.get('transformations', {})
        transformed = item.copy()
        
        for field, transform in transformations.items():
            if field in transformed:
                if transform == 'upper':
                    transformed[field] = str(transformed[field]).upper()
                elif transform == 'lower':
                    transformed[field] = str(transformed[field]).lower()
        
        return transformed

# Async function example
import asyncio

async def fetch_data(urls: List[str]) -> Dict[str, str]:
    """
    Fetch data from multiple URLs asynchronously.
    
    Args:
        urls: List of URLs to fetch
        
    Returns:
        Dictionary mapping URL to response content
    """
    results = {}
    
    async def fetch_single(url: str) -> tuple:
        try:
            # Simulate async request
            await asyncio.sleep(0.1)
            return url, f"Response from {url}"
        except Exception as e:
            return url, f"Error: {e}"
    
    tasks = [fetch_single(url) for url in urls]
    completed = await asyncio.gather(*tasks)
    
    for url, response in completed:
        results[url] = response
    
    return results

# Context manager example
class Timer:
    """Context manager for timing code execution."""
    
    def __init__(self, description: str = "Operation"):
        self.description = description
        self.start_time = None
        self.end_time = None
    
    def __enter__(self):
        import time
        self.start_time = time.time()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        import time
        self.end_time = time.time()
        duration = self.end_time - self.start_time
        print(f"{self.description} took {duration:.4f} seconds")

# Decorator example
def retry(max_attempts: int = 3, delay: float = 1.0):
    """Decorator to retry function calls."""
    def decorator(func):
        def wrapper(*args, **kwargs):
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts - 1:
                        raise e
                    logging.warning(f"Attempt {attempt + 1} failed: {e}")
                    import time
                    time.sleep(delay)
        return wrapper
    return decorator

# Example usage
if __name__ == "__main__":
    # Test the average calculation
    numbers = [1, 2, 3, 4, 5]
    avg = calculate_average(numbers)
    print(f"Average: {avg}")
    
    # Test the data processor
    processor = DataProcessor("config.json")
    data = [{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}]
    processed = processor.process_data(data)
    print(f"Processed data: {processed}")
    
    # Test the timer
    with Timer("Data processing"):
        result = sum(range(1000000))
    
    # Test async function
    async def main():
        urls = ["http://example.com/1", "http://example.com/2"]
        results = await fetch_data(urls)
        print(f"Async results: {results}")
    
    asyncio.run(main())