# Use the following command to run the playbook
ansible-playbook playbook.yml -i hosts.ini -u pi -kK -vvv

# After that go to remote host and running the following command in order to spin container for aws-terraform-kubectl
# currently latest-tag == 
docker run -it --rm -v ${PWD}:/work -w /work --entrypoint /bin/bash <username>/terraform-aws-cli:<tag>