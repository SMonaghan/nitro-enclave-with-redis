#! /bin/bash

docker build ${nitro_lookup_dir} -t secure-channel-example
nitro-cli build-enclave --docker-uri secure-channel-example:latest --output-file secure-channel-example.eif
nitro-cli run-enclave --cpu-count 2 --memory 2096 --eif-path secure-channel-example.eif
