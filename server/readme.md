# LinkedIn Video Downloader API

This Django application provides an API for downloading videos from LinkedIn posts, extracting metadata, and storing both in a database.

## Setup Instructions

### Prerequisites

- Python 3.8 or later
- Redis (for Celery background tasks)
- Chrome browser and ChromeDriver (for Selenium)

### Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd linkedin-video-api
```

2. Create a virtual environment and activate it:

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install required dependencies:

```bash
pip install -r requirements.txt
```

4. Set up environment variables:

```bash
cp .env.example .env
# Edit .env with your specific configuration
```

5. Run database migrations:

```bash
python manage.py migrate
```

6. Create a superuser:

```bash
python manage.py createsuperuser
```

7. Create necessary directories:

```bash
mkdir -p media/linkedin_videos logs
```

### Running the Application

1. Start Redis server (if not already running):

```bash
redis-server
```

2. Start Celery worker:

```bash
celery -A linkedin_api worker --loglevel=info
```

3. Start Django development server:

```bash
python manage.py runserver
```

## API Endpoints

### Authentication

The API uses Basic Authentication. You'll need to include your credentials in the requests or use the login page at:

- `/api-auth/login/`

### API Documentation

Browse interactive API documentation:

- Swagger UI: `/api/docs/`
- ReDoc: `/api/redoc/`

### Video Download Endpoints

#### Create a new download request

```
POST /api/v1/videos/
```

Request body:
```json
{
  "post_url": "https://www.linkedin.com/posts/example_post",
  "linkedin_email": "your_email@example.com",  // Optional
  "linkedin_password": "your_password"        // Optional
}
```

Response:
```json
{
  "id": "uuid-string",
  "post_url": "https://www.linkedin.com/posts/example_post",
  "status": "pending",
  "created_at": "2025-04-04T12:00:00Z",
  ...
}
```

#### Check download status

```
GET /api/v1/videos/{video_id}/status/
```

Response:
```json
{
  "status": "completed",  // pending, processing, completed, or failed
  "error": "Error message if status is failed"  // Only present if status is failed
}
```

#### Get video metadata

```
GET /api/v1/videos/{video_id}/metadata/
```

Response:
```json
{
  "author_name": "Example Company",
  "author_headline": "Example Headline",
  "post_text": "Example post content...",
  "published_date": "2 weeks ago",
  "likes_count": "123",
  "comments_count": "45",
  "embed_id": "12345",
  ...
}
```

#### Retry a failed download

```
POST /api/v1/videos/{video_id}/retry/
```

Response:
```json
{
  "message": "Download retry initiated"
}
```

#### Get all videos

```
GET /api/v1/videos/
```

Response:
```json
{
  "count": 10,
  "next": "http://localhost:8000/api/v1/videos/?page=2",
  "previous": null,
  "results": [
    {
      "id": "uuid-string",
      "post_url": "https://www.linkedin.com/posts/example_post",
      "status": "completed",
      ...
    },
    ...
  ]
}
```

### Admin Interface

Access the admin interface to manage videos and view detailed metadata:

```
/admin/
```

## Security Considerations

- LinkedIn credentials are stored in the database for authentication during download
- In a production environment, consider:
  - Adding proper encryption for credentials
  - Implementing more robust authentication for the API
  - Setting up HTTPS
  - Configuring proper access permissions for uploaded videos

## Troubleshooting

Common issues:

1. **Selenium browser doesn't start**: Make sure Chrome and ChromeDriver are installed and compatible
2. **Celery worker doesn't process tasks**: Check that Redis is running
3. **Video download fails**: LinkedIn's structure may change; check the error message and update selectors if needed