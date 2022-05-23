docker buildx build --platform=linux/arm64/v8 -t terraform-aws-cli .
docker image tag terraform-aws-cli ashishjullia19/terraform-aws-cli:35.0
docker image push ashishjullia19/terraform-aws-cli:35.0