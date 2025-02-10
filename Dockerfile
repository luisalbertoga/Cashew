# Stage 1 - Build the Flutter web app
FROM cirrusci/flutter:latest AS builder

# Set working directory
WORKDIR /app

# Copy the Flutter project files
COPY budget/. .

# Get Flutter packages
RUN flutter pub get

# Build the Flutter web app
RUN flutter build web --release

# Stage 2 - Create the final nginx image with just the built web files
FROM nginx:alpine

# Copy the built web files from builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy a custom nginx config if needed
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
