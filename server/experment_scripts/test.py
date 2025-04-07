import os
import time
import requests
import re
import json
from metadata import *
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Import from metadata module
# from linkedin_metadata import (
#     extract_url_metadata, 
#     extract_post_metadata, 
#     extract_video_metadata,
#     print_metadata,
#     save_metadata_to_json
# )

# ============= CONFIGURATION - MODIFY THESE VALUES =============
# LinkedIn post URL containing the video
POST_URL = "https://www.linkedin.com/posts/ashish-gawale_demo-out-now-check-it-out-httpslnkdin-activity-7313868802440495105-SMwB?utm_source=share&utm_medium=member_desktop&rcm=ACoAAB1WuAwBSsDyXR13ddP27zd4Jojvtj-TnKE"

# LinkedIn credentials (optional, but recommended for better access)
LINKEDIN_EMAIL = ""  # Your LinkedIn email
LINKEDIN_PASSWORD = ""  # Your LinkedIn password

# Output file path for the downloaded video
OUTPUT_PATH = "linkedin_video.mp4"

# Output metadata to JSON file (set to empty string to disable)
METADATA_JSON_PATH = "linkedin_metadata.json"

# Additional options
HEADLESS_MODE = True  # Set to False to see the browser window
TIMEOUT_SECONDS = 15  # Wait time for page elements
WEBDRIVER_PATH = ""  # Chrome WebDriver path (leave empty to use system PATH)
# ===============================================================

def login_to_linkedin(driver):
    """Login to LinkedIn with provided credentials"""
    print("Logging in to LinkedIn...")
    driver.get("https://www.linkedin.com/login")
    
    try:
        # Wait for email field and enter email
        email_elem = WebDriverWait(driver, TIMEOUT_SECONDS).until(
            EC.presence_of_element_located((By.ID, "username"))
        )
        email_elem.send_keys(LINKEDIN_EMAIL)
        
        # Enter password
        password_elem = driver.find_element(By.ID, "password")
        password_elem.send_keys(LINKEDIN_PASSWORD)
        
        # Click login button
        driver.find_element(By.XPATH, "//button[@type='submit']").click()
        
        # Wait for login to complete
        WebDriverWait(driver, TIMEOUT_SECONDS).until(
            EC.presence_of_element_located((By.ID, "global-nav"))
        )
        print("Successfully logged in to LinkedIn")
        return True
    except Exception as e:
        print(f"Login failed: {e}")
        return False

def extract_video_url(driver, post_url):
    """Extract video URL from LinkedIn post"""
    print(f"Navigating to post: {post_url}")
    driver.get(post_url)
    
    try:
        print("Waiting for video element...")
        WebDriverWait(driver, TIMEOUT_SECONDS).until(
            EC.presence_of_element_located((By.TAG_NAME, "video"))
        )
        
        # Let the page fully load
        time.sleep(5)
        
        # Try to find video element
        video_elements = driver.find_elements(By.TAG_NAME, "video")
        if not video_elements:
            print("No video found in the post")
            return None
        
        # Get the source URL of the first video
        video_url = video_elements[0].get_attribute("src")
        
        # If src is not available, try to find it in the page source
        if not video_url:
            print("Direct video source not found, searching in page source...")
            page_source = driver.page_source
            
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
            print(f"Found video URL: {video_url}")
        else:
            print("Could not extract video URL")
            
        return video_url
    
    except Exception as e:
        print(f"Error extracting video URL: {e}")
        return None

def download_video(video_url, output_path):
    """Download video from the extracted URL"""
    if not video_url:
        print("No valid video URL found to download")
        return False
    
    try:
        print(f"Downloading video from: {video_url}")
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
                    
                    # Show progress
                    if file_size > 0:
                        percent = int(100 * downloaded / file_size)
                        print(f"Download progress: {percent}% ({downloaded / (1024 * 1024):.1f}MB / {file_size / (1024 * 1024):.1f}MB)", end='\r')
        
        print(f"\nVideo downloaded successfully to: {output_path}")
        return True
    
    except Exception as e:
        print(f"Error downloading video: {e}")
        return False

def main():
    print("LinkedIn Video Downloader")
    print("=" * 50)
    
    # Validate configuration
    if not POST_URL:
        print("ERROR: Please set the POST_URL in the script configuration")
        return
    
    # First extract URL metadata using requests
    print("Extracting URL metadata...")
    url_metadata = extract_url_metadata(POST_URL)
    
    # Setup Chrome options
    chrome_options = Options()
    if HEADLESS_MODE:
        chrome_options.add_argument("--headless")
    
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36")
    
    # Initialize the driver
    try:
        if WEBDRIVER_PATH:
            driver = webdriver.Chrome(executable_path=WEBDRIVER_PATH, options=chrome_options)
        else:
            driver = webdriver.Chrome(options=chrome_options)
    except Exception as e:
        print(f"Error initializing Chrome WebDriver: {e}")
        print("Make sure Chrome and Chrome WebDriver are installed correctly.")
        return
    
    try:
        # Login if credentials provided
        if LINKEDIN_EMAIL and LINKEDIN_PASSWORD:
            login_success = login_to_linkedin(driver)
            if not login_success:
                print("WARNING: Proceeding without login. Some videos may not be accessible.")
        else:
            print("No login credentials provided. Attempting to access without login.")
        
        # Extract post details
        print("Extracting post details...")
        post_metadata = extract_post_metadata(driver, POST_URL)
        
        # Combine all metadata
        combined_metadata = {**url_metadata, **post_metadata}
        
        # Extract and download the video
        video_url = extract_video_url(driver, POST_URL)
        if video_url:
            # Download the video
            download_success = download_video(video_url, OUTPUT_PATH)
            
            if download_success:
                # Extract metadata from video URL
                video_metadata = extract_video_metadata(video_url)
                combined_metadata.update(video_metadata)
                
                # Add video file details
                if os.path.exists(OUTPUT_PATH):
                    file_size = os.path.getsize(OUTPUT_PATH)
                    combined_metadata['video_file_size'] = f"{file_size / (1024 * 1024):.2f} MB"
                    combined_metadata['video_file_path'] = os.path.abspath(OUTPUT_PATH)
        else:
            print("Failed to extract video URL. The post might not contain a video or might require login.")
        
        # Print and save metadata
        print_metadata(combined_metadata)
        if METADATA_JSON_PATH:
            save_metadata_to_json(combined_metadata, METADATA_JSON_PATH)
    
    except Exception as e:
        print(f"An error occurred: {e}")
    
    finally:
        print("Closing browser...")
        driver.quit()

if __name__ == "__main__":
    main()