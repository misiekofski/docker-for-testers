# Day 4 Exercises: Docker Compose & Multi-Container Applications

## Exercise 4.1: Introduction to Docker Compose (45 minutes)

### Objective
Learn Docker Compose basics by converting single-container setups to multi-container applications.

### Part A: Simple Web + Database Stack

1. **Create project directory:**
```bash
mkdir compose-intro
cd compose-intro
```

2. **Create your first docker-compose.yml:**
```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    depends_on:
      - db

  db:
    image: postgres:13
    environment:
      POSTGRES_DB: testdb
      POSTGRES_USER: testuser
      POSTGRES_PASSWORD: testpass
    volumes:
      - db_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  db_data:
```

3. **Create HTML content:**
```bash
mkdir html
cat > html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Docker Compose Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f0f0f0; }
        .container { background: white; padding: 30px; border-radius: 8px; }
        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }
        .success { background: #d4edda; color: #155724; }
        .info { background: #d1ecf1; color: #0c5460; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 Docker Compose Demo</h1>
        <div class="status success">✅ Web server is running!</div>
        <div class="status info">ℹ️ Database is configured on port 5432</div>
        
        <h3>Services Status:</h3>
        <ul>
            <li><strong>Web Server:</strong> nginx:alpine</li>
            <li><strong>Database:</strong> postgres:13</li>
            <li><strong>Network:</strong> Default bridge network</li>
            <li><strong>Volume:</strong> Persistent database storage</li>
        </ul>
        
        <h3>Quick Tests:</h3>
        <p>Test database connection from another container:</p>
        <code>docker-compose exec db psql -U testuser -d testdb -c "SELECT version();"</code>
    </div>
</body>
</html>
EOF
```

4. **Start the services:**
```bash
docker-compose up -d
```

5. **Check status:**
```bash
docker-compose ps
docker-compose logs
```

6. **Test the services:**
```bash
# Test web server
curl http://localhost:8080

# Test database connection
docker-compose exec db psql -U testuser -d testdb -c "SELECT version();"
```

7. **Scale the web service:**
```bash
docker-compose up -d --scale web=3
```

8. **View logs for specific service:**
```bash
docker-compose logs web
docker-compose logs -f db
```

### Part B: Environment Variables and Configuration

1. **Create .env file:**
```bash
cat > .env << 'EOF'
# Database Configuration
POSTGRES_DB=myapp
POSTGRES_USER=appuser
POSTGRES_PASSWORD=securepass123

# Web Configuration
WEB_PORT=8081
DB_PORT=5433

# Application Settings
APP_ENV=development
DEBUG=true
EOF
```

2. **Update docker-compose.yml to use environment variables:**
```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "${WEB_PORT}:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    environment:
      - APP_ENV=${APP_ENV}
    depends_on:
      - db

  db:
    image: postgres:13
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - db_data:/var/lib/postgresql/data
    ports:
      - "${DB_PORT}:5432"

volumes:
  db_data:
```

3. **Restart with new configuration:**
```bash
docker-compose down
docker-compose up -d
```

4. **Verify new ports:**
```bash
curl http://localhost:8081
docker-compose exec db psql -U appuser -d myapp -c "\l"
```

---

## Exercise 4.2: Custom Application with Compose (60 minutes)

### Objective
Build a complete application stack with custom images using Docker Compose.

### Instructions

1. **Create application structure:**
```bash
mkdir fullstack-app
cd fullstack-app
mkdir api frontend
```

