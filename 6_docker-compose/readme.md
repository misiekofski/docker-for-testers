## docker-compose and yaml files

1. In our folder there is app.py - this is an application written in Python which will use redis (redis is a host, and we are using default port = `6379`).

2. Create Dockerfile:

```Dockerfile
FROM python:3.4-alpine
ADD . /code
WORKDIR /code
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
```

3. Define services in a Compose file
```yaml
version: '3'
services:
  web:
    build: .
    ports:
     - "5000:5000"
  redis:
    image: "redis:alpine"
```

4. Build and run app with Compose by entering `docker-compose up`