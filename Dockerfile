# Stage 1: Build the base Flutter development image
FROM ubuntu:22.04 AS flutter_dev

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-11-jdk \
    wget \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up Flutter
ENV FLUTTER_VERSION="3.13.9"
ENV FLUTTER_HOME=/usr/local/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Download and install Flutter
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME}

# Run basic check and pre-download development binaries
RUN flutter doctor
RUN flutter config --no-analytics
RUN flutter precache

# Stage 2: Build the Flutter web app
FROM flutter_dev AS builder

# Set working directory
WORKDIR /app

# Copy the Flutter project files
COPY budget/. .

# Get Flutter packages
RUN flutter pub get

# Build the Flutter web app
RUN flutter build web --release

# Stage 3: Create the final nginx image with just the built web files
FROM nginx:alpine

# Copy the built web files from builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