2. **Create API service:**
```bash
cd api

cat > app.py << 'EOF'
from flask import Flask, jsonify, request, cors
import psycopg2
from psycopg2.extras import RealDictCursor
import redis
import os
import json
from datetime import datetime

app = Flask(__name__)

# Database connection
def get_db_connection():
    return psycopg2.connect(
        host=os.environ.get('DB_HOST', 'db'),
        database=os.environ.get('DB_NAME', 'appdb'),
        user=os.environ.get('DB_USER', 'appuser'),
        password=os.environ.get('DB_PASSWORD', 'apppass')
    )

# Redis connection
redis_client = redis.Redis(
    host=os.environ.get('REDIS_HOST', 'cache'),
    port=6379,
    decode_responses=True
)

@app.route('/health')
def health():
    try:
        # Test database
        conn = get_db_connection()
        conn.close()
        
        # Test Redis
        redis_client.ping()
        
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'database': 'connected',
            'cache': 'connected'
        })
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e)
        }), 500

@app.route('/api/tasks', methods=['GET'])
def get_tasks():
    try:
        # Try cache first
        cached_tasks = redis_client.get('tasks')
        if cached_tasks:
            return jsonify(json.loads(cached_tasks))
        
        # Get from database
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('SELECT * FROM tasks ORDER BY created_at DESC')
        tasks = cur.fetchall()
        conn.close()
        
        # Cache for 5 minutes
        redis_client.setex('tasks', 300, json.dumps([dict(task) for task in tasks], default=str))
        
        return jsonify([dict(task) for task in tasks])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/tasks', methods=['POST'])
def create_task():
    try:
        data = request.get_json()
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            'INSERT INTO tasks (title, description) VALUES (%s, %s) RETURNING *',
            (data['title'], data.get('description', ''))
        )
        task = cur.fetchone()
        conn.commit()
        conn.close()
        
        # Clear cache
        redis_client.delete('tasks')
        
        return jsonify(dict(task)), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def init_db():
    """Initialize database tables"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('''
            CREATE TABLE IF NOT EXISTS tasks (
                id SERIAL PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                description TEXT,
                completed BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Insert sample data
        cur.execute('SELECT COUNT(*) FROM tasks')
        if cur.fetchone()[0] == 0:
            sample_tasks = [
                ('Setup development environment', 'Install Docker and configure local environment'),
                ('Learn Docker Compose', 'Complete Docker Compose exercises'),
                ('Build API tests', 'Create comprehensive API test suite')
            ]
            cur.executemany('INSERT INTO tasks (title, description) VALUES (%s, %s)', sample_tasks)
        
        conn.commit()
        conn.close()
        print("Database initialized successfully")
    except Exception as e:
        print(f"Database initialization error: {e}")

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF

cat > requirements.txt << 'EOF'
flask==2.2.0
psycopg2-binary==2.9.0
redis==4.3.0
flask-cors==3.0.10
EOF

cat > Dockerfile << 'EOF'
FROM python:3.9-slim

RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

EXPOSE 5000
CMD ["python", "app.py"]
EOF

cd ..
```

3. **Create frontend service:**
```bash
cd frontend

cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Task Manager</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; padding: 20px; }
        .header { background: #2c3e50; color: white; padding: 20px; margin: -20px -20px 20px; }
        .task-form { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .task-list { background: white; border-radius: 8px; overflow: hidden; }
        .task-item { padding: 15px; border-bottom: 1px solid #eee; }
        .task-item:last-child { border-bottom: none; }
        .task-title { font-weight: bold; color: #2c3e50; }
        .task-description { color: #7f8c8d; margin-top: 5px; }
        .task-date { color: #95a5a6; font-size: 0.9em; margin-top: 5px; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: bold; }
        .form-group input, .form-group textarea { 
            width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; 
            box-sizing: border-box;
        }
        .btn { 
            background: #3498db; color: white; padding: 10px 20px; 
            border: none; border-radius: 4px; cursor: pointer; 
        }
        .btn:hover { background: #2980b9; }
        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }
        .status.success { background: #d4edda; color: #155724; }
        .status.error { background: #f8d7da; color: #721c24; }
        .loading { text-align: center; padding: 20px; color: #7f8c8d; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Task Manager</h1>
            <p>Full-stack application with Docker Compose</p>
        </div>

        <div id="status"></div>

        <div class="task-form">
            <h3>Add New Task</h3>
            <form id="taskForm">
                <div class="form-group">
                    <label for="title">Title:</label>
                    <input type="text" id="title" name="title" required>
                </div>
                <div class="form-group">
                    <label for="description">Description:</label>
                    <textarea id="description" name="description" rows="3"></textarea>
                </div>
                <button type="submit" class="btn">Add Task</button>
            </form>
        </div>

        <div class="task-list">
            <h3 style="margin: 0; padding: 15px; background: #ecf0f1;">Tasks</h3>
            <div id="taskList" class="loading">Loading tasks...</div>
        </div>
    </div>

    <script>
        const API_BASE = '/api';
        
        function showStatus(message, type = 'success') {
            const statusDiv = document.getElementById('status');
            statusDiv.innerHTML = `<div class="status ${type}">${message}</div>`;
            setTimeout(() => statusDiv.innerHTML = '', 3000);
        }

        async function loadTasks() {
            try {
                const response = await fetch(`${API_BASE}/tasks`);
                const tasks = await response.json();
                
                const taskList = document.getElementById('taskList');
                if (tasks.length === 0) {
                    taskList.innerHTML = '<div style="padding: 20px; text-align: center; color: #7f8c8d;">No tasks yet. Add one above!</div>';
                    return;
                }
                
                taskList.innerHTML = tasks.map(task => `
                    <div class="task-item">
                        <div class="task-title">${task.title}</div>
                        <div class="task-description">${task.description || 'No description'}</div>
                        <div class="task-date">Created: ${new Date(task.created_at).toLocaleString()}</div>
                    </div>
                `).join('');
            } catch (error) {
                document.getElementById('taskList').innerHTML = 
                    `<div style="padding: 20px; text-align: center; color: #e74c3c;">Error loading tasks: ${error.message}</div>`;
            }
        }

        document.getElementById('taskForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const formData = new FormData(e.target);
            const taskData = {
                title: formData.get('title'),
                description: formData.get('description')
            };
            
            try {
                const response = await fetch(`${API_BASE}/tasks`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(taskData)
                });
                
                if (response.ok) {
                    showStatus('Task added successfully!');
                    e.target.reset();
                    loadTasks();
                } else {
                    const error = await response.json();
                    showStatus(`Error: ${error.error}`, 'error');
                }
            } catch (error) {
                showStatus(`Error: ${error.message}`, 'error');
            }
        });

        // Load tasks on page load
        loadTasks();
        
        // Auto-refresh every 30 seconds
        setInterval(loadTasks, 30000);
    </script>
</body>
</html>
EOF

cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    upstream api_backend {
        server api:5000;
    }

    server {
        listen 80;
        server_name localhost;

        # Serve static files
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }

        # Proxy API requests
        location /api/ {
            proxy_pass http://api_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # CORS headers
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
        }

        # Health check endpoint
        location /health {
            proxy_pass http://api_backend/health;
        }
    }
}
EOF

cat > Dockerfile << 'EOF'
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
EOF

cd ..
```

