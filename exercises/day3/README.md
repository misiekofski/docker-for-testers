# Day 3 Exercises: Building Custom Images & Dockerfile

## Exercise 3.1: Your First Dockerfile (45 minutes)

### Objective
Create a custom Docker image for a simple test application.

### Instructions

1. **Create a project directory:**
```bash
mkdir simple-web-app
cd simple-web-app
```

2. **Create a simple Python web application:**
```python
# app.py
from http.server import HTTPServer, SimpleHTTPRequestHandler
import json
import os
from urllib.parse import urlparse, parse_qs

class TestHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {
                'status': 'healthy',
                'version': os.environ.get('APP_VERSION', '1.0.0'),
                'environment': os.environ.get('ENVIRONMENT', 'development')
            }
            self.wfile.write(json.dumps(response).encode())
        elif parsed_path.path == '/api/test':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {
                'message': 'Test API is working!',
                'timestamp': '2024-01-01T00:00:00Z'
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            html = """
            <!DOCTYPE html>
            <html>
            <head><title>Test Application</title></head>
            <body>
                <h1>Simple Test Application</h1>
                <p>This is a test application for Docker training.</p>
                <ul>
                    <li><a href="/health">Health Check</a></li>
                    <li><a href="/api/test">Test API</a></li>
                </ul>
            </body>
            </html>
            """
            self.wfile.write(html.encode())

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8000))
    server = HTTPServer(('0.0.0.0', port), TestHandler)
    print(f'Starting server on port {port}...')
    server.serve_forever()
```

3. **Create your first Dockerfile:**
```dockerfile
# Dockerfile
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy application code
COPY app.py .

# Set environment variables
ENV APP_VERSION=1.0.0
ENV ENVIRONMENT=production
ENV PORT=8000

# Expose the port
EXPOSE 8000

# Run the application
CMD ["python", "app.py"]
```

4. **Build the image:**
```bash
docker build -t my-test-app:v1.0 .
```

5. **List images to see your new image:**
```bash
docker images my-test-app
```

6. **Run your custom image:**
```bash
docker run -d --name test-app -p 8080:8000 my-test-app:v1.0
```

7. **Test your application:**
```bash
curl http://localhost:8080
curl http://localhost:8080/health
curl http://localhost:8080/api/test
```

8. **Check the logs:**
```bash
docker logs test-app
```

### Questions to Answer
1. What does each instruction in the Dockerfile do?
2. Why do we use `WORKDIR`?
3. What's the difference between `COPY` and `ADD`?

---

## Exercise 3.2: Dockerfile Instructions Deep Dive (60 minutes)

### Objective
Explore different Dockerfile instructions and their use cases.

### Part A: Environment and Arguments

1. **Create a more complex Dockerfile:**
```dockerfile
# Dockerfile.advanced
# Use ARG for build-time variables
ARG PYTHON_VERSION=3.9
ARG BASE_IMAGE=python:${PYTHON_VERSION}-slim

FROM ${BASE_IMAGE}

# Set build arguments that can be used during build
ARG APP_USER=appuser
ARG APP_UID=1000

# Create a non-root user
RUN groupadd -r ${APP_USER} && \
    useradd -r -g ${APP_USER} -u ${APP_UID} -s /bin/bash ${APP_USER}

# Set environment variables
ENV APP_VERSION=2.0.0
ENV ENVIRONMENT=development
ENV PORT=8000
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        vim \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first (for better layer caching)
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY --chown=${APP_USER}:${APP_USER} . .

# Switch to non-root user
USER ${APP_USER}

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Expose port
EXPOSE ${PORT}

# Use ENTRYPOINT and CMD together
ENTRYPOINT ["python"]
CMD ["app.py"]
```

2. **Create requirements.txt:**
```txt
requests==2.28.0
flask==2.2.0
```

