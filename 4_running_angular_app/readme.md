## Run angular app with volumes (files which are accessible on your hard disk)

1. This time we hook up our source code on windows into docker container. First check with `docker images` if you have node image downloaded. If not use `docker pull node`

2. Go into `/co-by-tu-wypic` folder and run docker command (-it means interactive console with /bin/bash)
- `-it` means interactive (we will have access to bash inside container)
- `-p 4200:4200` forwards ports from our computer to docker network
- `-e CHOKIDAR_USEPOLLING=true` is environment variable, which will poll every change we will make in code to docker
- `-v %cd%:/var/www` says we are mapping our current directory (in which we run our command) to directory inside container /var/www which we set in `-w /var/www` as working directory for angular application
- `node` is a name of docker image we will run and `/bin/bash` says run a linux console as a root

```posh
docker run -it -p 4200:4200 -e CHOKIDAR_USEPOLLING=true -v %cd%:/var/www -w "/var/www" node /bin/bash
```
3. We should see console in node image (linux + already installed node.js):
![Root console for docker node image](\img\rootconsole.png?raw=true "Set up docker")

4. Then inside consoel we need to run one by one

```bash
npm install
npm install -g @angular/cli
ng serve --host 0.0.0.0
```

5. And voila it's done manually. Now we can open localhost:4200 url in our browser and see if it's working.

6. Now change file `co-by-tu-wypic/src/app/app.component.html`, save changes and see if application is reloaded in your browser.

7. Cleanup: once you are done you can type `exit` into console to go out from docker and then `docker stop` + `docker rm`