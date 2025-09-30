# Day 2 Exercises: Containers, Networking & Data Management

## Exercise 2.1: Data Persistence with Volumes (45 minutes)

### Objective
Learn how to persist data beyond container lifecycle using volumes and bind mounts.

### Part A: Named Volumes

1. **Create a named volume:**
```bash
docker volume create my-data-volume
```

2. **List volumes:**
```bash
docker volume ls
```

3. **Run a container with the volume:**
```bash
docker run -it --name volume-test -v my-data-volume:/data ubuntu:20.04 bash
```

4. **Inside the container, create some data:**
```bash
echo "This data should persist!" > /data/persistent-file.txt
echo "Created on $(date)" >> /data/persistent-file.txt
ls -la /data/
exit
```

5. **Remove the container:**
```bash
docker rm volume-test
```

6. **Create a new container with the same volume:**
```bash
docker run -it --name volume-test2 -v my-data-volume:/data ubuntu:20.04 bash
```

7. **Check if data persisted:**
```bash
cat /data/persistent-file.txt
exit
```

8. **Inspect the volume:**
```bash
docker volume inspect my-data-volume
```

### Part B: Bind Mounts

1. **Create a local directory:**
```bash
# Linux/macOS
mkdir -p $HOME/docker-bind-test
echo "Local file content" > $HOME/docker-bind-test/local-file.txt

# Windows (in PowerShell)
# mkdir $env:USERPROFILE\docker-bind-test
# echo "Local file content" | Out-File -FilePath $env:USERPROFILE\docker-bind-test\local-file.txt
```

2. **Run container with bind mount:**
```bash
# Linux/macOS
docker run -it --name bind-test -v $HOME/docker-bind-test:/app/data ubuntu:20.04 bash

# Windows
# docker run -it --name bind-test -v ${env:USERPROFILE}\docker-bind-test:/app/data ubuntu:20.04 bash
```

3. **Inside container:**
```bash
ls -la /app/data/
echo "Added from container" >> /app/data/container-file.txt
cat /app/data/local-file.txt
exit
```

4. **Check local directory:**
```bash
# Linux/macOS
ls -la $HOME/docker-bind-test/

# Windows
# dir $env:USERPROFILE\docker-bind-test\
```

### Questions to Answer
1. What's the difference between volumes and bind mounts?
2. Where are named volumes stored on the host system?
3. When would you use each approach?

---

## Exercise 2.2: Container Resource Management (30 minutes)

### Objective
Learn to control container resource usage for testing environments.

### Instructions

1. **Run container with memory limit:**
```bash
docker run -d --name memory-limited --memory=512m nginx:alpine
```

2. **Run container with CPU limit:**
```bash
docker run -d --name cpu-limited --cpus=0.5 nginx:alpine
```

3. **Monitor resource usage:**
```bash
docker stats memory-limited cpu-limited
```
(Press Ctrl+C to exit)

4. **Run a stress test container:**
```bash
docker run -d --name stress-test --memory=256m --cpus=0.3 progrium/stress --vm 1 --vm-bytes 200M --timeout 30s
```

5. **Monitor the stress test:**
```bash
docker stats stress-test
```

6. **Check container details:**
```bash
docker inspect memory-limited --format='{{.HostConfig.Memory}}'
docker inspect cpu-limited --format='{{.HostConfig.CpuQuota}}'
```

7. **Update container resources (if needed):**
```bash
docker update --memory=1g memory-limited
```

8. **Cleanup:**
```bash
docker stop memory-limited cpu-limited stress-test
docker rm memory-limited cpu-limited stress-test
```

### Resource Limits Reference
- `--memory=<size>`: Memory limit (b, k, m, g)
- `--cpus=<number>`: CPU limit (0.5 = half CPU)
- `--restart=<policy>`: Restart policy (no, always, on-failure, unless-stopped)

---

## Exercise 2.3: Container Networking Basics (45 minutes)

### Objective
Understand Docker networking and container communication.

### Part A: Default Bridge Network

1. **Create two containers on default bridge:**
```bash
docker run -d --name web1 nginx:alpine
docker run -d --name web2 nginx:alpine
```

2. **Inspect the default bridge network:**
```bash
docker network ls
docker network inspect bridge
```

3. **Get container IP addresses:**
```bash
docker inspect web1 --format='{{.NetworkSettings.IPAddress}}'
docker inspect web2 --format='{{.NetworkSettings.IPAddress}}'
```

4. **Test connectivity between containers:**
```bash
docker exec web1 ping -c 3 $(docker inspect web2 --format='{{.NetworkSettings.IPAddress}}')
```

### Part B: Custom Networks