3. **Create improved Flask app:**
```python
# app_flask.py
from flask import Flask, jsonify
import os
import requests
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def home():
    return '''
    <h1>Advanced Test Application</h1>
    <p>Version: {}</p>
    <p>Environment: {}</p>
    <ul>
        <li><a href="/health">Health Check</a></li>
        <li><a href="/api/info">System Info</a></li>
        <li><a href="/api/external">External API Test</a></li>
    </ul>
    '''.format(
        os.environ.get('APP_VERSION', 'unknown'),
        os.environ.get('ENVIRONMENT', 'unknown')
    )

@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'version': os.environ.get('APP_VERSION', 'unknown'),
        'environment': os.environ.get('ENVIRONMENT', 'unknown'),
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/info')
def info():
    return jsonify({
        'python_version': os.sys.version,
        'working_directory': os.getcwd(),
        'environment_variables': {
            k: v for k, v in os.environ.items() 
            if k.startswith('APP_') or k in ['ENVIRONMENT', 'PORT']
        }
    })

@app.route('/api/external')
def external():
    try:
        response = requests.get('https://httpbin.org/json', timeout=5)
        return jsonify({
            'status': 'success',
            'external_api': response.json()
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port, debug=False)
```

4. **Build with custom arguments:**
```bash
docker build -f Dockerfile.advanced -t advanced-app:v2.0 --build-arg PYTHON_VERSION=3.10 .
```

5. **Run and test:**
```bash
docker run -d --name advanced-test -p 8081:8000 -e ENVIRONMENT=testing advanced-app:v2.0 app_flask.py
```

### Part B: Multi-stage Builds

1. **Create a multi-stage Dockerfile:**
```dockerfile
# Dockerfile.multistage
# Build stage
FROM node:16-alpine AS builder

WORKDIR /build

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev dependencies)
RUN npm ci

# Copy source code
COPY src/ ./src/
COPY public/ ./public/

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine AS production

# Copy built files from builder stage
COPY --from=builder /build/dist /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port
EXPOSE 80

# nginx runs as daemon by default
```

2. **Create a simple React-like build setup:**
```bash
mkdir react-test-app
cd react-test-app

# Create package.json
cat > package.json << 'EOF'
{
  "name": "test-app",
  "version": "1.0.0",
  "scripts": {
    "build": "mkdir -p dist && cp -r public/* dist/ && echo 'Build complete'"
  },
  "devDependencies": {
    "webpack": "^5.0.0"
  }
}
EOF

# Create source structure
mkdir -p src public
echo '<h1>Built with Multi-stage Docker!</h1>' > public/index.html

# Create nginx config
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
}
EOF
```

3. **Build multi-stage image:**
```bash
docker build -f ../Dockerfile.multistage -t react-app:multistage .
cd ..
```

4. **Compare image sizes:**
```bash
docker images | grep -E "(advanced-app|react-app)"
```

---

## Exercise 3.3: Image Optimization Techniques (45 minutes)

### Objective
Learn techniques to create smaller, more efficient Docker images.

### Part A: Comparing Image Sizes

1. **Create a "bad" Dockerfile (large image):**
```dockerfile
# Dockerfile.large
FROM ubuntu:20.04

# Install everything without cleanup
RUN apt-get update
RUN apt-get install -y python3 python3-pip
RUN apt-get install -y curl wget git vim nano
RUN apt-get install -y build-essential
RUN pip3 install flask requests numpy pandas

WORKDIR /app
COPY app_flask.py .

EXPOSE 8000
CMD ["python3", "app_flask.py"]
```

2. **Create an optimized Dockerfile:**
```dockerfile
# Dockerfile.optimized
FROM python:3.9-alpine

# Install only necessary packages in one layer
RUN apk add --no-cache curl && \
    pip install --no-cache-dir flask requests

WORKDIR /app

# Copy only what's needed
COPY app_flask.py requirements.txt ./

# Use specific user
RUN adduser -D -s /bin/sh appuser
USER appuser

EXPOSE 8000
CMD ["python", "app_flask.py"]
```

3. **Build both images:**
```bash
docker build -f Dockerfile.large -t large-app .
docker build -f Dockerfile.optimized -t optimized-app .
```

4. **Compare sizes:**
```bash
docker images | grep -E "(large-app|optimized-app)"
```

### Part B: Using .dockerignore

1. **Create unnecessary files:**
```bash
mkdir test-dockerignore
cd test-dockerignore

# Create large unnecessary files
dd if=/dev/zero of=large-file.dat bs=1M count=50
mkdir node_modules
echo "fake module" > node_modules/fake.js
mkdir .git
echo "git data" > .git/HEAD

# Create the app
echo "print('Hello World')" > app.py
```

