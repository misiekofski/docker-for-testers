# Day 5 Exercises: CI/CD Integration, Debugging & Production

## Exercise 5.1: CI/CD Pipeline with GitHub Actions (60 minutes)

### Objective
Learn to integrate Docker into CI/CD pipelines for automated testing and deployment.

### Part A: Setting up GitHub Actions

1. **Create GitHub Actions workflow structure:**
```bash
mkdir cicd-project
cd cicd-project
mkdir -p .github/workflows app tests
```

2. **Create simple application:**
```bash
cd app

cat > app.py << 'EOF'
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        'message': 'Hello from Dockerized Flask App!',
        'version': os.environ.get('APP_VERSION', '1.0.0'),
        'environment': os.environ.get('ENVIRONMENT', 'development')
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

@app.route('/api/status')
def status():
    return jsonify({
        'status': 'running',
        'uptime': 'unknown',
        'version': os.environ.get('APP_VERSION', '1.0.0')
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

cat > requirements.txt << 'EOF'
flask==2.2.0
gunicorn==20.1.0
EOF

cat > Dockerfile << 'EOF'
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

EXPOSE 5000

# Use gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
EOF

cd ..
```

3. **Create test suite:**
```bash
cd tests

cat > requirements.txt << 'EOF'
pytest==7.0.0
requests==2.28.0
pytest-cov==4.0.0
pytest-html==3.1.0
EOF

cat > test_app.py << 'EOF'
import pytest
import requests
import time
import os

# Use environment variable for base URL, default to localhost for local testing
BASE_URL = os.environ.get('APP_URL', 'http://localhost:5000')

def wait_for_app(timeout=60):
    """Wait for application to be ready"""
    for _ in range(timeout):
        try:
            response = requests.get(f'{BASE_URL}/health', timeout=2)
            if response.status_code == 200:
                return True
        except:
            pass
        time.sleep(1)
    return False

@pytest.fixture(scope="session", autouse=True)
def setup_test_environment():
    """Setup test environment"""
    if not wait_for_app():
        pytest.skip("Application not available")

def test_home_endpoint():
    """Test home endpoint"""
    response = requests.get(f'{BASE_URL}/')
    assert response.status_code == 200
    data = response.json()
    assert 'message' in data
    assert 'version' in data

def test_health_endpoint():
    """Test health endpoint"""
    response = requests.get(f'{BASE_URL}/health')
    assert response.status_code == 200
    data = response.json()
    assert data['status'] == 'healthy'

def test_status_endpoint():
    """Test status endpoint"""
    response = requests.get(f'{BASE_URL}/api/status')
    assert response.status_code == 200
    data = response.json()
    assert data['status'] == 'running'
    assert 'version' in data

def test_invalid_endpoint():
    """Test invalid endpoint returns 404"""
    response = requests.get(f'{BASE_URL}/invalid')
    assert response.status_code == 404
EOF

cat > Dockerfile << 'EOF'
FROM python:3.9-slim

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /tests
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["pytest", "-v", "--tb=short"]
EOF

cd ..
```