4. **Create docker-compose.yml for the full stack:**
```yaml
version: '3.8'

services:
  # Database
  db:
    image: postgres:13
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: apppass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser -d appdb"]
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

  # API Backend
  api:
    build: ./api
    environment:
      DB_HOST: db
      DB_NAME: appdb
      DB_USER: appuser
      DB_PASSWORD: apppass
      REDIS_HOST: cache
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_healthy
    restart: unless-stopped

  # Frontend
  frontend:
    build: ./frontend
    ports:
      - "8080:80"
    depends_on:
      - api
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:

networks:
  default:
    name: fullstack-network
```

5. **Build and start the application:**
```bash
docker-compose build
docker-compose up -d
```

6. **Monitor startup:**
```bash
docker-compose logs -f
```

7. **Test the application:**
```bash
# Check all services are healthy
docker-compose ps

# Test health endpoints
curl http://localhost:8080/health

# Open in browser
echo "Open http://localhost:8080 in your browser"
```

---

## Exercise 4.3: Environment-Specific Configurations (45 minutes)

### Objective
Learn to manage different environments (development, testing, production) with Docker Compose.

### Instructions

1. **Create environment-specific configuration:**
```bash
mkdir compose-environments
cd compose-environments
```

2. **Create base docker-compose.yml:**
```yaml
version: '3.8'

services:
  app:
    build: .
    environment:
      - NODE_ENV
      - LOG_LEVEL
      - DB_HOST=db
    depends_on:
      - db

  db:
    image: postgres:13
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

3. **Create development override:**
```yaml
# docker-compose.override.yml (automatically used in development)
version: '3.8'

services:
  app:
    ports:
      - "3000:3000"
    volumes:
      - ./src:/app/src:ro
    environment:
      - NODE_ENV=development
      - LOG_LEVEL=debug
    command: npm run dev

  db:
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: devdb
      POSTGRES_USER: devuser
      POSTGRES_PASSWORD: devpass
```

4. **Create testing configuration:**
```yaml
# docker-compose.test.yml
version: '3.8'

services:
  app:
    environment:
      - NODE_ENV=test
      - LOG_LEVEL=info
    command: npm test

  db:
    environment:
      POSTGRES_DB: testdb
      POSTGRES_USER: testuser
      POSTGRES_PASSWORD: testpass
    tmpfs:
      - /var/lib/postgresql/data  # Use in-memory database for tests

  test-runner:
    build: .
    environment:
      - NODE_ENV=test
      - DB_HOST=db
    command: npm run test:integration
    depends_on:
      - app
      - db
