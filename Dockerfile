# Use an official Node.js image as a base
FROM node:18-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json before running npm install
COPY package*.json ./

# Verify if package.json is copied correctly
RUN ls -lah /app

# Install production dependencies
RUN npm install --omit=dev

# Copy the rest of the application files
COPY . .

# Expose the port your app runs on
EXPOSE 3000

# Command to start the application
CMD ["npm", "start"]
