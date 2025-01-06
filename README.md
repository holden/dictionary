# Rails Application

A Ruby on Rails application that integrates multiple external APIs for content enrichment and data services.

## Integrated Services

### Art & Media Services

#### 1. Artsy API Integration
- Artwork search functionality
- Features:
  - Artwork details retrieval
  - Artist information
  - Image thumbnails
  - Artwork dating
- Includes caching with 1-hour expiration
- Token-based authentication

#### 2. Giphy API Integration
- GIF search capabilities
- Features:
  - Fixed height GIF retrieval
  - Size specifications (width/height)
  - Direct Giphy URLs
- Family-friendly content filtering (G-rated)
- Cached results with 1-hour expiration

### Language & Knowledge Services

#### 3. Datamuse API Integration
- Word relationship service
- Features:
  - Related word lookup
  - Semantic associations
- Includes comprehensive error logging

#### 4. ConceptNet API Integration
- Semantic network service
- Features:
  - General term lookup
  - Specialized person lookup
  - Semantic relationships
- Multi-language support with focus on English

### Quote & Literature Services

#### 5. WikiQuotes Service
- Comprehensive quote search system
- Features:
  - Author-based search
  - Topic-based search
  - Section filtering
  - Quote attribution
  - Context preservation
  - Disputed/misattributed flagging
- Advanced metadata handling
- Caching with 1-hour expiration

#### 6. BrainyQuotes Service
- Quote scraping service
- Features:
  - Author-based quote search
  - Topic categorization
  - Attribution tracking
  - URL preservation
- Includes retry mechanism
- Error handling and logging
- Uses Zyte API for reliable scraping

#### 7. OpenLibrary Service
- Book and author information service
- Features:
  - Author lookup with biographical data
  - Book search with metadata
  - ISBN lookup
  - Publication information
- Comprehensive error handling
- Fuzzy matching for better results

## Authentication & Security

- API key management through Rails credentials
- Rate limiting implementation
- Caching strategies for API responses
- Error handling and logging

## Caching

All services implement caching strategies:
- Default cache duration: 1 hour
- Token caching: 23 hours (Artsy)
- Redis-based caching in production
- File-based caching in development

## Error Handling

- Comprehensive logging for all API interactions
- Retry mechanisms for unstable connections
- Graceful degradation when services are unavailable
- Structured error responses

## Development Setup
