# Docker Training for QA Engineers

Welcome to the comprehensive Docker training program designed specifically for QA Engineers. This course will take you from zero Docker knowledge to being proficient in using Docker for testing environments, containerized applications, and CI/CD pipelines.

## 🎯 Training Objectives

By the end of this training, you will be able to:
- Understand Docker fundamentals and containerization concepts
- Set up Docker on Linux and macOS environments
- Create and manage Docker containers for testing
- Build custom Docker images for test applications
- Use Docker Compose for multi-service testing environments
- Integrate Docker into CI/CD pipelines
- Debug and troubleshoot containerized applications
- Apply security best practices for testing environments

## 📋 Prerequisites

- Basic command line knowledge (Terminal/Bash)
- Understanding of software testing concepts
- Familiarity with web applications and APIs
- Basic knowledge of YAML syntax (helpful but not required)

## 🗓️ Training Schedule (5-Day Program)

### Day 1: Docker Fundamentals & Installation
**Duration:** 6 hours (including breaks and hands-on practice)

#### Morning Session (3 hours)
- **Introduction to Containerization (45 min)**
  - What is containerization?
  - Virtual Machines vs Containers
  - Benefits for QA Engineers
  - Docker ecosystem overview

- **Docker Architecture (45 min)**
  - Docker Engine
  - Docker Images vs Containers
  - Docker Registry (Docker Hub)
  - Dockerfile concepts

- **Installation & Setup (90 min)**
  - Installing Docker on Linux (Ubuntu/CentOS)
  - Installing Docker on macOS
  - Docker Desktop overview
  - Verifying installation
  - Basic CLI commands

#### Afternoon Session (3 hours)
- **First Steps with Docker (90 min)**
  - Running your first container
  - Basic container commands
  - Container lifecycle management
  - Working with container logs

- **Docker Images Deep Dive (90 min)**
  - Understanding image layers
  - Pulling images from Docker Hub
  - Image inspection and management
  - Tagging and versioning

**Hands-on Exercises:** [exercises/day1/](exercises/day1/)

---

### Day 2: Working with Containers & Networking
**Duration:** 6 hours

#### Morning Session (3 hours)
- **Container Management (90 min)**
  - Starting, stopping, and restarting containers
  - Container inspection and monitoring
  - Resource management (CPU, memory limits)
  - Container cleanup strategies

- **Data Management (90 min)**
  - Understanding container filesystem
  - Volumes vs Bind mounts
  - Persistent data storage
  - Sharing data between containers

#### Afternoon Session (3 hours)
- **Docker Networking (90 min)**
  - Default networking concepts
  - Bridge, host, and none networks
  - Custom networks creation
  - Container communication

- **Environment Variables & Configuration (90 min)**
  - Setting environment variables
  - Configuration management
  - Secrets handling basics
  - Port mapping and exposure

**Hands-on Exercises:** [exercises/day2/](exercises/day2/)

---

### Day 3: Building Custom Images & Dockerfile
**Duration:** 6 hours

#### Morning Session (3 hours)
- **Dockerfile Fundamentals (90 min)**
  - Dockerfile syntax and instructions
  - FROM, RUN, COPY, ADD commands
  - WORKDIR, ENV, EXPOSE instructions
  - Best practices for layer optimization

- **Building Images (90 min)**
  - Docker build process
  - Build context optimization
  - Multi-stage builds
  - Image size optimization techniques

#### Afternoon Session (3 hours)
- **Advanced Dockerfile Techniques (90 min)**
  - ARG vs ENV variables
  - ENTRYPOINT vs CMD
  - Health checks implementation
  - Security considerations

- **Image Registry Management (90 min)**
  - Pushing images to Docker Hub
  - Private registry concepts
  - Image scanning and security
  - Versioning strategies

**Hands-on Exercises:** [exercises/day3/](exercises/day3/)

---

