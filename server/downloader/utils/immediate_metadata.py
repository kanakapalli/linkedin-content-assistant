import logging
from django.utils import timezone
from ..models import VideoMetadata
from .metadata_extractor import MetadataExtractor

logger = logging.getLogger(__name__)

def extract_immediate_metadata(video_obj):
    """
    Extract basic metadata immediately when a video is created
    This allows the API to return some metadata even before background processing starts
    
    Args:
        video_obj: LinkedInVideo instance
    
    Returns:
        bool: Success status
    """
    try:
        # Initialize metadata extractor
        extractor = MetadataExtractor()
        
        # Extract URL metadata first
        url_metadata = extractor.extract_url_metadata(video_obj.post_url)
        
        # Update basic metadata fields on the video object
        if 'title' in url_metadata:
            video_obj.title = url_metadata.get('title')
        if 'description' in url_metadata:
            video_obj.description = url_metadata.get('description')
        video_obj.extracted_at = timezone.now()
        video_obj.save(update_fields=['title', 'description', 'extracted_at'])
        
        # Create metadata object immediately
        metadata_obj, created = VideoMetadata.objects.get_or_create(video=video_obj)
        
        # Add open graph and twitter card data
        if 'open_graph' in url_metadata:
            metadata_obj.open_graph = url_metadata['open_graph']
        if 'twitter_card' in url_metadata:
            metadata_obj.twitter_card = url_metadata['twitter_card']
        
        # Extract username from URL if possible
        import re
        import urllib.parse
        
        url_parts = urllib.parse.urlparse(video_obj.post_url)
        path_parts = url_parts.path.split('/')
        if len(path_parts) > 2:
            metadata_obj.author_username = path_parts[2]
        
        metadata_obj.save()
        return True
    
    except Exception as e:
        logger.error(f"Error extracting immediate metadata: {e}")
        return False