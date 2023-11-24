# Setup

Create the following function in your `~/.bashrc` and then either:
- logout and login
- `source ~/.bashrc` (I don't prefer this as sometimes it works sometimes it does not)

```bash
function dev() {
    local docker_cmd="sudo docker run -it --rm -v $PWD:/work -w /work"

    # Check for incorrect usage (more than one argument or invalid format)
    if [ "$#" -gt 1 ] || ( [ "$#" -eq 1 ] && ! [[ $1 =~ ^.+/+.+$ ]] ); then
        echo "Usage: dev [<project-name>/<stage>]"
        return 1
    fi

    # Append PORTUNUS_TOKEN if it's set and exactly one correctly formatted argument is provided
    if [ -n "$PORTUNUS_TOKEN" ] && [ "$#" -eq 1 ]; then
        docker_cmd+=" -e PORTUNUS_TOKEN=${PORTUNUS_TOKEN}/$1"
    fi

    docker_cmd+=" --entrypoint /script.sh ashishjullia19/docker-dev-env"
    eval $docker_cmd
}
```

## With portunus integration:

For `PORTUNUS_TOKEN` make sure to grab this from portunus ui `portunus.ashishjullia.com` and you'll get the token in format:
- `PORTUNUS_TOKEN=<TOKEN>/<PORTUNUS_TEAM>/<PORTUNUS_PROJECT>/<PORTUNUS_STAGE>`. Then `<PORTUNUS_TEAM>` will not be same as you'll see in ui, it will be a random value.
- by default, you can set the token on your host system under PORTUNUS_TOKEN until `<TOKEN>/<PORTUNUS_TEAM>`.

Notes:
- If you run it with just `dev` on terminal then nothing from `script.sh` will be installed/configured 
- the utilities specified in the `script.sh` will only work if portunus integration is used and correct key names are used on portunus side that matches to env variables specified in `script.sh`
- to run with portunus integration `dev <portunus-project>/<portunus-stage>`
- if more you specify something like `dev <portunus-project>/<portunus-stage> argument2` -> it will throw error

### Action
###### Run the following command in whichever directory you want the docker development environment.

```bash
dev
```