4. **Create GitHub Actions workflow:**
```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # Lint and security checks
  lint:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install flake8 bandit safety
        if [ -f app/requirements.txt ]; then pip install -r app/requirements.txt; fi
    
    - name: Lint with flake8
      run: |
        # Stop the build if there are Python syntax errors or undefined names
        flake8 app --count --select=E9,F63,F7,F82 --show-source --statistics
        # Exit-zero treats all errors as warnings
        flake8 app --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics
    
    - name: Security check with bandit
      run: bandit -r app/ -f json -o bandit-report.json || true
    
    - name: Check dependencies for vulnerabilities
      run: safety check -r app/requirements.txt --json --output safety-report.json || true
    
    - name: Upload security reports
      uses: actions/upload-artifact@v3
      with:
        name: security-reports
        path: |
          bandit-report.json
          safety-report.json

  # Build and test
  test:
    runs-on: ubuntu-latest
    needs: lint
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Build application image
      uses: docker/build-push-action@v4
      with:
        context: ./app
        load: true
        tags: test-app:latest
        cache-from: type=gha
        cache-to: type=gha,mode=max
    
    - name: Build test image
      uses: docker/build-push-action@v4
      with:
        context: ./tests
        load: true
        tags: test-runner:latest
    
    - name: Create test network
      run: docker network create test-network
    
    - name: Start application
      run: |
        docker run -d \
          --name app-container \
          --network test-network \
          -p 5000:5000 \
          -e APP_VERSION=${{ github.sha }} \
          -e ENVIRONMENT=testing \
          test-app:latest
    
    - name: Wait for application
      run: |
        timeout 60 bash -c 'until curl -f http://localhost:5000/health; do sleep 2; done'
    
    - name: Run tests
      run: |
        docker run --rm \
          --network test-network \
          -e APP_URL=http://app-container:5000 \
          -v ${{ github.workspace }}/test-results:/tests/test-results \
          test-runner:latest \
          pytest -v --html=test-results/report.html --self-contained-html --cov=. --cov-report=html:test-results/coverage/
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results
        path: test-results/
    
    - name: Stop application
      if: always()
      run: docker stop app-container && docker rm app-container

  # Integration tests
  integration-test:
    runs-on: ubuntu-latest
    needs: test
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Create docker-compose for integration testing
      run: |
        cat > docker-compose.test.yml << 'EOF'
        version: '3.8'
        services:
          app:
            build: ./app
            environment:
              - APP_VERSION=${{ github.sha }}
              - ENVIRONMENT=integration
            healthcheck:
              test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
              interval: 10s
              timeout: 5s
              retries: 5
          
          integration-tests:
            build: ./tests
            environment:
              - APP_URL=http://app:5000
            depends_on:
              app:
                condition: service_healthy
            volumes:
              - ./integration-results:/tests/test-results
        EOF
    
    - name: Run integration tests
      run: |
        mkdir -p integration-results
        docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit integration-tests
        docker-compose -f docker-compose.test.yml down
    
    - name: Upload integration test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: integration-test-results
        path: integration-results/

  # Build and push image
  build-and-push:
    runs-on: ubuntu-latest
    needs: [test, integration-test]
    if: github.event_name == 'push'
    
    permissions:
      contents: read
      packages: write
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Log in to Container Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v4
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}
    
    - name: Build and push
      uses: docker/build-push-action@v4
      with:
        context: ./app
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  # Deploy to staging (for main branch)
  deploy-staging:
    runs-on: ubuntu-latest
    needs: build-and-push
    if: github.ref == 'refs/heads/main'
    environment: staging
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to staging
      run: |
        echo "🚀 Deploying to staging environment..."
        echo "Image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:main-${{ github.sha }}"
        # In a real scenario, this would deploy to your staging environment
        # For example: kubectl, docker-compose, or cloud provider CLI
```

5. **Create additional workflow for release:**
```yaml
# .github/workflows/release.yml
name: Release

on:
  release:
    types: [published]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push-release:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Log in to Container Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v4
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=semver,pattern={{version}}
          type=semver,pattern={{major}}.{{minor}}
          type=semver,pattern={{major}}
    
    - name: Build and push release
      uses: docker/build-push-action@v4
      with:
        context: ./app
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        build-args: |
          APP_VERSION=${{ github.event.release.tag_name }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  deploy-production:
    runs-on: ubuntu-latest
    needs: build-and-push-release
    environment: production
    
    steps:
    - name: Deploy to production
      run: |
        echo "🚀 Deploying version ${{ github.event.release.tag_name }} to production..."
        echo "Image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.event.release.tag_name }}"
        # Production deployment logic here
```

---

## Exercise 5.2: Advanced Debugging Techniques (45 minutes)

### Objective
Master Docker debugging techniques for troubleshooting issues in testing environments.

### Instructions

1. **Create debugging project:**
```bash
mkdir docker-debugging
cd docker-debugging
```

