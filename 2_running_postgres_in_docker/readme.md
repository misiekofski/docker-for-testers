## Run postgres locally

### Prerequisites:
* Installed and running Docker on Windows 10

### Excercises:

1. This time we are gonna pull image to our local computer

```posh
docker pull postgres
```

2. And run it with shortcuts (-d as detached, -e for environment variable). This time you haven't provided --name=something, and docker will create random names for you :) Run it two or three times and then check running containters

```posh
docker run --rm -d -e POSTGRES_PASSWORD=mypassword postgres
```
