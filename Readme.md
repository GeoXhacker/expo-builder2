# High-Performance Expo Android Build (VPS Edition)

This Docker setup is optimized for a 16GB RAM VPS running Node 22.5.1 and NDK 27.1. It uses a shared Gradle cache to ensure fast builds across multiple projects.

## Prerequisites

Docker Engine installed on your VPS.

16GB+ RAM available (Heap is tuned to 12GB).

## Setup (One-Time)

### Build the Image:

Run this once. You can use this single image for all your projects.

docker build -t expo-android-builder .

### Create Shared Cache Volume:

This volume stores Gradle wrappers and Maven dependencies, shared across all builds to save bandwidth and time.

docker volume create gradle_cache_shared

### How to Build (For Multiple Projects)

You don't need to copy the Dockerfile into every project. Instead, navigate to any project folder on your VPS and run the container ephemerally.

### Option 1: The "Power User" Command (Fastest)

Run this from the root of your React Native/Expo project:

docker run --rm -it \
 --name expo-build-runner \
 -v $(pwd):/app \
 -v gradle_cache_shared:/opt/gradle \
 expo-android-builder \
 bash -c "npm install && eas build --platform android --local"

-v $(pwd):/app: Mounts your current project code.

-v gradle_cache_shared:/opt/gradle: Mounts the shared cache.

--rm: Cleans up the container after the build finishes.

### Option 2: Using Docker Compose (Per Project)

If you prefer keeping a config file in each project, place this docker-compose.yml in the project root:

Run the build:

### Interactive mode (recommended for debugging/logging in)

docker-compose run --rm android-build

### Performance Notes

Heap Size: Configured to 12GB. Ensure your VPS isn't running heavyweight background services (like multiple databases) during the build, or the OOM killer might stop the container.

Compiler Cache: The image includes ccache and ninja-build. The first build will be standard speed, but subsequent builds of C++ modules (Hermes/Reanimated) will be significantly faster.

### Troubleshooting

Permission Denied (gradlew):
If the build fails instantly, the gradlew file might have lost execution rights on Windows/Linux transfer.

chmod +x android/gradlew

Login Issues:
If eas build asks for a login, you can pass your token via environment variable in the command:
EXPO_TOKEN=your_token_here docker run ...
