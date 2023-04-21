#! /bin/bash

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${account_id}.dkr.ecr.us-east-1.amazonaws.com
docker build ${nitro_lookup_dir} -t secure-channel-example
nitro-cli build-enclave --docker-uri secure-channel-example:latest --output-file secure-channel-example.eif
nitro-cli run-enclave --cpu-count 2 --memory 2096 --eif-path secure-channel-example.eif
