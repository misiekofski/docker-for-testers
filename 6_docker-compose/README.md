## docker-compose and yaml files

1. In our folder there is app.py - this is an application written in Python which will use redis (redis is a host, and we are using default port = `6379`).

2. What we want to do is to run two containers and to be able them to communicate. What is important is that in app.py there is an important line:

```python
cache = redis.Redis(host='redis', port=6379)
```

3. This means python app will use host 'redis' as an adress of redis container. We don't need to provide ip or url. Port 6379 won't be open to external networks, so only application running in docker will be able to communicate it.

2. Create Dockerfile to build python app (copy `app.py` to `/code` in docker, set up workdir as `/code`, then install all requirements (just like `npm install`) and run `python app.py` at last):

```Dockerfile
FROM python:3.6-alpine
ADD . /code
WORKDIR /code
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
```

3. Define services (containers) in a docker-compose.yml file

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

4. Build and run app with Compose by entering `docker-compose up -d` in command line. What it will do it will run two services: 
- redis
- python app in flask
- `-d` is for detached

5. Go to http://localhost:5000 and refresh site few times.

6. When you want to stop it, run `docker-compose down` in command line