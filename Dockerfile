# Use an official Ubuntu image as a base
FROM ubuntu:22.04

# Avoid tzdata prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive

# Update system and install necessary dependencies for Flutter and Android SDK
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        git \
        unzip \
        xz-utils \
        zip \
        libglu1-mesa \
        openjdk-17-jdk \
        wget \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Set Environment Variables
ENV ANDROID_SDK_ROOT=/opt/android-sdk \
    FLUTTER_HOME=/opt/flutter \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$FLUTTER_HOME/bin

# Install Android SDK Command Line Tools
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O android_tools.zip && \
    unzip -q android_tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools && \
    mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    rm android_tools.zip

# Accept all Android SDK licenses
RUN yes | sdkmanager --licenses

# Install essential Android SDK packages (matching standard modern Flutter requirements)
RUN sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Install Flutter SDK from the stable channel
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME

# Run flutter doctor to trigger Dart SDK download and accept licenses
RUN flutter config --no-analytics && \
    flutter doctor -v

# Set up the working directory inside the container
WORKDIR /app

# Copy the pubspec logic to get packages without needing all source files yet
COPY pubspec.* ./
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Build the Android App Bundle (AAB) tailored for the Google Play Store
RUN flutter build appbundle --release

# The built AAB will be available at /app/build/app/outputs/bundle/release/app-release.aab
# The apk equivalent is at /app/build/app/outputs/flutter-apk/app-release.apk

# Container command (keep running so artifacts can be easily copied out)
CMD ["echo", "✅ Build complete! Artifacts are available in /app/build/app/outputs/"]
