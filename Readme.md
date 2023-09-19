### To build your own image
```bash
git clone https://github.com/ashishjullia/docker-dev-awscli.git && cd ansible/single-liner
```

### Note: This is only required if you are not using portunus
#### Create and ".env" file to pass the secrets
```bash
KEY=VALUE
.........so on
```
```bash
docker build -t terraform-aws-cli .
```
```bash
docker image tag terraform-aws-cli ashishjullia19/terraform-aws-cli
```
###### Note: If you are pushing the image to a private dockerhub repository, make sure to run "docker login" first.
```bash
docker image push ashishjullia19/terraform-aws-cli
```
### Edit your "~/.bashrc" and place the following "aliases" at the bottom of the file

```bash
vim ~/.bashrc
```

```bash
alias dev="docker run -it --rm -v $PWD:/work -w /work --env-file=.env --entrypoint /script.sh ashishjullia19/terraform-aws-cli"
```

With portunus integration:
For `PORTUNUS_TOKEN` make sure to grab this from portunus ui `portunus.ashishjullia.com` and you'll get the token in format:
`PORTUNUS_TOKEN=<TOKEN>/<PORTUNUS_TEAM>/<PORTUNUS_PROJECT>/<PORTUNUS_STAGE>`. Then `<PORTUNUS_TEAM>` will not be same as you'll see in ui, it will be a random value.
By default, you can set the token on your host system under PORTUNUS_TOKEN until `<TOKEN>/<PORTUNUS_TEAM>`, the other parts of the token can be populated inside the container via `.env` file to keep things more dynamic (as once created the `PORTUNUS_TEAM` value remains the same for a user until and unless they are part of other teams as well) OR you can also pass `<PORTUNUS_PROJECT>` `<PORTUNUS_STAGE>` via docker command itself just do `-e <PORTUNUS_PROJECT>=<PORTUNUS_PROJECT>` `-e <PORTUNUS_STAGE>=<PORTUNUS_PROJECT>` 
For `.env`, use this:
```bash
PORTUNUS_PROJECT=<value>
PORTUNUS_PROJECT=<value>
```
```bash
alias dev="docker run -it --rm -v $PWD:/work -w /work --env-file=.env -e PORTUNUS_TOKEN=$PORTUNUS_TOKEN --entrypoint /script.sh ashishjullia19/terraform-aws-cli"
```

```bash
alias dot="source ~/.bashrc"
```
### Action
###### Run the following commands series in whichever directory you want the docker development environment.

```bash
dot
```
```bash
dev
```
