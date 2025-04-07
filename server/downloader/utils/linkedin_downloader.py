import os
import time
import requests
import re
import json
import logging
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Setup logging
logger = logging.getLogger(__name__)

class LinkedInDownloader:
    """Class to handle LinkedIn video downloading with Selenium"""
    
    def __init__(self, headless=True, timeout=15):
        """Initialize the downloader with options"""
        self.headless = headless
        self.timeout = timeout
        self.driver = None
    
    def setup_driver(self):
        """Setup and return a configured Chrome WebDriver"""
        chrome_options = Options()
        if self.headless:
            chrome_options.add_argument("--headless")
        
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36")
        
        try:
            # Try a simpler approach to initialize the driver
            try:
                # First attempt: Use ChromeDriverManager but with more explicit options
                driver_path = ChromeDriverManager().install()
                logger.info(f"Using ChromeDriver from path: {driver_path}")
                service = Service(executable_path=driver_path)
                self.driver = webdriver.Chrome(service=service, options=chrome_options)
                return True
            except Exception as e1:
                logger.warning(f"First attempt to initialize ChromeDriver failed: {e1}")
                
                # Second attempt: Try with default Chrome installation
                try:
                    self.driver = webdriver.Chrome(options=chrome_options)
                    return True
                except Exception as e2:
                    logger.warning(f"Second attempt to initialize ChromeDriver failed: {e2}")
                    raise Exception(f"Could not initialize ChromeDriver: {e1}; {e2}")
        except Exception as e:
            logger.error(f"Error initializing Chrome WebDriver: {e}")
            return False
    
    def login_to_linkedin(self, email, password):
        """Login to LinkedIn with provided credentials"""
        if not self.driver:
            if not self.setup_driver():
                return False
        
        logger.info("Logging in to LinkedIn...")
        self.driver.get("https://www.linkedin.com/login")
        
        try:
            # Wait for email field and enter email
            email_elem = WebDriverWait(self.driver, self.timeout).until(
                EC.presence_of_element_located((By.ID, "username"))
            )
            email_elem.send_keys(email)
            
            # Enter password
            password_elem = self.driver.find_element(By.ID, "password")
            password_elem.send_keys(password)
            
            # Click login button
            self.driver.find_element(By.XPATH, "//button[@type='submit']").click()
            
            # Wait for login to complete
            WebDriverWait(self.driver, self.timeout).until(
                EC.presence_of_element_located((By.ID, "global-nav"))
            )
            logger.info("Successfully logged in to LinkedIn")
            return True
        except Exception as e:
            logger.error(f"Login failed: {e}")
            return False
    
    def extract_video_url(self, post_url):
        """Extract video URL from LinkedIn post"""
        if not self.driver:
            if not self.setup_driver():
                return None
        
        logger.info(f"Navigating to post: {post_url}")
        self.driver.get(post_url)
        
        try:
            logger.info("Waiting for video element...")
            WebDriverWait(self.driver, self.timeout).until(
                EC.presence_of_element_located((By.TAG_NAME, "video"))
            )
            
            # Let the page fully load
            time.sleep(5)
            
            # Try to find video element
            video_elements = self.driver.find_elements(By.TAG_NAME, "video")
            if not video_elements:
                logger.info("No video found in the post")
                return None
            
            # Get the source URL of the first video
            video_url = video_elements[0].get_attribute("src")
            
            # If src is not available, try to find it in the page source
            if not video_url:
                logger.info("Direct video source not found, searching in page source...")
                page_source = self.driver.page_source
                
                # Look for video URLs in the page
                data_sources = re.findall(r'data-sources="([^"]*)"', page_source)
                if data_sources:
                    # Clean and parse the data-sources attribute
                    data_json = data_sources[0].replace('&quot;', '"')
                    sources = json.loads(data_json)
                    if isinstance(sources, list) and len(sources) > 0:
                        highest_quality = max(sources, key=lambda x: x.get('quality', 0) if isinstance(x, dict) else 0)
                        video_url = highest_quality.get('src')
                
                # If still not found, look for other patterns
                if not video_url:
                    # Try to find dms-src attribute
                    dms_src = re.findall(r'dms-src="([^"]*)"', page_source)
                    if dms_src:
                        video_url = dms_src[0].replace('&amp;', '&')
            
            if video_url:
                logger.info(f"Found video URL: {video_url}")
            else:
                logger.warning("Could not extract video URL")
                
            return video_url
        
        except Exception as e:
            logger.error(f"Error extracting video URL: {e}")
            return None
    
    def download_video(self, video_url, output_path):
        """Download video from the extracted URL"""
        if not video_url:
            logger.error("No valid video URL found to download")
            return False, 0
        
        try:
            logger.info(f"Downloading video from: {video_url}")
            response = requests.get(video_url, stream=True)
            response.raise_for_status()
            
            # Create output directory if it doesn't exist
            os.makedirs(os.path.dirname(output_path) if os.path.dirname(output_path) else '.', exist_ok=True)
            
            # Save the video with progress reporting
            file_size = int(response.headers.get('content-length', 0))
            downloaded = 0
            chunk_size = 1024 * 1024  # 1MB chunks
            
            with open(output_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=chunk_size):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        
                        # Log progress at 25% intervals
                        if file_size > 0:
                            percent = int(100 * downloaded / file_size)
                            if percent % 25 == 0:
                                logger.info(f"Download progress: {percent}% ({downloaded / (1024 * 1024):.1f}MB / {file_size / (1024 * 1024):.1f}MB)")
            
            # Calculate file size in MB
            file_size_mb = os.path.getsize(output_path) / (1024 * 1024)
            logger.info(f"Video downloaded successfully to: {output_path} ({file_size_mb:.2f}MB)")
            return True, file_size_mb
        
        except Exception as e:
            logger.error(f"Error downloading video: {e}")
            return False, 0
    
    def close(self):
        """Close the WebDriver"""
        if self.driver:
            self.driver.quit()
            self.driver = None