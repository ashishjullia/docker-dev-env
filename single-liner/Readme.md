docker build -t terraform-aws-cli .
docker image tag terraform-aws-cli ashishjullia19/terraform-aws-cli:1.0
docker image push ashishjullia19/terraform-aws-cli:1.0


 docker run -it --rm -v ${PWD}:/work -w /work --env-file=.env --entrypoint /new.sh ashishjullia19/terraform-aws-cli:5.0

### Create a .env file with the following
TF_VERSION=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
NAME_OF_CLUSTER=