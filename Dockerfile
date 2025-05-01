# 1) Build stage
FROM node:22 AS build
WORKDIR /app

# Set the npm cache to a writable directory (instead of the default root-owned one)
ENV NPM_CONFIG_CACHE=/tmp/.npm
RUN mkdir -p /tmp/.npm

# Copy package.json and package-lock.json first to install dependencies early
COPY package*.json ./

# Install dependencies using npm ci (which needs a valid package-lock.json)
RUN npm ci

# Copy the rest of the application and build it
COPY . .
RUN npm run build

# 2) Production stage
FROM nginx:stable-alpine

# Remove default site content from nginx
RUN rm -rf /usr/share/nginx/html/*

# Copy the built Vue app from the build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Expose port 80 for the nginx server
EXPOSE 80

# Keep nginx running in the foreground
CMD ["nginx", "-g", "daemon off;"]
