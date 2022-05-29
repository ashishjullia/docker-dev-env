### To build your own image
```bash
git clone https://github.com/ashishjullia/docker-dev-awscli.git && cd ansible/single-liner
```
#### Create and ".env" file to pass the secrets
```bash
TF_VERSION=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
NAME_OF_CLUSTER=
```
```bash
docker build -t terraform-aws-cli .
```
```bash
docker image tag terraform-aws-cli ashishjullia19/terraform-aws-cli:1.0
```
###### Note: If you are pushing the image to a private dockerhub repository, make sure to run "docker login" first.
```bash
docker image push ashishjullia19/terraform-aws-cli:1.0
```
### Edit your "~/.bashrc" and place the following "aliases" at the bottom of the file

```bash
vim ~/.bashrc
```

```bash
alias dev="docker run -it --rm -v $PWD:/work -w /work --env-file=.env --entrypoint /new.sh ashishjullia19/terraform-aws-cli:5.0"
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
