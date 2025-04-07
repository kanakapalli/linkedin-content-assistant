from django.urls import path
from .views import LinkedInVideoView, TaskStatusView

urlpatterns = [
    path('linkedin-video/', LinkedInVideoView.as_view(), name='linkedin-video'),
    path('task-status/', TaskStatusView.as_view(), name='task-status'),
]