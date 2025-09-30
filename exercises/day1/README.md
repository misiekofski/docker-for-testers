# Day 1 Exercises: Docker Fundamentals & Installation

## Exercise 1.1: Docker Installation Verification (30 minutes)

### Objective
Verify that Docker is properly installed and working on your system.

### Instructions

#### For Linux Users:
```bash
# Check Docker version
docker --version

# Check Docker Engine info
docker info

# Test Docker installation
docker run hello-world

# Check running containers
docker ps

# Check all containers (including stopped)
docker ps -a
```

#### For macOS Users:
```bash
# Same commands as Linux, but first ensure Docker Desktop is running

# Check Docker version
docker --version

# Check Docker Engine info
docker info

# Test Docker installation
docker run hello-world

# Check running containers
docker ps

# Check all containers (including stopped)
docker ps -a
```

### Expected Results
- Docker version should be displayed
- `docker info` should show system information
- `hello-world` container should run successfully
- You should see the hello-world container in `docker ps -a`

### Troubleshooting
- **Linux:** If permission denied, add user to docker group: `sudo usermod -aG docker $USER`
- **macOS:** Ensure Docker Desktop is running from Applications

---

## Exercise 1.2: Your First Container (45 minutes)

### Objective
Learn basic container operations with a simple web server.

### Instructions

1. **Run an Nginx web server container:**
```bash
docker run -d -p 8080:80 --name my-nginx nginx:latest
```

2. **Check if container is running:**
```bash
docker ps
```

3. **Access the web server:**
   - Open browser and go to `http://localhost:8080`
   - You should see the Nginx welcome page

4. **View container logs:**
```bash
docker logs my-nginx
```

5. **Execute commands inside the container:**
```bash
docker exec -it my-nginx bash
```

6. **Inside the container, explore:**
```bash
# Check running processes
ps aux

# Check nginx configuration
cat /etc/nginx/nginx.conf

# Exit the container
exit
```

7. **Stop and remove the container:**
```bash
docker stop my-nginx
docker rm my-nginx
```

### Questions to Answer
1. What does the `-d` flag do?
2. What does `-p 8080:80` mean?
3. How do you view real-time logs?
4. What happens when you stop a container?

---

## Exercise 1.3: Working with Different Images (30 minutes)

### Objective
Practice pulling and running different types of containers.

### Instructions

1. **Pull different images:**
```bash
# Pull Ubuntu image
docker pull ubuntu:22.04

# Pull Python image
docker pull python:3.9-slim

# Pull Redis image
docker pull redis:6-alpine
```

2. **List downloaded images:**
```bash
docker images
```

3. **Run an interactive Ubuntu container:**
```bash
docker run -it --name ubuntu-test ubuntu:22.04 bash
```

4. **Inside Ubuntu container:**
```bash
# Update package list
apt update

# Install a package
apt install -y curl

# Test curl
curl --version

# Exit
exit
```

5. **Run a Python container with a simple script:**
```bash
docker run --rm python:3.9-slim python -c "print('Hello from Python in Docker!')"
```

6. **Run Redis in the background:**
```bash
docker run -d --name redis-test redis:6-alpine
```

7. **Connect to Redis:**
```bash
docker exec -it redis-test redis-cli ping
```

8. **Clean up:**
```bash
docker stop redis-test
docker rm redis-test ubuntu-test
```

### Questions to Answer
1. What's the difference between `ubuntu:22.04` and `ubuntu:latest`?
2. What does `--rm` flag do?
3. How can you see the size of images?

---

## Exercise 1.4: Container Lifecycle Management (45 minutes)

### Objective
Understand container states and lifecycle management.

### Instructions

1. **Create a container without starting it:**
```bash
docker create --name lifecycle-test nginx:latest
```

2. **Check container status:**
```bash
docker ps -a
```

3. **Start the container:**
```bash
docker start lifecycle-test
```

4. **Check status again:**
```bash
docker ps
```

5. **Pause the container:**
```bash
docker pause lifecycle-test
```

6. **Try to access it (should not respond):**
```bash
curl http://localhost
```

7. **Unpause the container:**
```bash
docker unpause lifecycle-test
```