1. **Create a custom network:**
```bash
docker network create --driver bridge my-test-network
```

2. **Run containers on custom network:**
```bash
docker run -d --name app1 --network my-test-network nginx:alpine
docker run -d --name app2 --network my-test-network nginx:alpine
```

3. **Test name resolution:**
```bash
docker exec app1 ping -c 3 app2
docker exec app2 ping -c 3 app1
```

4. **Connect existing container to network:**
```bash
docker network connect my-test-network web1
```

5. **Disconnect from network:**
```bash
docker network disconnect my-test-network web1
```

### Part C: Port Publishing

1. **Run web server with port mapping:**
```bash
docker run -d --name web-public -p 8080:80 nginx:alpine
```

2. **Run web server with random port:**
```bash
docker run -d --name web-random -P nginx:alpine
```

3. **Check port mappings:**
```bash
docker port web-public
docker port web-random
```

4. **Test access:**
```bash
curl http://localhost:8080
curl http://localhost:$(docker port web-random 80 | cut -d: -f2)
```

### Cleanup
```bash
docker stop web1 web2 app1 app2 web-public web-random
docker rm web1 web2 app1 app2 web-public web-random
docker network rm my-test-network
```

---

## Exercise 2.4: Environment Variables & Configuration (30 minutes)

### Objective
Learn to configure containers using environment variables.

### Instructions

1. **Run PostgreSQL with environment variables:**
```bash
docker run -d \
  --name postgres-env \
  -e POSTGRES_DB=testdb \
  -e POSTGRES_USER=testuser \
  -e POSTGRES_PASSWORD=secretpass \
  -p 5432:5432 \
  postgres:13
```

2. **Check environment variables:**
```bash
docker exec postgres-env env | grep POSTGRES
```

3. **Connect to the database:**
```bash
docker exec -it postgres-env psql -U testuser -d testdb
```

4. **Inside PostgreSQL:**
```sql
\l
CREATE TABLE test_data (id SERIAL, message TEXT);
INSERT INTO test_data (message) VALUES ('Hello from Docker!');
SELECT * FROM test_data;
\q
```

5. **Use environment file:**
Create a file `postgres.env`:
```bash
cat > postgres.env << EOF
POSTGRES_DB=proddb
POSTGRES_USER=produser
POSTGRES_PASSWORD=prodpass
EOF
```

6. **Run container with env file:**
```bash
docker run -d \
  --name postgres-file \
  --env-file postgres.env \
  -p 5433:5432 \
  postgres:13
```

7. **Verify different configuration:**
```bash
docker exec -it postgres-file psql -U produser -d proddb -c "\l"
```

### Part B: Configuration with Bind Mounts

1. **Create custom nginx configuration:**
```bash
mkdir nginx-config
cat > nginx-config/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name localhost;
        
        location / {
            return 200 "Custom Nginx Configuration!\n";
            add_header Content-Type text/plain;
        }
        
        location /health {
            return 200 "OK\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF
```

2. **Run nginx with custom config:**
```bash
docker run -d \
  --name custom-nginx \
  -p 8081:80 \
  -v $(pwd)/nginx-config/nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx:alpine
```

3. **Test custom configuration:**
```bash
curl http://localhost:8081
curl http://localhost:8081/health
```

### Cleanup
```bash
docker stop postgres-env postgres-file custom-nginx
docker rm postgres-env postgres-file custom-nginx
rm -f postgres.env
rm -rf nginx-config
```

---

## Exercise 2.5: Multi-Container Application (60 minutes)

### Objective
Build a complete application stack with multiple containers.

### Scenario
Create a simple blog application with:
- Web frontend (nginx)
- API backend (node.js)
- Database (PostgreSQL)
- Cache (Redis)

### Instructions

1. **Create custom network:**
```bash
docker network create blog-network
```

2. **Start PostgreSQL database:**
```bash
docker run -d \
  --name blog-db \
  --network blog-network \
  -e POSTGRES_DB=blogdb \
  -e POSTGRES_USER=bloguser \
  -e POSTGRES_PASSWORD=blogpass \
  postgres:13
```

3. **Start Redis cache:**
```bash
docker run -d \
  --name blog-cache \
  --network blog-network \
  redis:6-alpine
```