2. **Create problematic application for debugging:**
```python
# app.py
import time
import os
import logging
from flask import Flask, jsonify

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s %(levelname)s %(name)s %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Simulate some issues
SIMULATE_MEMORY_LEAK = os.environ.get('MEMORY_LEAK', 'false').lower() == 'true'
SIMULATE_SLOW_RESPONSE = os.environ.get('SLOW_RESPONSE', 'false').lower() == 'true'
SIMULATE_CRASH = os.environ.get('CRASH_AFTER', '0')

# Global list to simulate memory leak
memory_hog = []

@app.route('/')
def home():
    logger.info("Home endpoint accessed")
    
    if SIMULATE_MEMORY_LEAK:
        # Add data to simulate memory leak
        memory_hog.extend([f"data_{i}" for i in range(1000)])
        logger.warning(f"Memory hog size: {len(memory_hog)}")
    
    if SIMULATE_SLOW_RESPONSE:
        logger.info("Simulating slow response...")
        time.sleep(5)
    
    return jsonify({
        'status': 'ok',
        'memory_usage': len(memory_hog),
        'pid': os.getpid()
    })

@app.route('/health')
def health():
    crash_after = int(SIMULATE_CRASH)
    if crash_after > 0:
        # Check if we should crash
        if not hasattr(health, 'counter'):
            health.counter = 0
        health.counter += 1
        
        if health.counter >= crash_after:
            logger.error("Simulating application crash!")
            raise Exception("Simulated crash!")
    
    return jsonify({'status': 'healthy'})

@app.route('/debug')
def debug_info():
    """Debug endpoint with system information"""
    import psutil
    import sys
    
    process = psutil.Process()
    
    return jsonify({
        'process_info': {
            'pid': os.getpid(),
            'memory_percent': process.memory_percent(),
            'cpu_percent': process.cpu_percent(),
            'num_threads': process.num_threads()
        },
        'system_info': {
            'python_version': sys.version,
            'platform': os.uname()._asdict() if hasattr(os, 'uname') else 'unknown'
        },
        'environment': dict(os.environ),
        'memory_hog_size': len(memory_hog)
    })

@app.route('/error')
def trigger_error():
    """Endpoint to trigger various types of errors"""
    error_type = request.args.get('type', 'generic')
    
    if error_type == 'division':
        return 1 / 0
    elif error_type == 'key':
        return {}['nonexistent_key']
    elif error_type == 'file':
        with open('/nonexistent/file.txt', 'r') as f:
            return f.read()
    else:
        raise Exception("Generic error for testing")

if __name__ == '__main__':
    logger.info("Starting application...")
    app.run(host='0.0.0.0', port=5000, debug=True)
```

3. **Create Dockerfile with debugging tools:**
```dockerfile
FROM python:3.9-slim

# Install debugging tools
RUN apt-get update && apt-get install -y \
    htop \
    strace \
    tcpdump \
    net-tools \
    procps \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Add debugging user
RUN useradd -m debuguser

EXPOSE 5000

CMD ["python", "app.py"]
```

4. **Create requirements.txt:**
```txt
flask==2.2.0
psutil==5.9.0
gunicorn==20.1.0
```

5. **Create docker-compose for debugging:**
```yaml
# docker-compose.debug.yml
version: '3.8'

services:
  # Normal app
  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=development
    volumes:
      - ./logs:/app/logs

  # App with memory leak
  app-memory-leak:
    build: .
    ports:
      - "5001:5000"
    environment:
      - MEMORY_LEAK=true
      - FLASK_ENV=development
    volumes:
      - ./logs:/app/logs

  # App with slow responses
  app-slow:
    build: .
    ports:
      - "5002:5000"
    environment:
      - SLOW_RESPONSE=true
      - FLASK_ENV=development

  # App that crashes
  app-crash:
    build: .
    ports:
      - "5003:5000"
    environment:
      - CRASH_AFTER=5
      - FLASK_ENV=development
    restart: unless-stopped

  # Monitoring container
  monitor:
    image: nicolaka/netshoot
    command: sleep infinity
    network_mode: "service:app"
    cap_add:
      - NET_ADMIN
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

6. **Create debugging scripts:**

**Container inspection script:**
```bash
# debug-container.sh
#!/bin/bash

CONTAINER_NAME=${1:-app}

echo "=== Container Information ==="
docker inspect $CONTAINER_NAME --format='{{json .State}}' | python -m json.tool

echo -e "\n=== Resource Usage ==="
docker stats $CONTAINER_NAME --no-stream

echo -e "\n=== Process List ==="
docker exec $CONTAINER_NAME ps aux

echo -e "\n=== Network Connections ==="
docker exec $CONTAINER_NAME netstat -tulpn

echo -e "\n=== Disk Usage ==="
docker exec $CONTAINER_NAME df -h

echo -e "\n=== Memory Info ==="
docker exec $CONTAINER_NAME cat /proc/meminfo | head -10

echo -e "\n=== Recent Logs ==="
docker logs --tail 20 $CONTAINER_NAME
```

**Network debugging script:**
```bash
# debug-network.sh
#!/bin/bash

NETWORK_NAME=${1:-docker-debugging_default}

echo "=== Network Information ==="
docker network inspect $NETWORK_NAME

echo -e "\n=== Containers in Network ==="
docker network inspect $NETWORK_NAME --format='{{range .Containers}}{{.Name}} - {{.IPv4Address}}{{"\n"}}{{end}}'

echo -e "\n=== Network Connectivity Test ==="
# Test connectivity between containers
docker run --rm --network $NETWORK_NAME nicolaka/netshoot \
  nslookup app

echo -e "\n=== Port Scanning ==="
docker run --rm --network $NETWORK_NAME nicolaka/netshoot \
  nmap -p 5000 app
```

7. **Start debugging environment:**
```bash
chmod +x debug-container.sh debug-network.sh

# Start all services
docker-compose -f docker-compose.debug.yml up -d

