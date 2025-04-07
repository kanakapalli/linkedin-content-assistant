from rest_framework import serializers
from .models import LinkedInVideo, VideoMetadata, HashTag

class HashTagSerializer(serializers.ModelSerializer):
    class Meta:
        model = HashTag
        fields = ['name']

class VideoMetadataSerializer(serializers.ModelSerializer):
    class Meta:
        model = VideoMetadata
        exclude = ['id', 'video']

class LinkedInVideoSerializer(serializers.ModelSerializer):
    metadata = VideoMetadataSerializer(read_only=True)
    hashtags = HashTagSerializer(many=True, read_only=True)
    
    class Meta:
        model = LinkedInVideo
        fields = [
            'id', 'post_url', 'status', 'created_at', 'updated_at', 
            'extracted_at', 'title', 'description', 'file_size',
            'video_file', 'metadata', 'hashtags'
        ]
        read_only_fields = [
            'id', 'status', 'created_at', 'updated_at', 
            'extracted_at', 'title', 'description', 'file_size',
            'video_file', 'metadata', 'hashtags'
        ]
    
    def to_representation(self, instance):
        """Include all metadata even if the metadata relation doesn't exist yet"""
        representation = super().to_representation(instance)
        
        # If no metadata relation exists yet, create a default metadata structure
        if representation['metadata'] is None:
            # Try to get URL metadata directly
            from .utils.metadata_extractor import MetadataExtractor
            
            try:
                extractor = MetadataExtractor()
                url_metadata = extractor.extract_url_metadata(instance.post_url)
                
                # Create a basic metadata structure
                metadata = {
                    # Basic metadata from URL
                    'title': url_metadata.get('title'),
                    'description': url_metadata.get('description'),
                    
                    # Author info - empty for now
                    'author_name': None,
                    'author_headline': None,
                    'author_profile_url': None,
                    'author_username': None,
                    
                    # Post info - empty for now
                    'post_text': None,
                    'published_date': None,
                    'likes_count': None,
                    'comments_count': None,
                    
                    # Open Graph and Twitter Card data
                    'open_graph': url_metadata.get('open_graph', {}),
                    'twitter_card': url_metadata.get('twitter_card', {})
                }
                
                representation['metadata'] = metadata
            except Exception:
                # If metadata extraction fails, return null
                representation['metadata'] = None
                
        return representation

class LinkedInVideoCreateSerializer(serializers.ModelSerializer):
    linkedin_email = serializers.CharField(required=False, allow_blank=True, write_only=True)
    linkedin_password = serializers.CharField(required=False, allow_blank=True, write_only=True)
    
    class Meta:
        model = LinkedInVideo
        fields = ['post_url', 'linkedin_email', 'linkedin_password']
    
    def validate_post_url(self, value):
        """Validate that the URL is a LinkedIn post URL"""
        if 'linkedin.com/posts/' not in value:
            raise serializers.ValidationError("URL must be a valid LinkedIn post URL")
        return value

class VideoDownloadURLSerializer(serializers.Serializer):
    url = serializers.URLField(required=True, help_text="LinkedIn post URL containing a video")
    email = serializers.EmailField(required=False, allow_blank=True, help_text="LinkedIn account email for accessing private content")
    password = serializers.CharField(required=False, allow_blank=True, help_text="LinkedIn account password")
    
    def validate_url(self, value):
        """Validate that the URL is a LinkedIn post URL"""
        if 'linkedin.com/posts/' not in value:
            raise serializers.ValidationError("URL must be a valid LinkedIn post URL")
        return value