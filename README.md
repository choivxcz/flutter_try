# Barangay-Disaster-Aid-Allocator-Full-System-
This repository helps people who are in need when in times of Disasters. It shows who will be prioritized in rescues based on their information.
Hi

## AI Backend Setup

The final project chat/image features now go through a small Vercel serverless backend instead of calling OpenRouter directly from the app.

Set the OpenRouter key in your Vercel project environment variables:

```powershell
OPENROUTER_API_KEY=your_openrouter_key
```

Deploy the `api/` folder to Vercel, then point the Flutter app at the deployed API base URL:

```powershell
flutter run --dart-define=OPENROUTER_BACKEND_URL=https://your-project.vercel.app/api
```

The app will fail fast if `OPENROUTER_BACKEND_URL` is missing.