from django.db import models
import uuid
import os
from django.conf import settings

def video_upload_path(instance, filename):
    """Generate file path for LinkedIn video"""
    # Create a unique filename with uuid
    ext = filename.split('.')[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    return os.path.join('linkedin_videos', filename)

class LinkedInVideo(models.Model):
    """Model for LinkedIn video downloads"""
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
    )

    # Base fields
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    post_url = models.URLField(max_length=1000)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    error_message = models.TextField(blank=True, null=True)
    
    # Video file
    video_file = models.FileField(upload_to=video_upload_path, blank=True, null=True)
    file_size = models.FloatField(blank=True, null=True, help_text="Size in MB")
    
    # Basic metadata
    extracted_at = models.DateTimeField(blank=True, null=True)
    title = models.CharField(max_length=500, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    
    # LinkedIn credentials (encrypted in a real app)
    linkedin_email = models.CharField(max_length=255, blank=True, null=True)
    linkedin_password = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = "LinkedIn Video"
        verbose_name_plural = "LinkedIn Videos"

    def __str__(self):
        return f"LinkedIn Video: {self.title or self.post_url}"

class VideoMetadata(models.Model):
    """Model for storing detailed video metadata"""
    video = models.OneToOneField(LinkedInVideo, on_delete=models.CASCADE, related_name='metadata')
    
    # Author info
    author_name = models.CharField(max_length=255, blank=True, null=True)
    author_headline = models.CharField(max_length=500, blank=True, null=True)
    author_profile_url = models.URLField(max_length=1000, blank=True, null=True)
    author_username = models.CharField(max_length=255, blank=True, null=True)
    
    # Post info
    post_text = models.TextField(blank=True, null=True)
    published_date = models.CharField(max_length=100, blank=True, null=True)
    likes_count = models.CharField(max_length=100, blank=True, null=True)
    comments_count = models.CharField(max_length=100, blank=True, null=True)
    
    # Video specific info
    embed_id = models.CharField(max_length=255, blank=True, null=True)
    media_id = models.CharField(max_length=255, blank=True, null=True)
    resolution = models.CharField(max_length=100, blank=True, null=True)
    quality = models.CharField(max_length=100, blank=True, null=True)
    has_auth_token = models.BooleanField(default=False)
    
    # Open Graph and Twitter Card data stored as JSON
    open_graph = models.JSONField(blank=True, null=True)
    twitter_card = models.JSONField(blank=True, null=True)
    
    def __str__(self):
        return f"Metadata for {self.video}"

class HashTag(models.Model):
    """Model for hashtags in LinkedIn posts"""
    name = models.CharField(max_length=100, unique=True)
    videos = models.ManyToManyField(LinkedInVideo, related_name='hashtags')
    
    def __str__(self):
        return f"#{self.name}"