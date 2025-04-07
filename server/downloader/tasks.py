import os
import tempfile
from django.conf import settings
from celery import shared_task
from django.utils import timezone
from django.core.files.base import ContentFile
from .models import LinkedInVideo, VideoMetadata, HashTag
from .utils.linkedin_downloader import LinkedInDownloader
from .utils.metadata_extractor import MetadataExtractor
import logging

# Setup logging
logger = logging.getLogger(__name__)

@shared_task
def download_linkedin_video(video_id):
    """
    Background task to download a LinkedIn video and extract metadata
    
    Args:
        video_id: UUID of the LinkedInVideo object
    """
    try:
        # Get the video object
        video_obj = LinkedInVideo.objects.get(id=video_id)
        
        # Update status to processing
        video_obj.status = 'processing'
        video_obj.save(update_fields=['status'])
        
        # Initialize downloader and metadata extractor
        downloader = LinkedInDownloader(headless=True, timeout=15)
        extractor = MetadataExtractor()
        
        try:
            # Extract URL metadata first
            url_metadata = extractor.extract_url_metadata(video_obj.post_url)
            
            # Update basic metadata fields
            if 'title' in url_metadata:
                video_obj.title = url_metadata.get('title')
            if 'description' in url_metadata:
                video_obj.description = url_metadata.get('description')
            video_obj.extracted_at = timezone.now()
            video_obj.save(update_fields=['title', 'description', 'extracted_at'])
            
            # Create basic metadata object right away so frontend can access it
            metadata_obj, created = VideoMetadata.objects.get_or_create(video=video_obj)
            
            # Add open graph and twitter card data
            if 'open_graph' in url_metadata:
                metadata_obj.open_graph = url_metadata['open_graph']
            if 'twitter_card' in url_metadata:
                metadata_obj.twitter_card = url_metadata['twitter_card']
            metadata_obj.save()
            
            # Setup the browser
            if not downloader.setup_driver():
                raise Exception("Failed to initialize WebDriver")
            
            # Login if credentials provided
            if video_obj.linkedin_email and video_obj.linkedin_password:
                login_success = downloader.login_to_linkedin(
                    video_obj.linkedin_email, video_obj.linkedin_password
                )
                if not login_success:
                    logger.warning(f"LinkedIn login failed for video {video_id}")
            
            # Extract post metadata
            post_metadata = extractor.extract_post_metadata(downloader.driver, video_obj.post_url)
            
            # Extract video URL
            video_url = downloader.extract_video_url(video_obj.post_url)
            
            if not video_url:
                raise Exception("Could not extract video URL from the post")
            
            # Extract video URL metadata
            video_url_metadata = extractor.extract_video_metadata(video_url)
            
            # Download the video to a temporary file
            with tempfile.NamedTemporaryFile(delete=False, suffix='.mp4') as temp_file:
                temp_path = temp_file.name
            
            # Download the actual video
            download_success, file_size_mb = downloader.download_video(video_url, temp_path)
            
            if not download_success:
                raise Exception("Failed to download video")
            
            # Save the video file to the model
            with open(temp_path, 'rb') as f:
                video_filename = f"linkedin_video_{video_id}.mp4"
                video_obj.video_file.save(video_filename, ContentFile(f.read()), save=False)
            
            # Update file size
            video_obj.file_size = file_size_mb
            
            # Save all metadata to VideoMetadata model
            metadata_obj, created = VideoMetadata.objects.get_or_create(video=video_obj)
            
            # Update with post metadata
            for key, value in post_metadata.items():
                if key != 'hashtags' and hasattr(metadata_obj, key):
                    setattr(metadata_obj, key, value)
            
            # Update with video URL metadata
            for key, value in video_url_metadata.items():
                if hasattr(metadata_obj, key):
                    setattr(metadata_obj, key, value)
            
            # Save open graph and twitter card data
            if 'open_graph' in url_metadata:
                metadata_obj.open_graph = url_metadata['open_graph']
            if 'twitter_card' in url_metadata:
                metadata_obj.twitter_card = url_metadata['twitter_card']
            
            # Save the metadata
            metadata_obj.save()
            
            # Process hashtags
            if 'hashtags' in post_metadata and post_metadata['hashtags']:
                for tag_name in post_metadata['hashtags']:
                    hashtag, _ = HashTag.objects.get_or_create(name=tag_name)
                    video_obj.hashtags.add(hashtag)
            
            # Update status to completed
            video_obj.status = 'completed'
            video_obj.save()
            
            # Delete temporary file
            if os.path.exists(temp_path):
                os.unlink(temp_path)
                
            logger.info(f"Successfully processed LinkedIn video {video_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error processing video {video_id}: {e}")
            video_obj.status = 'failed'
            video_obj.error_message = str(e)
            video_obj.save(update_fields=['status', 'error_message'])
            return False
            
        finally:
            # Always close the browser
            downloader.close()
    
    except LinkedInVideo.DoesNotExist:
        logger.error(f"LinkedInVideo with id {video_id} does not exist")
        return False
    except Exception as e:
        logger.error(f"Unexpected error in download_linkedin_video task: {e}")
        return False