2. **Create .dockerignore:**
```bash
cat > .dockerignore << 'EOF'
# Version control
.git
.gitignore

# Dependencies
node_modules
*.log

# Large files
*.dat
*.tmp

# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode
.idea
*.swp
*.swo
EOF
```

3. **Create Dockerfile:**
```dockerfile
FROM python:3.9-alpine
WORKDIR /app
COPY . .
CMD ["python", "app.py"]
```

4. **Build and check context size:**
```bash
docker build -t dockerignore-test .
cd ..
```

### Part C: Layer Optimization

1. **Create layer-optimized Dockerfile:**
```dockerfile
# Dockerfile.layers
FROM python:3.9-alpine

# Combine RUN commands to reduce layers
RUN apk add --no-cache \
        curl \
        wget && \
    pip install --no-cache-dir \
        flask \
        requests && \
    adduser -D appuser

# Copy requirements first for better caching
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy code last (changes most frequently)
COPY app_flask.py .

USER appuser
EXPOSE 8000
CMD ["python", "app_flask.py"]
```

2. **Build and examine layers:**
```bash
docker build -f Dockerfile.layers -t layered-app .
docker history layered-app
```

---

## Exercise 3.4: Advanced Dockerfile Features (45 minutes)

### Objective
Explore advanced Dockerfile features for complex testing scenarios.

### Part A: ONBUILD Instructions

1. **Create a base test image with ONBUILD:**
```dockerfile
# Dockerfile.base
FROM python:3.9-alpine

# Install common testing dependencies
RUN pip install --no-cache-dir pytest pytest-cov requests

# Set up common structure
WORKDIR /app
RUN adduser -D testuser

# ONBUILD instructions run when this image is used as base
ONBUILD COPY requirements.txt .
ONBUILD RUN pip install --no-cache-dir -r requirements.txt
ONBUILD COPY . .
ONBUILD RUN chown -R testuser:testuser /app
ONBUILD USER testuser

# Default command for testing
CMD ["pytest", "-v"]
```

2. **Build base image:**
```bash
docker build -f Dockerfile.base -t python-test-base .
```

3. **Create a child project:**
```bash
mkdir test-project
cd test-project

echo "pytest==7.0.0" > requirements.txt

cat > test_sample.py << 'EOF'
def test_addition():
    assert 1 + 1 == 2

def test_string():
    assert "hello" + " world" == "hello world"

def test_list():
    assert [1, 2, 3] == [1, 2, 3]
EOF

# Simple Dockerfile using ONBUILD base
echo "FROM python-test-base" > Dockerfile
```

4. **Build and run child image:**
```bash
docker build -t test-runner .
docker run --rm test-runner
cd ..
```

### Part B: Health Checks and Labels

1. **Create Dockerfile with metadata:**
```dockerfile
# Dockerfile.metadata
FROM python:3.9-alpine

# Add metadata labels
LABEL maintainer="qa-team@company.com"
LABEL version="1.0.0"
LABEL description="QA Test Application"
LABEL team="QA Engineering"
LABEL environment="testing"

# Install dependencies
RUN pip install --no-cache-dir flask requests

WORKDIR /app
COPY app_flask.py .

# Add comprehensive health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Add signal handling
STOPSIGNAL SIGTERM

EXPOSE 8000
CMD ["python", "app_flask.py"]
```

2. **Build and inspect metadata:**
```bash
docker build -f Dockerfile.metadata -t metadata-app .
docker inspect metadata-app --format='{{json .Config.Labels}}' | python -m json.tool
```

3. **Run with health check:**
```bash
docker run -d --name health-test -p 8082:8000 metadata-app
```

4. **Monitor health status:**
```bash
# Wait a moment for health check to run
sleep 35
docker inspect health-test --format='{{.State.Health.Status}}'
docker inspect health-test --format='{{json .State.Health}}' | python -m json.tool
```

---

## Exercise 3.5: Real-world Testing Scenario (60 minutes)

### Objective
Build a complete testing environment with custom images.

### Scenario
Create a testing suite for a web API with:
1. Application image
2. Database setup image
3. Test runner image
4. Load testing image

### Instructions

