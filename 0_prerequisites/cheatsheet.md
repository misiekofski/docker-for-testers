## Docker cheatsheet
Those commands work propery on git bash or powershell. Do not use simple windows terminal.


Kill all containers: `docker stop $(docker ps -a -q)`
 
Remove all containers: `docker rm $(docker ps -a -q)`