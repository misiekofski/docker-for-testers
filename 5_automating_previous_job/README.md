## Now we are gonna automate previous lesson

1. Create from node image another image which will have preinstalled `@angular/cli`

2. Run container based on newly built container from step 1 and run `npm install` + `ng serve`
- don't forget to mount volume to current folder which is `%cd%` in command line and `$PWD` in Powershell / Bash
- remember to stop and remove previous container because it uses port `4200`
- use Dockerfile