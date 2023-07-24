### To build your own image
```bash
git clone https://github.com/ashishjullia/docker-dev-awscli.git && cd ansible/single-liner
```
#### Create and ".env" file to pass the secrets
```bash
TF_VERSION=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=
NAME_OF_CLUSTER=

# Extra Utilities (Will be installed, only if populated)
FLUX_VERSION=
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
