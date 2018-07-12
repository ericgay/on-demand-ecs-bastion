# On Demand SSH Bastion for ECS

To use:

1. [optional] Update the Dockerfile to add your public key. You can skip this and just pass it in on the command line also.
2. Build and deploy to ECS.
3. Create a task named `bastion` that lives in a public subnet with port 22 allowed.
4. Obtain a short lived AWS token (aws-google-auth, etc.) then ./login.sh to spin up the task and login. Task will stop once you exit.

Todo:

- add Lambda to clean up any dangling taks
- add the current IP to the bastion security group on the fly and remove when done
