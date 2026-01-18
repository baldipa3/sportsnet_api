# SportsNet API - Project Documentation

## Overview

SportsNet API is a Phoenix/Elixir GraphQL API for a social sports networking platform. Users can create posts, comment on posts, like content, and connect with others based on shared sports interests and geographic locations.

## Tech Stack

- **Framework**: Phoenix 1.7.21
- **Language**: Elixir ~> 1.14
- **Database**: PostgreSQL (via Ecto 3.10)
- **GraphQL**: Absinthe 1.6 with Relay support
- **Authentication**: bcrypt_elixir + custom token-based auth
- **Testing**: ExUnit with ExMachina factories and Faker
- **Server**: Bandit 1.5
- **Email**: Swoosh 1.5

## Project Structure

```
lib/
├── sportsnet_api/             # Core business logic (contexts)
│   ├── accounts/              # User management
│   │   ├── user.ex            # User schema
│   │   ├── user_token.ex      # Auth tokens
│   │   └── user_notifier.ex   # Email notifications
│   ├── geography/             # Location data
│   │   ├── country.ex
│   │   └── city.ex
│   ├── sports/                # Sports categories
│   │   └── sport.ex
│   ├── social/                # Social features
│   │   ├── post.ex            # User posts
│   │   ├── post_edit.ex       # Post edit history
│   │   ├── comment.ex         # Comments & replies
│   │   ├── comment_edit.ex    # Comment edit history
│   │   ├── like.ex            # Likes for posts/comments
│   │   └── media.ex           # Media attachments
│   ├── media_storage/         # File storage abstractions
│   │   ├── adapter.ex         # Storage adapter behavior
│   │   ├── s3.ex              # AWS S3 implementation
│   │   └── local.ex           # Local filesystem implementation
│   ├── accounts.ex            # Accounts context
│   ├── geography.ex           # Geography context
│   ├── sports.ex              # Sports context
│   ├── social.ex              # Social context
│   └── repo.ex                # Ecto repository
│
└── sportsnet_api_web/         # Web layer
    ├── resolvers/             # GraphQL resolvers
    │   ├── accounts_resolver.ex
    │   ├── geography_resolver.ex
    │   ├── sports_resolver.ex
    │   ├── social_resolver.ex
    │   └── node_resolver.ex   # Relay Node interface
    ├── controllers/           # REST endpoints
    │   └── auth/              # Authentication controllers
    ├── schema.ex              # Main GraphQL schema
    ├── router.ex              # Route definitions
    ├── endpoint.ex            # Phoenix endpoint
    └── user_auth.ex           # Auth plug helpers

test/
├── sportsnet_api/             # Context tests
│   ├── accounts_test.exs
│   ├── geography_test.exs
│   ├── social_test.exs
│   ├── sports_test.exs
│   └── media_storage_test.exs
├── sportsnet_api_web/         # Web layer tests
└── support/                   # Test helpers & factories

priv/
└── repo/
    └── migrations/            # Database migrations
```

## Architecture Patterns

### Context-Driven Design

The application follows Phoenix's context pattern, organizing code into bounded contexts:

- **Accounts**: User registration, authentication, profile management
- **Geography**: Countries and cities
- **Sports**: Sports categories
- **Social**: Posts, comments, likes, media
- **MediaStorage**: File upload and storage abstraction

### GraphQL with Relay

Uses Absinthe with Relay Modern specification:

- Node interface for global object identification
- Connection/Edge pattern for pagination
- Global IDs (base64-encoded type:id)

### Authentication Flow

1. User registers via REST endpoint: `POST /users/register`
2. User logs in via REST endpoint: `POST /users/login` (returns token)
3. Token passed in GraphQL requests via `fetch_api_user` plug
4. Protected GraphQL endpoint at `/graphql` requires authentication
5. Public GraphiQL interface at `/graphiql` (dev only)

## Key Features

### Social Features

- **Posts**: Create posts with caption, media attachments, sport, and city
- **Comments**: Hierarchical comments (replies to posts and other comments)
- **Likes**: Like posts and comments
- **Media**: Upload and attach images/videos to posts
- **Edit History**: Track edits to posts and comments (15-minute edit window)
- **Soft Deletes**: Posts and comments marked as deleted, not removed

### Feed System

- Posts organized by sport + city combination
- Query: `posts_by_city_and_sport(city_slug, sport_slug)`
- Returns connection-based pagination

### Business Rules

- **Edit Window**: Posts and comments can only be edited within 15 minutes of creation
- **Edit History**: All edits tracked with old/new content, user, IP, and timestamp
- **Ownership Verification**: Users can only edit/delete their own content
- **Soft Deletes**: Deleted content remains in database with `deleted_at` timestamp

## Database Schema

### Core Tables

- `users`: User accounts (name, surname, email, hashed_password, city_id, default_sport_id)
- `user_tokens`: Authentication tokens
- `countries`: Country data (name, code)
- `cities`: City data (name, slug, country_id)
- `sports`: Sports categories (name, slug)
- `posts`: User posts (caption, user_id, sport_id, city_id, deleted_at)
- `comments`: Comments and replies (content, user_id, post_id, parent_comment_id, deleted_at)
- `likes`: Likes (user_id, post_id, comment_id) - polymorphic
- `media`: Media attachments (url, media_type, filename, position, post_id)
- `post_edits`: Post edit history (old_caption, new_caption, user_id, post_id, ip_address)
- `comment_edits`: Comment edit history (old_content, new_content, user_id, comment_id, ip_address)

## GraphQL Schema

### Queries

- `node(id: ID!)`: Fetch any object by global ID (Relay)
- `all_sports`: List all sports
- `countries_with_cities`: List countries with nested cities
- `posts_by_city_and_sport(city_slug, sport_slug)`: Get feed for location+sport
- `current_user`: Get authenticated user details

