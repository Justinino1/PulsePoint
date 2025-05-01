# 1️⃣ Build Stage
FROM node:22-alpine AS build

# Set working directory
WORKDIR /app

# Set npm cache to writable location
ENV NPM_CONFIG_CACHE=/tmp/.npm

# Create writable npm cache
RUN mkdir -p /tmp/.npm

# Install dependencies early for caching efficiency
COPY package.json package-lock.json ./
RUN npm ci --prefer-offline --no-audit

# Copy the rest of the source and build
COPY . .
RUN npm run build

# 2️⃣ Production Stage with Nginx
FROM nginx:stable-alpine

# Clean default Nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy built files from build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Expose port
EXPOSE 80

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
