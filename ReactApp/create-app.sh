#!/bin/bash

# Create the root directory
mkdir -p my-app
cd my-app

# Create .github/workflows directory and deploy.yml file
mkdir -p .github/workflows
cat <<EOL > .github/workflows/deploy.yml
name: Build and Deploy

on:
  push:
    branches:
      - main

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Log in to Docker Hub
        uses: docker/login-action@v2
        with:
          username: \${{ secrets.DOCKER_HUB_USERNAME }}
          password: \${{ secrets.DOCKER_HUB_TOKEN }}

      - name: Build and push frontend
        uses: docker/build-push-action@v3
        with:
          context: ./frontend
          push: true
          tags: your-dockerhub-username/my-app-frontend:latest

      - name: Build and push backend
        uses: docker/build-push-action@v3
        with:
          context: ./backend
          push: true
          tags: your-dockerhub-username/my-app-backend:latest

      - name: Deploy to server
        uses: appleboy/ssh-action@v1
        with:
          host: \${{ secrets.SERVER_HOST }}
          username: \${{ secrets.SERVER_USERNAME }}
          key: \${{ secrets.SERVER_SSH_KEY }}
          script: |
            cd /opt/my-app
            docker-compose pull
            docker-compose up -d
EOL

# Create frontend directory and files
mkdir -p frontend
cd frontend

# Create Dockerfile for frontend
cat <<EOL > Dockerfile
# Build stage
FROM node:18-alpine as build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOL

# Create package.json for frontend
cat <<EOL > package.json
{
  "name": "frontend",
  "version": "1.0.0",
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1",
    "@mui/material": "^5.14.0",
    "@emotion/react": "^11.11.0",
    "@emotion/styled": "^11.11.0"
  }
}
EOL

# Create src and public directories
mkdir src public

# Create a basic React app in src
cat <<EOL > src/index.js
import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';

ReactDOM.render(<App />, document.getElementById('root'));
EOL

cat <<EOL > src/App.js
import React from 'react';
import { Button } from '@mui/material';

function App() {
  return (
    <div>
      <h1>Welcome to My App</h1>
      <Button variant="contained" color="primary">
        Click Me
      </Button>
    </div>
  );
}

export default App;
EOL

# Create a basic index.html in public
cat <<EOL > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My App</title>
</head>
<body>
  <div id="root"></div>
</body>
</html>
EOL

cd ..

# Create backend directory and files
mkdir -p backend
cd backend

# Create Dockerfile for backend
cat <<EOL > Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
EOL

# Create package.json for backend
cat <<EOL > package.json
{
  "name": "backend",
  "version": "1.0.0",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1"
  }
}
EOL

# Create src directory and index.js
mkdir src
cat <<EOL > src/index.js
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.send('Backend is running');
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(\`Server is running on port \${PORT}\`);
});
EOL

# Create .env file
cat <<EOL > .env
PORT=5000
DATABASE_URL=mongodb://mongo:27017/mydb
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
EOL

cd ..

# Create docker-compose.yml
cat <<EOL > docker-compose.yml
version: '3.8'

services:
  frontend:
    image: your-dockerhub-username/my-app-frontend:latest
    ports:
      - "3000:80"
    restart: always

  backend:
    image: your-dockerhub-username/my-app-backend:latest
    ports:
      - "5000:5000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=mongodb://mongo:27017/mydb
    depends_on:
      - mongo

  mongo:
    image: mongo:latest
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db

volumes:
  mongo-data:
EOL

# Create .dockerignore
cat <<EOL > .dockerignore
node_modules
build
.env
EOL

echo "App structure created successfully!"
