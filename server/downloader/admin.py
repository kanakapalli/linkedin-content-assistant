from django.contrib import admin
from .models import LinkedInVideo, VideoMetadata, HashTag

class VideoMetadataInline(admin.StackedInline):
    model = VideoMetadata
    can_delete = False
    verbose_name_plural = 'Video Metadata'
    readonly_fields = [
        'author_name', 'author_headline', 'author_profile_url', 'author_username',
        'post_text', 'published_date', 'likes_count', 'comments_count',
        'embed_id', 'media_id', 'resolution', 'quality', 'has_auth_token',
        'open_graph', 'twitter_card'
    ]

@admin.register(LinkedInVideo)
class LinkedInVideoAdmin(admin.ModelAdmin):
    list_display = ['id', 'title', 'status', 'created_at', 'file_size']
    list_filter = ['status', 'created_at']
    search_fields = ['title', 'post_url', 'id']
    readonly_fields = ['id', 'created_at', 'updated_at', 'extracted_at', 'file_size']
    inlines = [VideoMetadataInline]
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('id', 'post_url', 'status', 'error_message')
        }),
        ('Video Details', {
            'fields': ('title', 'description', 'video_file', 'file_size')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'extracted_at')
        }),
        ('Credentials', {
            'fields': ('linkedin_email', 'linkedin_password'),
            'classes': ('collapse',)
        })
    )

@admin.register(HashTag)
class HashTagAdmin(admin.ModelAdmin):
    list_display = ['name', 'video_count']
    search_fields = ['name']
    
    def video_count(self, obj):
        return obj.videos.count()
    video_count.short_description = 'Videos'