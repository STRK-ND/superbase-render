# Supabase for Render Free Tier

This repository contains a modified version of Supabase optimized to run on Render's free tier. It includes fallback mechanisms for component downloads and minimal resource usage configurations.

## Modifications

- Optimized PostgreSQL configuration for low memory usage
- Fallback mechanisms for Auth (formerly GoTrue), PostgREST, and Kong services
- Reduced resource consumption for all components
- Error handling for component downloads

## Deployment on Render

1. Fork this repository
2. Create a new Web Service on Render
3. Connect your forked repository
4. Use the following settings:
   - Environment: Docker
   - Build Command: (leave empty)
   - Start Command: (leave empty)

## Environment Variables

You can customize the deployment by setting the following environment variables in Render:

- `POSTGRES_PASSWORD`: Password for PostgreSQL (default: postgres)
- `JWT_SECRET`: Secret for JWT tokens (must be at least 32 characters)
- `SITE_URL`: Your application URL
- `API_EXTERNAL_URL`: External API URL

## Connecting to Cloudflare R2 Storage

To use Cloudflare R2 Storage with this Supabase deployment:

1. Create a Cloudflare R2 bucket
2. Add the following environment variables to your Render service:
   - `R2_ACCESS_KEY_ID`: Your Cloudflare R2 access key ID
   - `R2_SECRET_ACCESS_KEY`: Your Cloudflare R2 secret access key
   - `R2_BUCKET`: Your R2 bucket name
   - `R2_ENDPOINT`: Your R2 endpoint URL (e.g., `https://<account_id>.r2.cloudflarestorage.com`)

## Limitations

This deployment is optimized for Render's free tier and has the following limitations:

- Reduced performance compared to a full Supabase deployment
- Limited storage capacity
- Some features may be disabled or have reduced functionality

## Troubleshooting

If you encounter issues with the deployment:

1. Check the Render logs for error messages
2. Verify that all required environment variables are set correctly
3. Ensure your Render service has sufficient resources allocated