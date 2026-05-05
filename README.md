# Barangay-Disaster-Aid-Allocator-Full-System-
This repository helps people who are in need when in times of Disasters. It shows who will be prioritized in rescues based on their information.
Hi

## AI Backend Setup

The final project chat/image features now go through Firebase Functions instead of calling OpenRouter directly from the app.

Set the OpenRouter key on the backend before deploying:

```powershell
firebase functions:secrets:set OPENROUTER_API_KEY
```

Deploy the function after that:

```powershell
firebase deploy --only functions
```

Note: Firebase Functions deployment requires the Blaze plan, so you will need to upgrade the Firebase project before the deploy step will work.

If you want to point the app at a different backend URL, pass it at build time:

```powershell
flutter run --dart-define=OPENROUTER_BACKEND_URL=https://us-central1-finance-app-9e679.cloudfunctions.net/api
```