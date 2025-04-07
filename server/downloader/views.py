from rest_framework import views, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.shortcuts import get_object_or_404
from .models import LinkedInVideo, VideoMetadata
from .serializers import LinkedInVideoSerializer, LinkedInVideoCreateSerializer
from .tasks import download_linkedin_video
from .utils.immediate_metadata import extract_immediate_metadata

class LinkedInVideoView(views.APIView):
    """
    API endpoint for LinkedIn video downloads
    - POST: Create a new download request and get immediate metadata
    - GET: Get status and complete metadata for a specific video
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        """Create a new LinkedIn video download request and return metadata"""
        serializer = LinkedInVideoCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Create the video object
        video = LinkedInVideo(
            post_url=serializer.validated_data['post_url'],
            linkedin_email=serializer.validated_data.get('linkedin_email', ''),
            linkedin_password=serializer.validated_data.get('linkedin_password', '')
        )
        video.save()
        
        # Extract basic metadata immediately to provide in the response
        extract_immediate_metadata(video)
        
        # Trigger background task for full processing
        download_linkedin_video.delay(str(video.id))
        
        # Return the video object with initial metadata
        return Response(
            LinkedInVideoSerializer(video).data,
            status=status.HTTP_201_CREATED
        )
    
    def get(self, request):
        """Get status and complete metadata for a video"""
        video_id = request.query_params.get('id')
        if not video_id:
            return Response(
                {"error": "Missing required parameter 'id'"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        video = get_object_or_404(LinkedInVideo, id=video_id)
        return Response(LinkedInVideoSerializer(video).data)


class TaskStatusView(views.APIView):
    """
    API endpoint for checking task status
    - GET: Check the status of a LinkedIn video download task
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        """Get status of a download task"""
        video_id = request.query_params.get('id')
        if not video_id:
            return Response(
                {"error": "Missing required parameter 'id'"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        video = get_object_or_404(LinkedInVideo, id=video_id)
        
        # If completed, return full data similar to the LinkedIn video endpoint
        if video.status == 'completed':
            return Response(LinkedInVideoSerializer(video).data)
        
        # For other statuses, return basic status information
        response = {
            "id": str(video.id),
            "status": video.status,
            "created_at": video.created_at,
            "updated_at": video.updated_at
        }
        
        if video.status == 'failed':
            response["error"] = video.error_message
            
        return Response(response)