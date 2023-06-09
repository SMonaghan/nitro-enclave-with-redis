#!/usr/bin/env python

import argparse
import http.server
import os
import enclave_client
import base64
import subprocess
import json
import nitro_client
import logging


logging.basicConfig(level=logging.INFO)

output = subprocess.check_output(['nitro-cli', 'describe-enclaves'])
enclaves = json.loads(output)

# Get the EnclaveCID of the first enclave
enclave_cid = enclaves[0]['EnclaveCID']

# Print the EnclaveCID
logging.debug(enclave_cid)

class HTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_PUT(self):
        path = self.translate_path(self.path)
        length = int(self.headers['Content-Length'])
        query = json.dumps({'set': nitro_client.prepare_server_request(self.rfile.read(length).decode())}).encode()
        logging.info(query)
        query64 = base64.b64encode(query)
        logging.debug(query64)
        args = argparse.Namespace(cid=enclave_cid, port=${enclave_port}, query=query64.decode())
        output = enclave_client.client_handler(args)
        self.send_response(201)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        message = output.encode()
        self.wfile.write(message)
    def do_GET(self):
        path = '/'.join(self.path.split('/')[1:])
        logging.info(path)
        query = json.dumps({'get': nitro_client.prepare_server_request(path)}).encode()
        logging.info(query)
        query64 = base64.b64encode(query)
        logging.debug(query64)
        args = argparse.Namespace(cid=enclave_cid, port=${enclave_port}, query=query64.decode())
        output = enclave_client.client_handler(args)
        logging.info("Output: {}".format(output))
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        message = output.encode()
        self.wfile.write(message)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--bind', '-b', default='localhost', metavar='ADDRESS',
                        help='Specify alternate bind address '
                             '[default: all interfaces]')
    parser.add_argument('port', action='store',
                        default=8000, type=int,
                        nargs='?',
                        help='Specify alternate port [default: 8000]')
    args = parser.parse_args()

    http.server.test(HandlerClass=HTTPRequestHandler, port=args.port, bind=args.bind)