### Mutations

- `complete_user_onboarding(city_id, default_sport_id)`: Set user preferences
- `create_post(caption, sport_id, city_id, media)`: Create new post
- `edit_post(id, caption)`: Edit post within 15-minute window
- `delete_post(id)`: Soft delete post
- `like_post(id, does_like)`: Like or unlike post
- `create_comment(content, post_id, parent_comment_id)`: Create comment/reply
- `edit_comment(id, content)`: Edit comment within 15-minute window
- `delete_comment(id)`: Soft delete comment

### Types

All main types implement the `Node` interface for Relay:

- `User`: name, surname, email, city, default_sport
- `Post`: caption, sport_id, city_id, media, user, comments (connection), post_likes_count, liked_by_current_user, was_edited
- `Comment`: content, user, post_id, parent_comment_id, replies (connection), comment_likes_count, was_edited
- `Media`: url, media_type, filename, position
- `Country`: name, code, cities
- `City`: name, slug, country
- `Sport`: name, slug
- `SportCityFeed`: virtual type combining sport, city, and posts connection

## Testing

### Test Organization

- **Context tests**: `test/sportsnet_api/` - Unit tests for business logic
- **Resolver tests**: `test/sportsnet_api_web/resolvers/` - GraphQL integration tests
- **Test helpers**: `test/support/` - Factories, fixtures, helpers

### Test Utilities

- **ExMachina**: Factory pattern for test data
- **Faker**: Generate realistic fake data
- **DataCase**: Shared test setup with database sandbox

### Recent Test Coverage

- Posts: Create, edit (with validation), delete
- Comments: Create, edit (with validation), delete, replies
- Likes: Like/unlike posts
- Edit window validation (15 minutes)
- Ownership verification
- Content change validation

## Development Commands

```bash
# Setup
mix setup                    # Install deps + setup database

# Development
mix phx.server              # Start server (localhost:4000)
iex -S mix phx.server       # Start with IEx console

# Database
mix ecto.setup              # Create + migrate + seed
mix ecto.reset              # Drop + setup
mix ecto.migrate            # Run migrations
mix ecto.rollback           # Rollback last migration

# Testing
mix test                    # Run all tests
mix test test/path/file.exs # Run specific test file
mix test --trace            # Run with detailed output

# Debugging
require IEx; IEx.pry()      # Add breakpoint in code
```

## Configuration

### Environments

- **dev**: Development with GraphiQL UI, LiveDashboard, code reloading
- **test**: Test environment with database sandbox
- **prod**: Production configuration

### Key Config Files

- `config/config.exs`: Shared configuration
- `config/dev.exs`: Development overrides
- `config/test.exs`: Test overrides
- `config/runtime.exs`: Runtime configuration (database URL, secrets)

## Recent Development

### Latest Features (from git history)

1. **Comment edits**: Edit and delete comments with history tracking
2. **Post edits**: Edit and delete posts with history tracking
3. **Comments system**: Hierarchical comments with replies
4. **Likes**: Like posts and comments
5. **Media uploads**: Attach images to posts

## Common Tasks

### Adding a New GraphQL Mutation

1. Add resolver function in `lib/sportsnet_api_web/resolvers/`
2. Add business logic in appropriate context (e.g., `lib/sportsnet_api/social.ex`)
3. Define mutation in `lib/sportsnet_api_web/schema.ex`
4. Add tests in `test/sportsnet_api_web/resolvers/` and `test/sportsnet_api/`

### Adding a New Database Table

1. Generate migration: `mix ecto.gen.migration create_table_name`
2. Define schema in `lib/sportsnet_api/context/schema.ex`
3. Add functions to context module
4. Add GraphQL type to schema if needed
5. Write tests

### Adding a New Context

1. Create directory: `lib/sportsnet_api/new_context/`
2. Create context module: `lib/sportsnet_api/new_context.ex`
3. Create schemas in context directory
4. Create resolver: `lib/sportsnet_api_web/resolvers/new_context_resolver.ex`
5. Add types/queries/mutations to schema
6. Write tests

## Important Notes

- All timestamps use UTC
- Global IDs are base64-encoded "Type:id" strings
- Edit window is hardcoded to 15 minutes
- Media storage uses adapter pattern (supports S3 and local)
- Authentication uses token-based approach (not session-based)
- GraphQL endpoint requires authentication
- Soft deletes preserve data integrity
- Edit history tracks IP addresses for audit trail

## Troubleshooting

### Common Issues

1. **Migration errors**: Run `mix ecto.reset` to recreate database
2. **GraphQL auth errors**: Ensure token passed in request headers
3. **Test failures**: Check database setup with `mix ecto.create --quiet`
4. **Port conflicts**: Phoenix runs on port 4000 by default

### Useful Mix Tasks

```bash
mix deps.get                # Install dependencies
mix compile                 # Compile project
mix format                  # Format code
mix credo                   # Code analysis (if installed)
mix dialyzer                # Type checking (if installed)
```

## API Endpoints

### REST Endpoints

- `POST /users/register`: Create new user account
- `POST /users/login`: Authenticate and get token
- `DELETE /users/logout`: Invalidate token (requires auth)

### GraphQL Endpoints

- `/graphql`: Main GraphQL endpoint (requires authentication)
- `/graphiql`: Interactive GraphQL IDE (dev only, no auth required)

### Dev Tools

- `/dev/dashboard`: Phoenix LiveDashboard (dev only)
- `/dev/mailbox`: Swoosh email preview (dev only)

## Next Steps / TODO

Check recent commits for ongoing work:

```bash
git log --oneline -10
```

Look for TODO comments in code:

```bash
grep -r "TODO" lib/
```
