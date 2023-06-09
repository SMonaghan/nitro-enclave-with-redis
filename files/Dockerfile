# // Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# // SPDX-License-Identifier: MIT-0

ARG base_image_name
FROM $base_image_name

ARG server_port
ARG kms_key_id
ENV SERVER_PORT=$server_port
ENV KMS_KEY_ID=$kms_key_id
ENV AWS_DEFAULT_REGION=us-east-1

RUN amazon-linux-extras install epel -y
RUN yum install python3 iproute redis -y
ENV AWS_STS_REGIONAL_ENDPOINTS=regional
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/app

RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade redis==4.5.1 boto3 faker

WORKDIR /app

COPY server.py ./
COPY nitro_client.py ./
COPY traffic_forwarder.py ./
COPY run.sh ./

COPY redis.conf /usr/local/etc/redis/redis.conf

RUN chmod +x /app/run.sh

CMD /app/run.sh $SERVER_PORT