1. **Create the main application:**
```bash
mkdir api-testing-suite
cd api-testing-suite

# Create API application
cat > api.py << 'EOF'
from flask import Flask, jsonify, request
import sqlite3
import os
from datetime import datetime

app = Flask(__name__)
DATABASE = '/data/test.db'

def init_db():
    if not os.path.exists('/data'):
        os.makedirs('/data')
    
    conn = sqlite3.connect(DATABASE)
    conn.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Add sample data
    conn.execute("INSERT OR IGNORE INTO users (id, name, email) VALUES (1, 'John Doe', 'john@example.com')")
    conn.execute("INSERT OR IGNORE INTO users (id, name, email) VALUES (2, 'Jane Smith', 'jane@example.com')")
    conn.commit()
    conn.close()

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

@app.route('/api/users', methods=['GET'])
def get_users():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    users = conn.execute('SELECT * FROM users').fetchall()
    conn.close()
    return jsonify([dict(user) for user in users])

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.get_json()
    if not data or 'name' not in data or 'email' not in data:
        return jsonify({'error': 'Name and email required'}), 400
    
    conn = sqlite3.connect(DATABASE)
    cursor = conn.execute('INSERT INTO users (name, email) VALUES (?, ?)', 
                         (data['name'], data['email']))
    user_id = cursor.lastrowid
    conn.commit()
    conn.close()
    
    return jsonify({'id': user_id, 'name': data['name'], 'email': data['email']}), 201

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF
```

2. **Create application Dockerfile:**
```dockerfile
# Dockerfile.api
FROM python:3.9-alpine

RUN pip install --no-cache-dir flask

WORKDIR /app
COPY api.py .

# Create volume mount point
RUN mkdir -p /data

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:5000/health || exit 1

EXPOSE 5000
CMD ["python", "api.py"]
```

3. **Create test suite:**
```bash
cat > test_api.py << 'EOF'
import requests
import pytest
import json
import time

BASE_URL = 'http://api:5000'

def wait_for_api():
    """Wait for API to be ready"""
    for _ in range(30):
        try:
            response = requests.get(f'{BASE_URL}/health', timeout=2)
            if response.status_code == 200:
                return True
        except:
            pass
        time.sleep(1)
    return False

def test_api_health():
    """Test API health endpoint"""
    assert wait_for_api(), "API failed to start"
    response = requests.get(f'{BASE_URL}/health')
    assert response.status_code == 200
    data = response.json()
    assert data['status'] == 'healthy'

def test_get_users():
    """Test getting users"""
    response = requests.get(f'{BASE_URL}/api/users')
    assert response.status_code == 200
    users = response.json()
    assert isinstance(users, list)
    assert len(users) >= 2

def test_create_user():
    """Test creating a new user"""
    new_user = {
        'name': 'Test User',
        'email': 'test@example.com'
    }
    response = requests.post(f'{BASE_URL}/api/users', 
                           json=new_user,
                           headers={'Content-Type': 'application/json'})
    assert response.status_code == 201
    user = response.json()
    assert user['name'] == new_user['name']
    assert user['email'] == new_user['email']
    assert 'id' in user

def test_create_user_validation():
    """Test user creation validation"""
    response = requests.post(f'{BASE_URL}/api/users', json={})
    assert response.status_code == 400
EOF
```

4. **Create test runner Dockerfile:**
```dockerfile
# Dockerfile.tests
FROM python:3.9-alpine

RUN pip install --no-cache-dir pytest requests

WORKDIR /tests
COPY test_api.py .

CMD ["pytest", "-v", "--tb=short"]
```

