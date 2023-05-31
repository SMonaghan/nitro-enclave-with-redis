#! /bin/bash

nitro-cli run-enclave --cpu-count 2 --memory 2996 --eif-path ${nitro_lookup_dir}/${enclave_file}