8. **Restart the container:**
```bash
docker restart lifecycle-test
```

9. **View detailed container information:**
```bash
docker inspect lifecycle-test
```

10. **Monitor container statistics:**
```bash
docker stats lifecycle-test
```
(Press Ctrl+C to exit)

11. **Stop and remove:**
```bash
docker stop lifecycle-test
docker rm lifecycle-test
```

### Container States Diagram
```
Created → Running → Paused → Running → Stopped → Removed
    ↑         ↓                    ↓         ↓
    └─────────┴────────────────────┴─────────┘
```

---

## Exercise 1.5: Image Management (30 minutes)

### Objective
Learn to manage Docker images effectively.

### Instructions

1. **Search for images on Docker Hub:**
```bash
docker search nginx
```

2. **Pull specific versions:**
```bash
docker pull nginx:1.20
docker pull nginx:alpine
```

3. **Compare image sizes:**
```bash
docker images nginx
```

4. **Inspect an image:**
```bash
docker inspect nginx:alpine
```

5. **View image history:**
```bash
docker history nginx:alpine
```

6. **Tag an image:**
```bash
docker tag nginx:alpine my-nginx:latest
```

7. **Remove specific images:**
```bash
docker rmi nginx:1.20
docker rmi my-nginx:latest
```

8. **Remove unused images:**
```bash
docker image prune
```

### Questions to Answer
1. Why are Alpine images typically smaller?
2. What information does `docker inspect` provide?
3. How do tags work in Docker?

---

## Exercise 1.6: Hands-on Challenge (45 minutes)

### Objective
Apply everything you've learned in a practical scenario.

### Challenge: Set up a Development Environment

You need to set up a quick development environment with:
1. A web server (nginx) serving on port 8080
2. A database (postgres) for data storage
3. A Redis cache for session storage

### Requirements
1. All containers should be named appropriately
2. Web server should be accessible via browser
3. You should be able to connect to both database and Redis
4. Document all commands used

### Solution Steps
(Try to solve this yourself first, then check the solution below)

<details>
<summary>Click to see solution</summary>

```bash
# 1. Run Nginx web server
docker run -d -p 8080:80 --name dev-webserver nginx:latest

# 2. Run PostgreSQL database
docker run -d \
  --name dev-database \
  -e POSTGRES_DB=testdb \
  -e POSTGRES_USER=testuser \
  -e POSTGRES_PASSWORD=testpass \
  -p 5432:5432 \
  postgres:13

# 3. Run Redis cache
docker run -d --name dev-cache -p 6379:6379 redis:6-alpine

# 4. Verify all containers are running
docker ps

# 5. Test connections
# Web server: http://localhost:8080
# Database: docker exec -it dev-database psql -U testuser -d testdb
# Redis: docker exec -it dev-cache redis-cli ping

# 6. Cleanup when done
docker stop dev-webserver dev-database dev-cache
docker rm dev-webserver dev-database dev-cache
```

</details>

---

## Additional Resources for Day 1

### Useful Commands Reference
```bash
# Container operations
docker run [OPTIONS] IMAGE [COMMAND]
docker start/stop/restart CONTAINER
docker pause/unpause CONTAINER
docker rm CONTAINER
docker ps [-a]

# Image operations
docker images
docker pull IMAGE
docker rmi IMAGE
docker inspect IMAGE/CONTAINER
docker history IMAGE

# Information and monitoring
docker info
docker version
docker logs CONTAINER
docker stats CONTAINER
docker exec -it CONTAINER COMMAND
```

### Common Flags
- `-d`: Run in detached mode (background)
- `-it`: Interactive terminal
- `-p HOST_PORT:CONTAINER_PORT`: Port mapping
- `--name NAME`: Assign name to container
- `--rm`: Remove container when it exits
- `-e KEY=VALUE`: Set environment variable

### Next Day Preview
Tomorrow we'll dive deeper into:
- Data persistence with volumes
- Container networking
- Environment configuration
- Inter-container communication

---

**🎉 Congratulations! You've completed Day 1 exercises!**

Make sure to ask questions and clarify any concepts before moving to Day 2.