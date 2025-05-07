# Supabase for Render (Free Plan Compatible)

This is a streamlined Docker image for Supabase that includes core features and is optimized for deployment on Render's free plan. It combines the essential Supabase services (PostgreSQL, Auth, REST API, and API Gateway) into a single container for easier deployment while maintaining minimal resource usage to fit within Render's free tier limits.

## Features

- **PostgreSQL Database**: Full-featured PostgreSQL database with Supabase extensions
- **Authentication (GoTrue)**: User management and authentication service
- **REST API (PostgREST)**: Instant, RESTful API for your PostgreSQL database
- **API Gateway (Kong)**: API management and routing

## Can I Run This on Render's Free Plan?

**Yes!** This version of Supabase has been specifically optimized to run within Render's free plan limitations. The following optimizations have been made:

1. **Reduced Memory Usage**: PostgreSQL configuration has been tuned to use minimal memory
2. **Optimized Disk Usage**: Persistent storage reduced to 1GB to fit within free tier limits
3. **Minimized Dependencies**: Only essential packages are installed to reduce container size
4. **Resource-Efficient Configuration**: Services configured to use fewer workers and connections
5. **Environment Variable Controls**: Memory allocation can be fine-tuned via environment variables

## Local Development

### Prerequisites

- Docker and Docker Compose

### Running Locally

```bash
# Clone the repository
git clone <your-repo-url>
cd supabase-render

# Start the services
docker-compose up -d
```

Once running, you can access:
- API Gateway: http://localhost:8000
- PostgreSQL: localhost:5432 (Username: postgres, Password: postgres)

## Deploying to Render Free Plan

### Option 1: Deploy using Render Blueprint

1. Fork this repository to your GitHub account
2. Create a new Web Service on Render
3. Connect your GitHub repository
4. Select "Docker" as the environment
5. Select "Free" as the plan
6. Configure the following environment variables:
   - `POSTGRES_PASSWORD`: A secure password for PostgreSQL
   - `JWT_SECRET`: A secure secret for JWT token generation
   - `SITE_URL`: Your application's URL
   - `API_EXTERNAL_URL`: Your Render service URL
   - `POSTGRES_SHARED_BUFFERS`: Set to "128MB" for free plan (optional)
   - `POSTGRES_EFFECTIVE_CACHE_SIZE`: Set to "256MB" for free plan (optional)
   - `POSTGRES_WORK_MEM`: Set to "16MB" for free plan (optional)
   - `POSTGRES_MAINTENANCE_WORK_MEM`: Set to "64MB" for free plan (optional)

### Option 2: Deploy using Render's Docker Registry

1. Build and push the Docker image to Render's Docker registry:

```bash
docker build -t registry.render.com/your-render-username/supabase-render .
docker push registry.render.com/your-render-username/supabase-render
```

2. Create a new Web Service on Render using the pushed image

## Environment Variables

| Variable | Description | Default |
|----------|-------------|--------|
| `POSTGRES_PASSWORD` | PostgreSQL password | postgres |
| `JWT_SECRET` | Secret for JWT token generation | your-super-secret-jwt-token-with-at-least-32-characters-long |
| `ANON_KEY` | Anonymous API key | (example key) |
| `SERVICE_ROLE_KEY` | Service role API key | (example key) |
| `SITE_URL` | Your application URL | http://localhost:3000 |
| `API_EXTERNAL_URL` | External API URL | http://localhost:8000 |
| `DISABLE_SIGNUP` | Disable user signup | false |

## Security Considerations

- **Change Default Keys**: Replace all default keys and passwords before deploying to production
- **Environment Variables**: Use Render's environment variables to securely store sensitive information
- **Database Backups**: Set up regular database backups (note: automated backups are not available on the free plan)
- **Resource Monitoring**: Monitor your application's resource usage to ensure it stays within free plan limits

## Limitations

### Free Plan Limitations

When running on Render's free plan, be aware of these limitations:

- 512 MB memory limit
- 0.1 CPU allocation
- Automatic spin-down after 15 minutes of inactivity
- 750 hours of runtime per month
- 1 GB of persistent disk storage

### Feature Limitations

This streamlined version includes only the core Supabase services. The following features are not included:

- Storage API (for file storage)
- Realtime API (for real-time subscriptions)
- Edge Functions
- Studio UI (admin dashboard)

If you need these features, consider using the full Supabase platform or the complete self-hosted version on a paid Render plan.

## License

This project is licensed under the MIT License - see the LICENSE file for details.