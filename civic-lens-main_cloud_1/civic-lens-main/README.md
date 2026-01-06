# Civic Lens

A municipal service management application that connects citizens and municipal workers.

## Features

- Report municipal issues with photos and location data
- AI-powered pothole detection system
- Worker task management system 
- Real-time updates on service requests

## Performance Optimizations

We've implemented several optimizations to improve app performance:

### Pothole Detection Service
- **Parallel Processing:** Server discovery, image processing, and location services run in parallel to minimize delays
- **Background Processing:** Long-running tasks are moved to the background to keep the UI responsive
- **Location Caching:** Location data is cached to prevent repeated GPS requests
- **Server URL Caching:** ML server discovery results are cached to avoid network scans
- **Optimized Timeouts:** Intelligent timeouts prevent hanging on slow operations

### Image Processing
- **Optimized Image Quality:** Balanced compression settings for faster transfers
- **Non-blocking Operations:** Image processing happens in the background
- **Fast Local Estimation:** Falls back to simplified processing when server is unavailable

### User Experience
- **Improved Visual Feedback:** Enhanced processing indicators show real-time progress
- **Task Completion Flow:** Optimized workflow for field workers to complete tasks
- **Responsive UI:** Background processing ensures the UI remains responsive during complex operations

## Getting Started

For developers working on this project:

1. Install Flutter and set up your development environment
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Configure Firebase as per the instructions in `firebase.json`
5. Run the app with `flutter run`

For more information on Flutter development, visit the
[Flutter documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