# Wait for services to start
sleep 10

# Test different scenarios
echo "Testing normal app..."
curl http://localhost:5000/

echo "Testing memory leak app..."
curl http://localhost:5001/

echo "Testing slow app..."
time curl http://localhost:5002/

echo "Testing crash app..."
for i in {1..6}; do
  curl http://localhost:5003/health
  sleep 1
done
```

8. **Debug different issues:**

**Memory debugging:**
```bash
# Monitor memory usage
./debug-container.sh docker-debugging_app-memory-leak_1

# Execute commands inside container for detailed debugging
docker exec -it docker-debugging_app-memory-leak_1 bash

# Inside container:
# top
# ps aux --sort=-%mem
# cat /proc/meminfo
# python -c "import psutil; print(f'Memory: {psutil.virtual_memory().percent}%')"
```

**Network debugging:**
```bash
# Debug network issues
./debug-network.sh

# Advanced network debugging
docker exec -it docker-debugging_monitor_1 bash

# Inside monitor container:
# tcpdump -i any port 5000
# netstat -i
# ss -tulpn
```

**Performance debugging:**
```bash
# Use docker stats for real-time monitoring
docker stats

# Trace system calls
docker exec docker-debugging_app-slow_1 strace -p 1 -f

# Monitor file descriptor usage
docker exec docker-debugging_app-slow_1 ls -la /proc/1/fd/
```

---

## Exercise 5.3: Security Best Practices (45 minutes)

### Objective
Implement security best practices for Docker containers in testing environments.

### Instructions

1. **Create security-focused project:**
```bash
mkdir docker-security
cd docker-security
```

2. **Create secure Dockerfile:**
```dockerfile
# Dockerfile.secure
# Use specific version, not latest
FROM python:3.9.16-slim-bullseye

# Create non-root user first
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install only necessary packages and clean up
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set working directory
WORKDIR /app

# Copy and install dependencies as root
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && pip cache purge

# Copy application code
COPY --chown=appuser:appuser . .

# Remove setuid/setgid permissions from all files
RUN find / -perm /6000 -type f -exec chmod a-s {} \; 2>/dev/null || true

# Switch to non-root user
USER appuser

# Use non-privileged port
EXPOSE 8080

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Don't run as PID 1 to avoid zombie processes
ENTRYPOINT ["python"]
CMD ["secure_app.py"]
```

3. **Create secure application:**
```python
# secure_app.py
import os
import logging
import secrets
from flask import Flask, jsonify, request
from werkzeug.security import generate_password_hash, check_password_hash

# Configure secure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s',
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Use environment variables for configuration
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', secrets.token_hex(16))
app.config['DEBUG'] = False

# Security headers middleware
@app.after_request
def after_request(response):
    """Add security headers"""
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    response.headers['Content-Security-Policy'] = "default-src 'self'"
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    return response

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'})

@app.route('/info')
def info():
    """Safe information endpoint"""
    # Don't expose sensitive information
    safe_env = {k: v for k, v in os.environ.items() 
                if not any(secret in k.lower() for secret in ['pass', 'key', 'token', 'secret'])}
    
    return jsonify({
        'user': os.getuid(),
        'working_directory': os.getcwd(),
        'python_version': os.sys.version.split()[0],
        'safe_environment': safe_env
    })

@app.route('/secure-endpoint', methods=['POST'])
def secure_endpoint():
    """Example of secure endpoint with input validation"""
    data = request.get_json()
    
    if not data:
        return jsonify({'error': 'No data provided'}), 400
    
    # Input validation
    username = data.get('username', '').strip()
    password = data.get('password', '')
    
    if not username or len(username) < 3:
        return jsonify({'error': 'Username must be at least 3 characters'}), 400
    
    if not password or len(password) < 8:
        return jsonify({'error': 'Password must be at least 8 characters'}), 400
    
    # Secure password hashing
    password_hash = generate_password_hash(password)
    
    # Log without sensitive data
    logger.info(f"User registration attempt for username: {username}")
    
    return jsonify({
        'message': 'User registered successfully',
        'username': username,
        'password_hash': password_hash[:20] + '...'  # Only show partial hash
    })

if __name__ == '__main__':
    # Bind to all interfaces but use non-privileged port
    app.run(host='0.0.0.0', port=8080, debug=False)
```

4. **Create security scanning configuration:**
```yaml
# docker-compose.security.yml
version: '3.8'

