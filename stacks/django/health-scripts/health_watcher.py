#!/usr/bin/env python3
"""
Django Health Watcher
Monitors Django application health via HTTP endpoints
"""

import time
import requests
import os
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def check_health(app_name, url):
    """Check if an application is healthy by making HTTP request"""
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            logger.info(f'{app_name}: HEALTHY')
            return True
        else:
            logger.warning(f'{app_name}: UNHEALTHY (HTTP {response.status_code})')
            return False
    except Exception as e:
        logger.error(f'{app_name}: ERROR - {str(e)}')
        return False

def main():
    """Main health monitoring loop"""
    logger.info('Starting Django health watcher...')
    
    # Configuration from environment variables
    apps = [
        ('Jopi', 'http://jopi_app:8000/health/'),
        ('Synergas', 'http://synergas_app:8000/health/')
    ]
    
    # Check interval in seconds (default: 60)
    check_interval = int(os.getenv('HEALTH_CHECK_INTERVAL', '60'))
    
    while True:
        healthy_count = 0
        
        for app_name, url in apps:
            if check_health(app_name, url):
                healthy_count += 1
        
        if healthy_count == len(apps):
            logger.info('All Django apps are healthy')
        else:
            logger.warning(f'Some Django apps are unhealthy! ({healthy_count}/{len(apps)} healthy)')
        
        time.sleep(check_interval)

if __name__ == '__main__':
    main()