4. **Create a simple Node.js API:**
```bash
mkdir simple-api
cd simple-api

cat > package.json << 'EOF'
{
  "name": "simple-api",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0",
    "pg": "^8.7.0",
    "redis": "^4.0.0"
  }
}
EOF

cat > app.js << 'EOF'
const express = require('express');
const { Client } = require('pg');
const redis = require('redis');

const app = express();
const port = 3000;

app.use(express.json());

// Database connection
const dbClient = new Client({
  host: 'blog-db',
  port: 5432,
  database: 'blogdb',
  user: 'bloguser',
  password: 'blogpass'
});

// Redis connection
const redisClient = redis.createClient({
  socket: { host: 'blog-cache', port: 6379 }
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/api/posts', async (req, res) => {
  try {
    const result = await dbClient.query('SELECT * FROM posts ORDER BY id DESC');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(port, '0.0.0.0', async () => {
  try {
    await dbClient.connect();
    await redisClient.connect();
    console.log(`API server running on port ${port}`);
    
    // Create table if not exists
    await dbClient.query(`
      CREATE TABLE IF NOT EXISTS posts (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255),
        content TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Insert sample data
    await dbClient.query(`
      INSERT INTO posts (title, content) 
      VALUES ('First Post', 'This is my first blog post!')
      ON CONFLICT DO NOTHING
    `);
  } catch (err) {
    console.error('Startup error:', err);
  }
});
EOF

cat > Dockerfile << 'EOF'
FROM node:16-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]
EOF
```

5. **Build and run the API:**
```bash
docker build -t simple-api .
docker run -d \
  --name blog-api \
  --network blog-network \
  -p 3000:3000 \
  simple-api

cd ..
```

6. **Create nginx frontend:**
```bash
mkdir nginx-frontend
cd nginx-frontend

cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Simple Blog</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .post { border: 1px solid #ddd; padding: 20px; margin: 20px 0; }
    </style>
</head>
<body>
    <h1>Simple Blog</h1>
    <div id="posts"></div>
    
    <script>
        fetch('/api/posts')
            .then(response => response.json())
            .then(posts => {
                const postsDiv = document.getElementById('posts');
                posts.forEach(post => {
                    const postDiv = document.createElement('div');
                    postDiv.className = 'post';
                    postDiv.innerHTML = `
                        <h3>${post.title}</h3>
                        <p>${post.content}</p>
                        <small>Created: ${new Date(post.created_at).toLocaleString()}</small>
                    `;
                    postsDiv.appendChild(postDiv);
                });
            })
            .catch(err => {
                document.getElementById('posts').innerHTML = 
                    `<p style="color: red;">Error loading posts: ${err.message}</p>`;
            });
    </script>
</body>
</html>
EOF

cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream api_backend {
        server blog-api:3000;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }

        location /api/ {
            proxy_pass http://api_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
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
```

7. **Build and run nginx frontend:**
```bash
docker build -t blog-frontend .
docker run -d \
  --name blog-web \
  --network blog-network \
  -p 8080:80 \
  blog-frontend

cd ..
```

8. **Test the complete application:**
```bash
# Test API health
curl http://localhost:3000/health

# Test API posts
curl http://localhost:3000/api/posts

# Test complete application in browser
echo "Open http://localhost:8080 in your browser"
```

9. **Monitor all containers:**
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Verification Checklist
- [ ] All 4 containers are running
- [ ] Database contains sample posts
- [ ] API returns JSON data
- [ ] Frontend displays blog posts
- [ ] All containers can communicate

### Cleanup
```bash
docker stop blog-web blog-api blog-cache blog-db
docker rm blog-web blog-api blog-cache blog-db
docker network rm blog-network
docker rmi simple-api blog-frontend
rm -rf simple-api nginx-frontend
```

---

## Day 2 Summary & Best Practices

### Key Concepts Learned
1. **Data Persistence**: Volumes vs bind mounts
2. **Resource Management**: Memory and CPU limits
3. **Networking**: Custom networks and container communication
4. **Configuration**: Environment variables and config files
5. **Multi-container Applications**: Service orchestration

### Best Practices for QA Engineers
1. **Use named volumes** for test data that needs persistence
2. **Create custom networks** for isolated test environments
3. **Set resource limits** to prevent test containers from consuming all system resources
4. **Use environment variables** for configuration instead of hardcoded values
5. **Document container dependencies** for complex test setups

### Common Commands Reference
```bash
# Volume management
docker volume create/ls/rm/inspect

# Network management
docker network create/ls/rm/inspect/connect/disconnect

# Resource monitoring
docker stats
docker inspect --format='{{.HostConfig.Memory}}'

# Environment configuration
docker run -e KEY=VALUE
docker run --env-file file.env
```

### Next Day Preview
Tomorrow we'll learn:
- Writing Dockerfiles
- Building custom images
- Multi-stage builds
- Image optimization techniques

---

**🎉 Great job completing Day 2!**

You now understand how to create robust, networked, multi-container testing environments!