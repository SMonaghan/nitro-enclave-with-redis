#! /bin/bash

nitro-cli run-enclave --cpu-count 2 --memory 3072 --eif-path ${nitro_lookup_dir}/${enclave_file} --debug-mode --attach-console