services:
  # Secure application
  secure-app:
    build:
      context: .
      dockerfile: Dockerfile.secure
    ports:
      - "8080:8080"
    environment:
      - SECRET_KEY=${SECRET_KEY}
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
    restart: unless-stopped
    user: appuser

  # Security scanner
  trivy-scanner:
    image: aquasec/trivy:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./security-reports:/reports
    command: |
      sh -c "
        trivy image --format json --output /reports/image-scan.json secure-app:latest;
        trivy fs --format json --output /reports/filesystem-scan.json /;
      "
    profiles:
      - security-scan

  # Container security benchmark
  docker-bench:
    image: docker/docker-bench-security
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /usr/lib/systemd:/usr/lib/systemd:ro
      - /etc:/etc:ro
      - ./security-reports:/reports
    command: sh -c "docker-bench-security.sh | tee /reports/docker-bench.txt"
    profiles:
      - security-scan
```

5. **Create security testing script:**
```bash
# security-test.sh
#!/bin/bash

set -e

echo "🔒 Starting security testing..."

# Create reports directory
mkdir -p security-reports

# Generate secure secret key
export SECRET_KEY=$(openssl rand -hex 32)

# Build and start secure application
echo "📦 Building secure application..."
docker-compose -f docker-compose.security.yml build secure-app

echo "🚀 Starting secure application..."
docker-compose -f docker-compose.security.yml up -d secure-app

# Wait for app to start
echo "⏳ Waiting for application to start..."
timeout 30 bash -c 'until curl -f http://localhost:8080/health; do sleep 2; done'

echo "✅ Application started successfully"

# Test security headers
echo "🛡️ Testing security headers..."
curl -I http://localhost:8080/health | grep -E "(X-Content-Type-Options|X-Frame-Options|X-XSS-Protection)"

# Test non-root user
echo "👤 Verifying non-root user..."
docker exec $(docker-compose -f docker-compose.security.yml ps -q secure-app) whoami

# Test read-only filesystem
echo "📁 Testing read-only filesystem..."
docker exec $(docker-compose -f docker-compose.security.yml ps -q secure-app) \
  sh -c 'echo "test" > /test.txt 2>&1 || echo "✅ Read-only filesystem working"'

# Test capabilities
echo "🔧 Testing capabilities..."
docker inspect $(docker-compose -f docker-compose.security.yml ps -q secure-app) \
  --format='{{.HostConfig.CapDrop}}' | grep -q "ALL" && echo "✅ Capabilities dropped"

# Run security scans
echo "🔍 Running security scans..."
docker-compose -f docker-compose.security.yml --profile security-scan up --build trivy-scanner docker-bench

echo "📊 Security scan results:"
ls -la security-reports/

# Cleanup
echo "🧹 Cleaning up..."
docker-compose -f docker-compose.security.yml down

echo "🎉 Security testing completed!"
```

6. **Create Dockerfile linting:**
```bash
# dockerfile-lint.sh
#!/bin/bash

echo "🔍 Linting Dockerfile..."

# Install hadolint if not present
if ! command -v hadolint &> /dev/null; then
    echo "Installing hadolint..."
    wget -O hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64
    chmod +x hadolint
    sudo mv hadolint /usr/local/bin/
fi

# Lint the Dockerfile
echo "📋 Hadolint results:"
hadolint Dockerfile.secure || echo "⚠️ Dockerfile has linting issues"

echo "✅ Dockerfile linting completed"
```

---

## Exercise 5.4: Final Project - Complete Testing Environment (90 minutes)

### Objective
Build a comprehensive testing environment that incorporates all concepts learned throughout the course.

### Project Requirements
Create a complete testing environment for an e-commerce API with:
1. Multi-service application (API, Database, Cache, Frontend)
2. Multiple test suites (Unit, Integration, Load, Security)
3. CI/CD pipeline
4. Monitoring and debugging capabilities
5. Security best practices

### Instructions

1. **Create project structure:**
```bash
mkdir final-project
cd final-project
mkdir -p {api,frontend,tests,monitoring,.github/workflows}
```

2. **Create the API service:**
```bash
cd api

cat > app.py << 'EOF'
from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
import redis
import jwt
import bcrypt
import os
import logging
from datetime import datetime, timedelta
from functools import wraps

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Configuration
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key')
app.config['JWT_EXPIRATION_HOURS'] = 24

# Database connection
def get_db():
    return psycopg2.connect(
        host=os.environ.get('DB_HOST', 'db'),
        database=os.environ.get('DB_NAME', 'ecommerce'),
        user=os.environ.get('DB_USER', 'ecommerce_user'),
        password=os.environ.get('DB_PASSWORD', 'password')
    )

# Redis connection
redis_client = redis.Redis(
    host=os.environ.get('REDIS_HOST', 'cache'),
    port=6379,
    decode_responses=True
)

