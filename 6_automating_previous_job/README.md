## Now we are gonna automate previous lesson

1. We need to create Dockerfile
```Dockerfile
# base image
FROM node:12.2.0

# install chrome for protractor tests
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
RUN apt-get update && apt-get install -yq google-chrome-stable

# set working directory
WORKDIR /app

# add `/app/node_modules/.bin` to $PATH
ENV PATH /app/node_modules/.bin:$PATH

# install and cache app dependencies
COPY package.json /app/package.json
RUN npm install
RUN npm install -g @angular/cli@7.3.9

# add app
COPY . /app

# start app
CMD ng serve --host 0.0.0.0
```

2. We can create .dockerignore (it's just like .gitignore but for docker)
```
node_modules
.git
.gitignore
```

3. Build and tag Docker image
```ps
docker build -t example:dev
```

4. And then run it:
```ps
docker run -v ${pwd}:/app -v /app/node_modules -p 4201:4200 --rm example:dev
```

- `--rm` removes the container and volumes if the container exists
