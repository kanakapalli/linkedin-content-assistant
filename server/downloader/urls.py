from django.urls import path
from .views import LinkedInVideoView, TaskStatusView, VideoDownloadURLView

urlpatterns = [
    path('linkedin-video/', LinkedInVideoView.as_view(), name='linkedin-video'),
    path('task-status/', TaskStatusView.as_view(), name='task-status'),
     path('video-download-url/', VideoDownloadURLView.as_view(), name='video-download-url'),
]