# JWT token required decorator
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'error': 'Token missing'}), 401
        
        try:
            token = token.split(' ')[1]  # Remove 'Bearer ' prefix
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
            current_user_id = data['user_id']
        except:
            return jsonify({'error': 'Token invalid'}), 401
        
        return f(current_user_id, *args, **kwargs)
    return decorated

@app.route('/health')
def health():
    try:
        # Test database
        conn = get_db()
        conn.close()
        
        # Test Redis
        redis_client.ping()
        
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'services': {
                'database': 'connected',
                'cache': 'connected'
            }
        })
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500

@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    
    if not all(k in data for k in ['username', 'email', 'password']):
        return jsonify({'error': 'Missing required fields'}), 400
    
    # Hash password
    hashed_password = bcrypt.hashpw(data['password'].encode('utf-8'), bcrypt.gensalt())
    
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute(
            'INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s) RETURNING id',
            (data['username'], data['email'], hashed_password.decode('utf-8'))
        )
        user_id = cur.fetchone()[0]
        conn.commit()
        conn.close()
        
        logger.info(f"User registered: {data['username']}")
        return jsonify({'message': 'User registered successfully', 'user_id': user_id}), 201
    except psycopg2.IntegrityError:
        return jsonify({'error': 'Username or email already exists'}), 409

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    
    if not all(k in data for k in ['username', 'password']):
        return jsonify({'error': 'Username and password required'}), 400
    
    try:
        conn = get_db()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('SELECT * FROM users WHERE username = %s', (data['username'],))
        user = cur.fetchone()
        conn.close()
        
        if user and bcrypt.checkpw(data['password'].encode('utf-8'), user['password_hash'].encode('utf-8')):
            # Generate JWT token
            token = jwt.encode({
                'user_id': user['id'],
                'exp': datetime.utcnow() + timedelta(hours=app.config['JWT_EXPIRATION_HOURS'])
            }, app.config['SECRET_KEY'])
            
            return jsonify({'token': token, 'user_id': user['id']})
        else:
            return jsonify({'error': 'Invalid credentials'}), 401
    except Exception as e:
        logger.error(f"Login error: {e}")
        return jsonify({'error': 'Login failed'}), 500

@app.route('/api/products', methods=['GET'])
def get_products():
    try:
        # Try cache first
        cached_products = redis_client.get('products')
        if cached_products:
            import json
            return jsonify(json.loads(cached_products))
        
        # Get from database
        conn = get_db()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('SELECT * FROM products WHERE available = true ORDER BY name')
        products = cur.fetchall()
        conn.close()
        
        # Cache for 5 minutes
        import json
        redis_client.setex('products', 300, json.dumps([dict(p) for p in products], default=str))
        
        return jsonify([dict(p) for p in products])
    except Exception as e:
        logger.error(f"Error fetching products: {e}")
        return jsonify({'error': 'Failed to fetch products'}), 500

@app.route('/api/products', methods=['POST'])
@token_required
def create_product(current_user_id):
    data = request.get_json()
    
    required_fields = ['name', 'description', 'price', 'stock']
    if not all(k in data for k in required_fields):
        return jsonify({'error': 'Missing required fields'}), 400
    
    try:
        conn = get_db()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            '''INSERT INTO products (name, description, price, stock, created_by) 
               VALUES (%s, %s, %s, %s, %s) RETURNING *''',
            (data['name'], data['description'], data['price'], data['stock'], current_user_id)
        )
        product = cur.fetchone()
        conn.commit()
        conn.close()
        
        # Clear cache
        redis_client.delete('products')
        
        logger.info(f"Product created: {data['name']} by user {current_user_id}")
        return jsonify(dict(product)), 201
    except Exception as e:
        logger.error(f"Error creating product: {e}")
        return jsonify({'error': 'Failed to create product'}), 500

