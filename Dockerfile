# Use Ubuntu 24.04 (Noble Numbat) as base to match VPS
FROM ubuntu:24.04

# ==============================================================================
# 1. Environment Variables
# ==============================================================================
ENV DEBIAN_FRONTEND=noninteractive \
    # Node Version
    NODE_VERSION="22.5.1" \
    # Java
    JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64" \
    # Android SDK
    ANDROID_HOME="/opt/android-sdk" \
    ANDROID_SDK_ROOT="/opt/android-sdk" \
    # Centralized Gradle Cache for speed across multiple projects
    GRADLE_USER_HOME="/opt/gradle" \
    # Versions
    ANDROID_CMDLINE_TOOLS_VERSION="11076708" \
    ANDROID_BUILD_TOOLS_VERSION="35.0.0" \
    ANDROID_PLATFORM_VERSION="android-35" \
    ANDROID_NDK_VERSION="27.1.12297006" \
    # React Native build variables
    # Increased heap to 12GB since VPS has 16GB RAM.
    GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs=\"-Xmx12g -XX:MaxMetaspaceSize=1g\""

# Update PATH to include Android tools and Node
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools"

# ==============================================================================
# 2. Install System Dependencies, JDK 17, and Tools
# ==============================================================================
# Added xz-utils for Node extraction
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    unzip \
    wget \
    curl \
    git \
    ccache \
    ninja-build \
    ca-certificates \
    xz-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# 3. Install Node.js 22.5.1 Manually
# ==============================================================================
# Since we are using Ubuntu 24.04 base, we pull the specific Node binary
RUN curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
    | tar -xJ -C /usr/local --strip-components=1

# Enable Corepack to get pnpm
RUN npm install -g pnpm@8.15.2

# ==============================================================================
# 4. Install Android SDK Command Line Tools
# ==============================================================================
WORKDIR ${ANDROID_HOME}

# Download Command Line Tools
RUN wget -q "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" -O cmdline-tools.zip \
    && unzip -q cmdline-tools.zip \
    && rm cmdline-tools.zip \
    && mkdir -p cmdline-tools/latest \
    && mv cmdline-tools/bin cmdline-tools/latest/ \
    && mv cmdline-tools/lib cmdline-tools/latest/ \
    && mv cmdline-tools/NOTICE.txt cmdline-tools/latest/ \
    && mv cmdline-tools/source.properties cmdline-tools/latest/

# ==============================================================================
# 5. Accept Licenses & Install SDK Packages
# ==============================================================================
RUN yes | sdkmanager --licenses > /dev/null \
    && sdkmanager \
    "platform-tools" \
    "platforms;${ANDROID_PLATFORM_VERSION}" \
    "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
    "cmake;3.22.1" \
    "ndk;${ANDROID_NDK_VERSION}"

# ==============================================================================
# 6. Install Global Node Packages (EAS CLI)
# ==============================================================================
RUN npm install -g eas-cli expo-cli

# Create the Gradle cache directory so permissions are correct
RUN mkdir -p /opt/gradle

# ==============================================================================
# 7. Final Setup
# ==============================================================================
WORKDIR /monorepo

CMD ["/bin/bash"]