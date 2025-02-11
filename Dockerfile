# Use official Node.js image as base
FROM node:18-alpine

# Set working directory inside container
WORKDIR /app

# Copy package.json and package-lock.json first for efficient caching
COPY package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy the entire application code
COPY . .

# Expose the application port (this should match the ECS task definition port)
EXPOSE 3000

# Command to start the application
CMD ["node", "server.js"]