def init_database():
    """Initialize database tables"""
    try:
        conn = get_db()
        cur = conn.cursor()
        
        # Create users table
        cur.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                username VARCHAR(50) UNIQUE NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Create products table
        cur.execute('''
            CREATE TABLE IF NOT EXISTS products (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                description TEXT,
                price DECIMAL(10,2) NOT NULL,
                stock INTEGER NOT NULL DEFAULT 0,
                available BOOLEAN DEFAULT true,
                created_by INTEGER REFERENCES users(id),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Insert sample products
        cur.execute('SELECT COUNT(*) FROM products')
        if cur.fetchone()[0] == 0:
            sample_products = [
                ('Laptop', 'High-performance laptop', 999.99, 10),
                ('Mouse', 'Wireless optical mouse', 29.99, 50),
                ('Keyboard', 'Mechanical keyboard', 79.99, 25),
                ('Monitor', '24-inch LCD monitor', 199.99, 15)
            ]
            cur.executemany(
                'INSERT INTO products (name, description, price, stock) VALUES (%s, %s, %s, %s)',
                sample_products
            )
        
        conn.commit()
        conn.close()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Database initialization error: {e}")

if __name__ == '__main__':
    init_database()
    app.run(host='0.0.0.0', port=5000, debug=os.environ.get('FLASK_DEBUG', 'false').lower() == 'true')
EOF

cat > requirements.txt << 'EOF'
flask==2.2.0
flask-cors==3.0.10
psycopg2-binary==2.9.0
redis==4.3.0
PyJWT==2.6.0
bcrypt==4.0.0
gunicorn==20.1.0
EOF

cat > Dockerfile << 'EOF'
FROM python:3.9-slim

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
EOF

cd ..
```

3. **Create comprehensive test suite:**
```bash
cd tests

cat > requirements.txt << 'EOF'
pytest==7.0.0
requests==2.28.0
pytest-html==3.1.0
pytest-cov==4.0.0
locust==2.14.0
pytest-xdist==3.2.0
PyJWT==2.6.0
EOF

# Unit tests
cat > test_unit.py << 'EOF'
import pytest
import jwt
from datetime import datetime, timedelta

def test_jwt_token_creation():
    """Test JWT token creation and validation"""
    secret_key = 'test-secret'
    payload = {
        'user_id': 1,
        'exp': datetime.utcnow() + timedelta(hours=1)
    }
    
    token = jwt.encode(payload, secret_key, algorithm='HS256')
    decoded = jwt.decode(token, secret_key, algorithms=['HS256'])
    
    assert decoded['user_id'] == 1

def test_password_validation():
    """Test password validation logic"""
    import bcrypt
    
    password = "test123"
    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    
    assert bcrypt.checkpw(password.encode('utf-8'), hashed)
    assert not bcrypt.checkpw("wrong".encode('utf-8'), hashed)
EOF

# Integration tests
cat > test_integration.py << 'EOF'
import pytest
import requests
import time
import os

BASE_URL = os.environ.get('API_URL', 'http://localhost:5000')

def wait_for_api(timeout=60):
    for _ in range(timeout):
        try:
            response = requests.get(f'{BASE_URL}/health', timeout=2)
            if response.status_code == 200:
                return True
        except:
            pass
        time.sleep(1)
    return False

@pytest.fixture(scope="session", autouse=True)
def setup_api():
    assert wait_for_api(), "API not available"

def test_health_endpoint():
    response = requests.get(f'{BASE_URL}/health')
    assert response.status_code == 200
    data = response.json()
    assert data['status'] == 'healthy'

def test_user_registration():
    user_data = {
        'username': 'testuser',
        'email': 'test@example.com',
        'password': 'password123'
    }
    response = requests.post(f'{BASE_URL}/api/register', json=user_data)
    assert response.status_code == 201

def test_user_login():
    login_data = {
        'username': 'testuser',
        'password': 'password123'
    }
    response = requests.post(f'{BASE_URL}/api/login', json=login_data)
    assert response.status_code == 200
    data = response.json()
    assert 'token' in data

def test_products_endpoint():
    response = requests.get(f'{BASE_URL}/api/products')
    assert response.status_code == 200
    products = response.json()
    assert isinstance(products, list)
    assert len(products) > 0
EOF

# Load tests
cat > locustfile.py << 'EOF'
from locust import HttpUser, task, between
import random

class ECommerceUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        # Register a user
        self.username = f"user_{random.randint(1000, 9999)}"
        self.client.post("/api/register", json={
            "username": self.username,
            "email": f"{self.username}@example.com",
            "password": "password123"
        })
        
        # Login and get token
        response = self.client.post("/api/login", json={
            "username": self.username,
            "password": "password123"
        })
        if response.status_code == 200:
            self.token = response.json()["token"]
            self.headers = {"Authorization": f"Bearer {self.token}"}
        else:
            self.headers = {}
    
    @task(3)
    def view_products(self):
        self.client.get("/api/products")
    
    @task(1)
    def health_check(self):
        self.client.get("/health")
    
    @task(1)
    def create_product(self):
        if hasattr(self, 'headers'):
            self.client.post("/api/products", 
                json={
                    "name": f"Product {random.randint(1, 1000)}",
                    "description": "Test product",
                    "price": random.uniform(10, 100),
                    "stock": random.randint(1, 50)
                },
                headers=self.headers
            )
EOF

cat > Dockerfile << 'EOF'
FROM python:3.9-slim

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /tests
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["pytest", "-v"]
EOF

cd ..
```

4. **Create docker-compose for the complete environment:**
```yaml
# docker-compose.yml
version: '3.8'

services:
  # Database
  db:
    image: postgres:13
    environment:
      POSTGRES_DB: ecommerce
      POSTGRES_USER: ecommerce_user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ecommerce_user -d ecommerce"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Cache
  cache:
    image: redis:6-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  # API
  api:
    build: ./api
    environment:
      DB_HOST: db
      DB_NAME: ecommerce
      DB_USER: ecommerce_user
      DB_PASSWORD: password
      REDIS_HOST: cache
      SECRET_KEY: ${SECRET_KEY:-dev-secret-key}
    ports:
      - "5000:5000"
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_healthy
    restart: unless-stopped

  # Testing services
  unit-tests:
    build: ./tests
    command: pytest test_unit.py -v
    profiles: ["test"]

  integration-tests:
    build: ./tests
    environment:
      API_URL: http://api:5000
    command: pytest test_integration.py -v
    depends_on:
      - api
    profiles: ["test"]

  load-tests:
    build: ./tests
    command: locust --host=http://api:5000 --users=10 --spawn-rate=2 --run-time=60s --headless
    depends_on:
      - api
    profiles: ["load"]

volumes:
  postgres_data:
  redis_data:

networks:
  default:
    name: ecommerce-network
```

5. **Create CI/CD pipeline:**
```yaml
# .github/workflows/complete-pipeline.yml
name: Complete E-commerce Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Start services
      run: |
        export SECRET_KEY=$(openssl rand -hex 32)
        docker-compose up -d api
    
    - name: Wait for services
      run: |
        timeout 60 bash -c 'until curl -f http://localhost:5000/health; do sleep 2; done'
    
    - name: Run unit tests
      run: docker-compose --profile test up --build unit-tests
    
    - name: Run integration tests
      run: docker-compose --profile test up --build integration-tests
    
    - name: Run load tests
      run: docker-compose --profile load up --build load-tests
    
    - name: Collect logs
      if: always()
      run: |
        mkdir -p logs
        docker-compose logs api > logs/api.log
        docker-compose logs db > logs/db.log
    
    - name: Upload logs
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: service-logs
        path: logs/
    
    - name: Cleanup
      if: always()
      run: docker-compose down -v
```

6. **Run the complete testing environment:**
```bash
# Create environment variables
export SECRET_KEY=$(openssl rand -hex 32)

# Start the complete environment
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
timeout 60 bash -c 'until curl -f http://localhost:5000/health; do sleep 2; done'

# Run all tests
echo "Running unit tests..."
docker-compose --profile test up --build unit-tests

echo "Running integration tests..."
docker-compose --profile test up --build integration-tests

echo "Running load tests..."
docker-compose --profile load up --build load-tests

# Check service status
docker-compose ps

# View logs
docker-compose logs api

# Cleanup
docker-compose down -v
```

---

## Course Completion & Next Steps

### 🎉 Congratulations!

You have successfully completed the Docker Training for QA Engineers! You've learned:

1. **Docker Fundamentals**: Containers, images, networking, and data management
2. **Custom Image Creation**: Dockerfile best practices and optimization
3. **Multi-Container Applications**: Docker Compose orchestration
4. **CI/CD Integration**: Automated testing and deployment pipelines
5. **Debugging & Security**: Troubleshooting and security best practices

### 🚀 Next Steps for Advanced Learning

1. **Container Orchestration**:
   - Kubernetes basics for QA Engineers
   - Docker Swarm for simple clustering
   - Service mesh concepts (Istio, Linkerd)

2. **Advanced Testing Strategies**:
   - Chaos engineering with containers
   - Performance testing at scale
   - Contract testing with Pact

3. **Monitoring & Observability**:
   - Prometheus and Grafana setup
   - Distributed tracing with Jaeger
   - Log aggregation with ELK stack

4. **Security Deep Dive**:
   - Container image scanning
   - Runtime security monitoring
   - Compliance automation

### 📚 Recommended Resources

- **Books**: "Docker Deep Dive" by Nigel Poulton
- **Courses**: Kubernetes for Developers, Advanced Docker
- **Certifications**: Docker Certified Associate, CKA/CKAD
- **Communities**: Docker Community, r/docker, Stack Overflow

### 🏆 Final Project Checklist

- [ ] Multi-service application deployed
- [ ] Comprehensive test suite implemented
- [ ] CI/CD pipeline configured
- [ ] Security best practices applied
- [ ] Monitoring and logging setup
- [ ] Documentation completed

**Well done on completing this comprehensive Docker training!** 🐳