5. **Create load test script:**
```bash
cat > load_test.py << 'EOF'
import requests
import threading
import time
import statistics

BASE_URL = 'http://api:5000'
results = []

def make_request():
    start_time = time.time()
    try:
        response = requests.get(f'{BASE_URL}/api/users', timeout=5)
        duration = time.time() - start_time
        results.append({
            'duration': duration,
            'status_code': response.status_code,
            'success': response.status_code == 200
        })
    except Exception as e:
        duration = time.time() - start_time
        results.append({
            'duration': duration,
            'status_code': 0,
            'success': False,
            'error': str(e)
        })

def run_load_test(num_requests=100, num_threads=10):
    print(f"Starting load test: {num_requests} requests with {num_threads} threads")
    
    # Wait for API
    for _ in range(30):
        try:
            requests.get(f'{BASE_URL}/health', timeout=2)
            break
        except:
            time.sleep(1)
    
    threads = []
    requests_per_thread = num_requests // num_threads
    
    start_time = time.time()
    
    for i in range(num_threads):
        thread = threading.Thread(target=lambda: [make_request() for _ in range(requests_per_thread)])
        threads.append(thread)
        thread.start()
    
    for thread in threads:
        thread.join()
    
    total_time = time.time() - start_time
    
    # Analyze results
    successful_requests = [r for r in results if r['success']]
    failed_requests = [r for r in results if not r['success']]
    
    if successful_requests:
        response_times = [r['duration'] for r in successful_requests]
        avg_response_time = statistics.mean(response_times)
        median_response_time = statistics.median(response_times)
        max_response_time = max(response_times)
        min_response_time = min(response_times)
    else:
        avg_response_time = median_response_time = max_response_time = min_response_time = 0
    
    print(f"\n=== Load Test Results ===")
    print(f"Total requests: {len(results)}")
    print(f"Successful requests: {len(successful_requests)}")
    print(f"Failed requests: {len(failed_requests)}")
    print(f"Success rate: {len(successful_requests)/len(results)*100:.2f}%")
    print(f"Total time: {total_time:.2f}s")
    print(f"Requests per second: {len(results)/total_time:.2f}")
    print(f"Average response time: {avg_response_time:.3f}s")
    print(f"Median response time: {median_response_time:.3f}s")
    print(f"Min response time: {min_response_time:.3f}s")
    print(f"Max response time: {max_response_time:.3f}s")

if __name__ == '__main__':
    run_load_test()
EOF
```

6. **Create load test Dockerfile:**
```dockerfile
# Dockerfile.load
FROM python:3.9-alpine

RUN pip install --no-cache-dir requests

WORKDIR /load
COPY load_test.py .

CMD ["python", "load_test.py"]
```

7. **Build all images:**
```bash
docker build -f Dockerfile.api -t test-api .
docker build -f Dockerfile.tests -t test-runner .
docker build -f Dockerfile.load -t load-tester .
```

8. **Create test network and run tests:**
```bash
# Create network
docker network create test-network

# Start API
docker run -d --name test-api --network test-network -p 5000:5000 test-api

# Wait for API to start
sleep 10

# Run unit tests
docker run --rm --network test-network test-runner

# Run load tests
docker run --rm --network test-network load-tester

# Cleanup
docker stop test-api
docker rm test-api
docker network rm test-network
```

### Verification
- [ ] All images build successfully
- [ ] API starts and health check passes
- [ ] Unit tests pass
- [ ] Load tests complete with results
- [ ] All containers communicate properly

---

## Day 3 Summary & Best Practices

### Key Concepts Learned
1. **Dockerfile Instructions**: FROM, RUN, COPY, ENV, EXPOSE, CMD, ENTRYPOINT
2. **Build Arguments**: ARG for build-time customization
3. **Multi-stage Builds**: Optimizing image size
4. **Image Optimization**: Layer caching, .dockerignore, Alpine images
5. **Advanced Features**: HEALTHCHECK, ONBUILD, Labels
6. **Real-world Applications**: Building complete testing suites

### Dockerfile Best Practices for QA
1. **Use specific base image tags** (not `latest`)
2. **Minimize layers** by combining RUN commands
3. **Copy requirements first** for better caching
4. **Use .dockerignore** to exclude unnecessary files
5. **Add health checks** for monitoring
6. **Use non-root users** for security
7. **Clean up** in the same layer (remove caches, temp files)
8. **Use multi-stage builds** for production images

### Image Size Optimization Tips
- Use Alpine-based images when possible
- Remove package caches in the same RUN layer
- Use `--no-cache-dir` with pip
- Remove development dependencies in production builds
- Use `.dockerignore` to exclude build context

### Security Considerations
- Don't run as root user
- Don't include secrets in images
- Use specific versions for dependencies
- Scan images for vulnerabilities
- Use minimal base images

### Next Day Preview
Tomorrow we'll learn:
- Docker Compose for multi-container applications
- Service orchestration
- Environment-specific configurations
- Testing workflows with Compose

---

**🎉 Excellent work on Day 3!**

You can now build custom Docker images optimized for testing environments!