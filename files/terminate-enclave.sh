#! /bin/bash

[ "$ENCLAVE_ID" != "null" ] && nitro-cli terminate-enclave --enclave-name ${enclave_name}
