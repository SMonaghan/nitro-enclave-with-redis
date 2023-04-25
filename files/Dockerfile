# // Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# // SPDX-License-Identifier: MIT-0

FROM public.ecr.aws/docker/library/redis:7.0.10-alpine3.17

ARG server_port
ENV SERVER_PORT=$server_port

RUN apk add --update --no-cache iproute2
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade redis==4.5.1

WORKDIR /app

COPY server.py ./
COPY run.sh ./

COPY redis.conf /usr/local/etc/redis/redis.conf

RUN chmod +x /app/run.sh

CMD /app/run.sh $SERVER_PORT