### Day 4: Docker Compose & Multi-Container Applications
**Duration:** 6 hours

#### Morning Session (3 hours)
- **Introduction to Docker Compose (90 min)**
  - What is Docker Compose?
  - YAML syntax for docker-compose.yml
  - Services, networks, and volumes
  - Compose vs individual containers

- **Multi-Service Applications (90 min)**
  - Web application + database setup
  - Service dependencies
  - Environment-specific configurations
  - Scaling services

#### Afternoon Session (3 hours)
- **Testing Environments with Compose (90 min)**
  - Creating test environments
  - Database seeding and migrations
  - Integration testing setup
  - Parallel test execution

- **Advanced Compose Features (90 min)**
  - Override files for different environments
  - Profiles for conditional services
  - External networks and volumes
  - Compose in CI/CD pipelines

**Hands-on Exercises:** [exercises/day4/](exercises/day4/)

---

### Day 5: Testing Strategies & CI/CD Integration
**Duration:** 6 hours

#### Morning Session (3 hours)
- **Testing Strategies with Docker (90 min)**
  - Unit testing in containers
  - Integration testing approaches
  - End-to-end testing setup
  - Test data management

- **Debugging & Troubleshooting (90 min)**
  - Container debugging techniques
  - Log management and analysis
  - Performance monitoring
  - Common issues and solutions

#### Afternoon Session (3 hours)
- **CI/CD Integration (90 min)**
  - Docker in GitHub Actions
  - GitLab CI with Docker
  - Jenkins pipeline integration
  - Automated testing workflows

- **Security & Best Practices (90 min)**
  - Container security fundamentals
  - Image vulnerability scanning
  - Secrets management
  - Production readiness checklist

**Hands-on Exercises:** [exercises/day5/](exercises/day5/)

---

## 🛠️ Required Tools & Software

### For Linux Users:
- Docker Engine (latest stable version)
- Docker Compose
- Text editor (VS Code, vim, nano)
- Git
- curl/wget

### For macOS Users:
- Docker Desktop for Mac
- Text editor (VS Code, TextEdit)
- Git
- Homebrew (recommended)

### Online Accounts:
- Docker Hub account (free)
- GitHub account (for CI/CD exercises)

## 📚 Learning Resources

### Official Documentation:
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)

### Recommended Reading:
- "Docker Deep Dive" by Nigel Poulton
- "Docker for Developers" by Richard Bullington-McGuire
- "Testing Strategies in a Microservice Architecture" by Toby Clemson

### Online Courses & Tutorials:
- Docker Official Training
- Play with Docker (hands-on browser-based learning)
- Katacoda Docker Scenarios

## 🔧 Practice Environment Setup

All hands-on exercises are located in the `exercises/` directory. Each day has its own folder with:
- Step-by-step instructions
- Sample applications
- Configuration files
- Solution guides

## 📊 Assessment & Certification

### Daily Assessments:
- Practical exercises completion
- Quiz questions
- Peer code reviews

### Final Project:
Create a complete testing environment for a multi-tier web application including:
- Web application container
- Database container
- Test automation container
- CI/CD pipeline configuration

## 🤝 Support & Community

- **Instructor Support:** Available during training hours
- **Peer Learning:** Encouraged throughout the program
- **Online Community:** Join our Slack workspace for ongoing support

## 📞 Getting Help

If you encounter issues during the training:
1. Check the troubleshooting section in each exercise
2. Ask a colleague or instructor
3. Consult the official Docker documentation
4. Search Stack Overflow or Docker forums

---

## 🚀 Next Steps After Training

After completing this training, consider:
- Advanced Docker topics (Swarm, Kubernetes basics)
- Container orchestration platforms
- Advanced CI/CD pipeline design
- Security-focused container practices
- Microservices testing strategies

**Happy Learning!** 🐳

---

*This training material is designed for QA Engineers at all levels. Adjust the pace according to your team's experience and needs.*