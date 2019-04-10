## Now we are gonna automate previous lesson

1. Create from node image another image which will have preinstalled `@angular/cli`

2. Run container based on newly built container from step 1 and run `npm install` + `ng serve`
- don't forget to mount volume to current folder which is `%cd%` in command line and `$PWD` in Powershell / Bash
- remember to stop and remove previous container because it uses port `4200`
- use Dockerfile

Let's call this time this file: Docker-angular
```Dockerfile
FROM node
RUN npm install -g @angular/cli
ENV CHOKIDAR_USEPOLLING=true
```

3. Build docker with angular with `docker build -f Dockerfile-angular -t ourangular .`

4. You can check if that was build with `docker images`. You should have seen `ourangular` image, which already has @angular/cli installed.

5. Then you can run (it will store and speed up a bit running app for next time) by `docker run -p 4200:4200 -v ${pwd}:/var/www -w "/var/www" ourangular npm install && ng serve --host 0.0.0.0`
