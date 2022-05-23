docker build -t terraform-aws-cli .
docker image tag terraform-aws-cli ashishjullia19/terraform-aws-cli:1.0
docker image push ashishjullia19/terraform-aws-cli:1.0


docker run -it --rm -v ${PWD}:/work -w /work --env-file=.env --entrypoint /work/new.sh ashishjullia19/terraform-aws-cli:7.0