```

5. **Create production configuration:**
```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  app:
    restart: always
    environment:
      - NODE_ENV=production
      - LOG_LEVEL=warn
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '0.5'
          memory: 512M

  db:
    restart: always
    environment:
      POSTGRES_DB: proddb
      POSTGRES_USER: produser
      POSTGRES_PASSWORD: ${PROD_DB_PASSWORD}
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.prod.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - app
    restart: always
```

6. **Create simple Node.js app for testing:**
```javascript
// package.json
{
  "name": "multi-env-app",
  "version": "1.0.0",
  "scripts": {
    "start": "node server.js",
    "dev": "node server.js",
    "test": "echo 'Running tests...' && exit 0",
    "test:integration": "echo 'Running integration tests...' && exit 0"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
```

```javascript
// server.js
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    environment: process.env.NODE_ENV,
    logLevel: process.env.LOG_LEVEL,
    message: `Running in ${process.env.NODE_ENV} mode`
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(port, () => {
  console.log(`Server running on port ${port} in ${process.env.NODE_ENV} mode`);
});
```

```dockerfile
# Dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

7. **Test different environments:**

**Development (uses docker-compose.override.yml automatically):**
```bash
docker-compose up -d
curl http://localhost:3000
docker-compose logs
docker-compose down
```

**Testing:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.test.yml up --build
docker-compose -f docker-compose.yml -f docker-compose.test.yml down
```

**Production:**
```bash
# First, set production password
export PROD_DB_PASSWORD=super-secure-password

docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
docker-compose -f docker-compose.yml -f docker-compose.prod.yml ps
docker-compose -f docker-compose.yml -f docker-compose.prod.yml down
```

---

## Exercise 4.4: Testing Workflows with Compose (60 minutes)

### Objective
Create comprehensive testing workflows using Docker Compose.

### Instructions

1. **Create testing project structure:**
```bash
mkdir testing-workflow
cd testing-workflow
mkdir app tests
```

2. **Create the application:**
```bash
cd app

cat > app.py << 'EOF'
from flask import Flask, jsonify, request
import sqlite3
import os

app = Flask(__name__)
DATABASE = '/data/test.db'

def init_db():
    os.makedirs('/data', exist_ok=True)
    conn = sqlite3.connect(DATABASE)
    conn.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            username TEXT UNIQUE NOT NULL,
            email TEXT NOT NULL
        )
    ''')
    conn.commit()
    conn.close()

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

@app.route('/users', methods=['GET'])
def get_users():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    users = conn.execute('SELECT * FROM users').fetchall()
    conn.close()
    return jsonify([dict(user) for user in users])

@app.route('/users', methods=['POST'])
def create_user():
    data = request.get_json()
    if not data or 'username' not in data or 'email' not in data:
        return jsonify({'error': 'Username and email required'}), 400
    
    try:
        conn = sqlite3.connect(DATABASE)
        cursor = conn.execute(
            'INSERT INTO users (username, email) VALUES (?, ?)',
            (data['username'], data['email'])
        )
        user_id = cursor.lastrowid
        conn.commit()
        conn.close()
        return jsonify({'id': user_id, 'username': data['username'], 'email': data['email']}), 201
    except sqlite3.IntegrityError:
        return jsonify({'error': 'Username already exists'}), 409

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000)
EOF

cat > requirements.txt << 'EOF'
flask==2.2.0
EOF

cat > Dockerfile << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
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
selenium==4.8.0
EOF

cat > test_unit.py << 'EOF'
import pytest
import sys
import os
sys.path.append('/app')

def test_basic_math():
    """Basic unit test"""
    assert 1 + 1 == 2

def test_string_operations():
    """Test string operations"""
    assert "hello".upper() == "HELLO"
    assert "world".capitalize() == "World"

def test_list_operations():
    """Test list operations"""
    test_list = [1, 2, 3]
    test_list.append(4)
    assert len(test_list) == 4
    assert test_list[-1] == 4

class TestUserValidation:
    """Test user-related validation logic"""
    
    def test_valid_email_format(self):
        """Test email validation"""
        valid_emails = ["test@example.com", "user.name@domain.co.uk"]
        for email in valid_emails:
            assert "@" in email
            assert "." in email
    
    def test_username_requirements(self):
        """Test username validation"""
        valid_usernames = ["testuser", "user123", "test_user"]
        for username in valid_usernames:
            assert len(username) >= 3
            assert username.isalnum() or "_" in username
EOF

cat > test_integration.py << 'EOF'
import pytest
import requests
import time
import json

BASE_URL = 'http://app:5000'

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
    assert wait_for_app(), "Application failed to start"

def test_health_endpoint():
    """Test application health"""
    response = requests.get(f'{BASE_URL}/health')
    assert response.status_code == 200
    data = response.json()
    assert data['status'] == 'healthy'

def test_get_users_empty():
    """Test getting users when database is empty"""
    response = requests.get(f'{BASE_URL}/users')
    assert response.status_code == 200
    users = response.json()
    assert isinstance(users, list)

def test_create_user():
    """Test creating a new user"""
    user_data = {
        'username': 'testuser',
        'email': 'test@example.com'
    }
    response = requests.post(f'{BASE_URL}/users', json=user_data)
    assert response.status_code == 201
    user = response.json()
    assert user['username'] == user_data['username']
    assert user['email'] == user_data['email']
    assert 'id' in user

def test_create_user_validation():
    """Test user creation validation"""
    # Missing email
    response = requests.post(f'{BASE_URL}/users', json={'username': 'testuser2'})
    assert response.status_code == 400
    
    # Missing username
    response = requests.post(f'{BASE_URL}/users', json={'email': 'test2@example.com'})
    assert response.status_code == 400
    
    # Empty data
    response = requests.post(f'{BASE_URL}/users', json={})
    assert response.status_code == 400

def test_duplicate_username():
    """Test duplicate username handling"""
    user_data = {
        'username': 'duplicate_test',
        'email': 'first@example.com'
    }
    
    # Create first user
    response = requests.post(f'{BASE_URL}/users', json=user_data)
    assert response.status_code == 201
    
    # Try to create duplicate
    user_data['email'] = 'second@example.com'
    response = requests.post(f'{BASE_URL}/users', json=user_data)
    assert response.status_code == 409

def test_get_users_with_data():
    """Test getting users after creating some"""
    response = requests.get(f'{BASE_URL}/users')
    assert response.status_code == 200
    users = response.json()
    assert len(users) >= 2  # At least the users we created
EOF

cat > test_load.py << 'EOF'
import pytest
import requests
import threading
import time
import statistics

BASE_URL = 'http://app:5000'

class LoadTestResults:
    def __init__(self):
        self.response_times = []
        self.errors = 0
        self.total_requests = 0

results = LoadTestResults()

def make_request():
    """Make a single request and record metrics"""
    start_time = time.time()
    try:
        response = requests.get(f'{BASE_URL}/health', timeout=5)
        duration = time.time() - start_time
        results.response_times.append(duration)
        if response.status_code != 200:
            results.errors += 1
    except Exception:
        results.errors += 1
    
    results.total_requests += 1

def test_load_health_endpoint():
    """Load test the health endpoint"""
    num_requests = 50
    num_threads = 5
    requests_per_thread = num_requests // num_threads
    
    threads = []
    start_time = time.time()
    
    # Create and start threads
    for _ in range(num_threads):
        thread = threading.Thread(target=lambda: [make_request() for _ in range(requests_per_thread)])
        threads.append(thread)
        thread.start()
    
    # Wait for all threads to complete
    for thread in threads:
        thread.join()
    
    total_time = time.time() - start_time
    
    # Analyze results
    assert results.total_requests == num_requests
    assert results.errors == 0, f"Load test had {results.errors} errors"
    
    if results.response_times:
        avg_response_time = statistics.mean(results.response_times)
        max_response_time = max(results.response_times)
        requests_per_second = num_requests / total_time
        
        print(f"\n=== Load Test Results ===")
        print(f"Total requests: {results.total_requests}")
        print(f"Errors: {results.errors}")
        print(f"Average response time: {avg_response_time:.3f}s")
        print(f"Max response time: {max_response_time:.3f}s")
        print(f"Requests per second: {requests_per_second:.2f}")
        
        # Performance assertions
        assert avg_response_time < 1.0, f"Average response time too high: {avg_response_time:.3f}s"
        assert max_response_time < 2.0, f"Max response time too high: {max_response_time:.3f}s"
        assert requests_per_second > 10, f"Throughput too low: {requests_per_second:.2f} RPS"
EOF

cat > Dockerfile << 'EOF'
FROM python:3.9-slim

# Install dependencies for testing
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tests
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["pytest", "-v"]
EOF

cd ..
```

4. **Create comprehensive docker-compose for testing:**
```yaml
# docker-compose.test.yml
version: '3.8'

services:
  # Application under test
  app:
    build: ./app
    volumes:
      - app_data:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Unit tests
  unit-tests:
    build: ./tests
    command: pytest test_unit.py -v --tb=short
    profiles:
      - unit

  # Integration tests
  integration-tests:
    build: ./tests
    command: pytest test_integration.py -v --tb=short
    depends_on:
      app:
        condition: service_healthy
    profiles:
      - integration

  # Load tests
  load-tests:
    build: ./tests
    command: pytest test_load.py -v --tb=short
    depends_on:
      app:
        condition: service_healthy
    profiles:
      - load

  # All tests with reporting
  all-tests:
    build: ./tests
    command: >
      pytest -v 
      --html=/reports/report.html 
      --self-contained-html
      --cov=/app
      --cov-report=html:/reports/coverage/
      --tb=short
    volumes:
      - ./test-reports:/reports
    depends_on:
      app:
        condition: service_healthy
    profiles:
      - all

volumes:
  app_data:
```

5. **Run different test suites:**

**Unit tests only:**
```bash
docker-compose -f docker-compose.test.yml --profile unit up --build unit-tests
```

**Integration tests only:**
```bash
docker-compose -f docker-compose.test.yml --profile integration up --build integration-tests
```

**Load tests only:**
```bash
docker-compose -f docker-compose.test.yml --profile load up --build load-tests
```

**All tests with reports:**
```bash
mkdir test-reports
docker-compose -f docker-compose.test.yml --profile all up --build all-tests
```

**Run complete test pipeline:**
```bash
# Create test script
cat > run-tests.sh << 'EOF'
#!/bin/bash
set -e

echo "🧪 Starting comprehensive test suite..."

echo "📋 Running unit tests..."
docker-compose -f docker-compose.test.yml --profile unit up --build --abort-on-container-exit unit-tests

echo "🔗 Running integration tests..."
docker-compose -f docker-compose.test.yml --profile integration up --build --abort-on-container-exit integration-tests

echo "⚡ Running load tests..."
docker-compose -f docker-compose.test.yml --profile load up --build --abort-on-container-exit load-tests

echo "📊 Generating test reports..."
mkdir -p test-reports
docker-compose -f docker-compose.test.yml --profile all up --build --abort-on-container-exit all-tests

echo "✅ All tests completed successfully!"
echo "📈 Check test-reports/ for detailed results"

# Cleanup
docker-compose -f docker-compose.test.yml down --volumes
EOF

chmod +x run-tests.sh
./run-tests.sh
```

6. **Check test results:**
```bash
# View test reports (if generated)
ls -la test-reports/
echo "Open test-reports/report.html in your browser to view detailed test results"
```

---

## Day 4 Summary & Best Practices

### Key Concepts Learned
1. **Docker Compose Basics**: Services, networks, volumes
2. **Multi-container Applications**: Service orchestration
3. **Environment Management**: Development, testing, production configs
4. **Health Checks**: Service dependencies and readiness
5. **Testing Workflows**: Comprehensive test automation
6. **Profiles**: Conditional service execution

### Docker Compose Best Practices for QA
1. **Use health checks** for service dependencies
2. **Separate configurations** for different environments
3. **Use profiles** for different test scenarios
4. **Document service dependencies** clearly
5. **Use specific image tags** in production
6. **Implement proper cleanup** procedures
7. **Use volumes** for persistent test data

### Common Commands Reference
```bash
# Basic operations
docker-compose up -d                    # Start services in background
docker-compose down                     # Stop and remove services
docker-compose ps                       # List running services
docker-compose logs -f [service]        # Follow logs

# Building and updating
docker-compose build                    # Build all services
docker-compose up --build              # Build and start
docker-compose pull                     # Pull latest images

# Environment-specific
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up
docker-compose --profile test up       # Run specific profiles

# Scaling and management
docker-compose up --scale web=3         # Scale service
docker-compose exec service bash       # Execute command in service
```

### Testing Workflow Patterns
1. **Isolated Test Environments**: Each test suite in its own network
2. **Service Dependencies**: Use health checks and depends_on
3. **Test Data Management**: Use volumes or temporary filesystems
4. **Parallel Testing**: Multiple test runners with different profiles
5. **Report Generation**: Persistent volumes for test artifacts

### Next Day Preview
Tomorrow we'll learn:
- CI/CD integration with Docker
- Advanced debugging techniques
- Security best practices
- Production deployment strategies

---

**🎉 Outstanding work on Day 4!**

You now know how to orchestrate complex testing environments with Docker Compose!