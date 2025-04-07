import requests
from bs4 import BeautifulSoup
import re
import json
import urllib.parse
from datetime import datetime
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def extract_url_metadata(url):
    """Extract metadata from URL using requests and BeautifulSoup"""
    parsed_url = urllib.parse.urlparse(url)
    if not parsed_url.scheme:
        url = 'https://' + url
    
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36'
        }
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        metadata = {
            'url': url,
            'extracted_at': datetime.now().isoformat(),
        }
        
        # Extract title
        title = soup.find('title')
        metadata['title'] = title.text.strip() if title else None
        
        # Extract meta tags
        for meta in soup.find_all('meta'):
            name = meta.get('name') or meta.get('property')
            content = meta.get('content')
            if name and content and (name == 'description' or name == 'keywords' or name == 'author'):
                metadata[name] = content
        
        # Extract Open Graph metadata
        og_metadata = {}
        for meta in soup.find_all('meta', property=lambda x: x and x.startswith('og:')):
            og_metadata[meta['property'][3:]] = meta.get('content', '')
        metadata['open_graph'] = og_metadata
        
        # Extract Twitter Card metadata
        twitter_metadata = {}
        for meta in soup.find_all('meta', attrs={'name': lambda x: x and x.startswith('twitter:')}):
            twitter_metadata[meta['name'][8:]] = meta.get('content', '')
        metadata['twitter_card'] = twitter_metadata
        
        return metadata
        
    except requests.exceptions.RequestException as e:
        print(f"Error extracting URL metadata: {e}")
        return {'error': str(e), 'url': url}

def extract_post_metadata(driver, post_url):
    """Extract post-specific metadata using Selenium"""
    post_metadata = {
        'post_url': post_url,
        'author_name': None,
        'author_headline': None,
        'author_profile_url': None,
        'post_text': None,
        'published_date': None,
        'likes_count': None,
        'comments_count': None,
        'hashtags': []
    }
    
    try:
        # Extract username from URL
        url_parts = urllib.parse.urlparse(post_url)
        path_parts = url_parts.path.split('/')
        if len(path_parts) > 2:
            post_metadata['author_username'] = path_parts[2]
        
        # Try to get author details
        try:

            
            author_element = WebDriverWait(driver, 5).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, ".update-components-actor__name"))
            )
            post_metadata['author_name'] = author_element.text.strip()
            
            headline_element = driver.find_element(By.CSS_SELECTOR, ".update-components-actor__description")
            if headline_element:
                post_metadata['author_headline'] = headline_element.text.strip()
            
            profile_link = driver.find_element(By.CSS_SELECTOR, ".update-components-actor__container a")
            if profile_link:
                post_metadata['author_profile_url'] = profile_link.get_attribute("href")
        except Exception as e:
            print(f"Could not extract author details: {e}")
        
        # Try to get post text
        try:
            text_element = driver.find_element(By.CSS_SELECTOR, ".update-components-text")
            if text_element:
                post_metadata['post_text'] = text_element.text.strip()
                hashtags = re.findall(r'#(\w+)', post_metadata['post_text'])
                post_metadata['hashtags'] = hashtags
        except Exception as e:
            print(f"Could not extract post text: {e}")
        
        # Try to get published date and engagement stats
        try:
            date_element = driver.find_element(By.CSS_SELECTOR, ".update-components-actor__sub-description")
            if date_element:
                post_metadata['published_date'] = date_element.text.strip()
            
            likes_element = driver.find_element(By.CSS_SELECTOR, ".social-details-social-counts__reactions-count")
            if likes_element:
                post_metadata['likes_count'] = likes_element.text.strip()
                
            comments_element = driver.find_element(By.CSS_SELECTOR, ".social-details-social-counts__comments")
            if comments_element:
                post_metadata['comments_count'] = comments_element.text.strip()
        except Exception as e:
            print(f"Could not extract post stats: {e}")
            
        return post_metadata
    except Exception as e:
        print(f"Error extracting post metadata: {e}")
        return post_metadata

def extract_video_metadata(video_url):
    """Extract metadata from video URL"""
    video_metadata = {}
    
    try:
        parsed_url = urllib.parse.urlparse(video_url)
        query_params = urllib.parse.parse_qs(parsed_url.query)
        
        if 'e' in query_params:
            video_metadata['embed_id'] = query_params['e'][0]
        
        if 'mediaId' in query_params:
            video_metadata['media_id'] = query_params['mediaId'][0]
            
        if 'authenticationToken' in query_params:
            token = query_params['authenticationToken'][0]
            if token:
                video_metadata['has_auth_token'] = True
        
        if 'r' in query_params:
            video_metadata['resolution'] = query_params['r'][0]
        elif 'q' in query_params:
            video_metadata['quality'] = query_params['q'][0]
            
        return video_metadata
    
    except Exception as e:
        print(f"Error extracting video URL metadata: {e}")
        return video_metadata

def print_metadata(metadata):
    """Print the extracted metadata in a readable format"""
    print("\n" + "=" * 50)
    print("POST METADATA")
    print("=" * 50)
    
    # First print the sharing metadata (Open Graph & Twitter Card)
    print("\nSHARING METADATA (used when sharing the URL):")
    print("-" * 45)
    
    # Print Open Graph metadata
    if 'open_graph' in metadata and metadata['open_graph']:
        for key, value in metadata['open_graph'].items():
            print(f"og:{key}: {value}")
    
    # Print Twitter Card metadata
    if 'twitter_card' in metadata and metadata['twitter_card']:
        for key, value in metadata['twitter_card'].items():
            print(f"twitter:{key}: {value}")
    
    # Print general metadata
    if 'title' in metadata:
        print(f"Title: {metadata['title']}")
    if 'description' in metadata:
        print(f"Description: {metadata['description']}")
    
    # Print post details
    print("\nPOST DETAILS:")
    print("-" * 45)
    post_keys = ['post_url', 'author_name', 'author_headline', 'author_profile_url', 
                'author_username', 'post_text', 'published_date', 'likes_count', 
                'comments_count']
    
    for key in post_keys:
        if key in metadata and metadata[key]:
            print(f"{key.replace('_', ' ').title()}: {metadata[key]}")
    
    # Print video details
    print("\nVIDEO DETAILS:")
    print("-" * 45)
    video_keys = ['embed_id', 'media_id', 'resolution', 'quality', 'has_auth_token',
                 'video_file_size', 'video_file_path']
    
    for key in video_keys:
        if key in metadata and metadata[key]:
            print(f"{key.replace('_', ' ').title()}: {metadata[key]}")
    
    # Print hashtags
    if 'hashtags' in metadata and metadata['hashtags'] and len(metadata['hashtags']) > 0:
        print(f"\nHashtags: {', '.join(['#' + tag for tag in metadata['hashtags']])}")
    
    print("=" * 50 + "\n")

def save_metadata_to_json(metadata, filepath):
    """Save metadata dictionary to a JSON file"""
    try:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(metadata, f, indent=2, ensure_ascii=False)
        
        print(f"Metadata saved to: {filepath}")
        return True
    except Exception as e:
        print(f"Error saving metadata to JSON: {e}")
        return False