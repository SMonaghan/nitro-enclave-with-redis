#! /bin/bash

sudo mkdir /var/lib/docker
sudo mkdir ${nitro_lookup_dir}
sudo mkfs.xfs ${volume_mount}
sudo mount ${volume_mount} /var/lib/docker
sudo /usr/bin/lsblk
sudo /usr/bin/df -h
sudo su -c "echo \"$(blkid ${volume_mount} |cut -d ' ' -f 2-2|tr -d '"')  /var/lib/docker  xfs  defaults  0  2\" >> /etc/fstab";
sudo cat /etc/fstab
sudo yum install aws-nitro-enclaves-cli aws-nitro-enclaves-cli-devel git httpd mod_ssl aws-nitro-enclaves-acm nginx httpd mod_ssl -y
#sudo mv /etc/nitro_enclaves/acm.example.yaml /etc/nitro_enclaves/acm.yaml
#sudo sed -i 's|certificate_arn: ""|certificate_arn: "${certificate_arn}"|g' /etc/nitro_enclaves/acm.yaml
#sudo sed -i 's|pid /run/nginx.pid;|pid /run/nginx.pid;\n\nssl_engine pkcs11;|g' /etc/nginx/nginx.conf
#sudo sed -i '39,55 s/^/#/' /etc/nginx/nginx.conf
#sudo sed -i '58,82 s/#//' /etc/nginx/nginx.conf
#sudo sed -i 's/server_name  _;/server_name  ${enclave_instance_domain};/' /etc/nginx/nginx.conf
#sudo sed -i '57,81 s|ssl_certificate "/etc/pki/nginx/server.crt";||' /etc/nginx/nginx.conf
#sudo sed -i '57,80 s|ssl_certificate_key "/etc/pki/nginx/private/server.key";||' /etc/nginx/nginx.conf
#sudo sed -i '57,79 s|ssl_ciphers PROFILE=SYSTEM;|ssl_protocols TLSv1.2;|' /etc/nginx/nginx.conf
#sudo sed -i 's/listen       \[::\]:443 ssl http2;//g' /etc/nginx/nginx.conf
#sudo sed -i 's|ssl_prefer_server_ciphers on;|ssl_prefer_server_ciphers on;\n\t#Set this to the stanza path configured in /etc/nitro_enclaves/acm.yaml\n\tinclude "/etc/pki/nginx/nginx-acm.conf";|' /etc/nginx/nginx.conf
sudo usermod -aG ne ec2-user
sudo usermod -aG docker ec2-user
sudo echo "---
# Enclave configuration file.
#
# How much memory to allocate for enclaves (in MiB).
memory_mib: 8192
#
# How many CPUs to reserve for enclaves.
cpu_count: 6" > /etc/nitro_enclaves/allocator.yaml
sudo mv /etc/nitro_enclaves/acm-httpd.example.yaml /etc/nitro_enclaves/acm.yaml
sudo sed -i 's|certificate_arn: ""|certificate_arn: "${certificate_arn}"|g' /etc/nitro_enclaves/acm.yaml
sudo mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/httpd-acm.conf
sudo grep -qxF 'ServerName ${enclave_instance_domain}' /etc/httpd/conf.d/httpd-acm.conf || sudo sed -i "s/^#ServerName .*/ServerName ${enclave_instance_domain}/g" /etc/httpd/conf.d/httpd-acm.conf
sudo grep -qxF 'ProxyPreserveHost On' /etc/httpd/conf.d/httpd-acm.conf || sudo sed -i '/^ServerName ${enclave_instance_domain}/a ProxyPreserveHost On' /etc/httpd/conf.d/httpd-acm.conf
sudo grep -qxF 'ProxyRequests Off' /etc/httpd/conf.d/httpd-acm.conf || sudo sed -i '/^ProxyPreserveHost On/a ProxyRequests Off' /etc/httpd/conf.d/httpd-acm.conf
sudo grep -qxF 'ProxyPass / http://localhost:${local_port}/' /etc/httpd/conf.d/httpd-acm.conf || sudo sed -i '\|^ProxyRequests Off|a ProxyPass / http://localhost:${local_port}/' /etc/httpd/conf.d/httpd-acm.conf
sudo grep -qxF 'ProxyPassReverse / http://localhost:${local_port}/' /etc/httpd/conf.d/httpd-acm.conf || sudo sed -i '\|^ProxyPass / http://localhost:${local_port}/|a ProxyPassReverse / http://localhost:${local_port}/' /etc/httpd/conf.d/httpd-acm.conf

sudo echo "#<VirtualHost *:80>
#  ServerName ${enclave_instance_domain}
#  Redirect Permanent / ${enclave_instance_domain}
#</VirtualHost>
" >> /etc/httpd/conf.d/httpd-acm.conf
sudo systemctl start nitro-enclaves-allocator.service && sudo systemctl enable nitro-enclaves-allocator.service
sudo systemctl start docker && sudo systemctl enable docker
sudo aws s3 cp s3://${s3_bucket}/${s3_prefix}/ ${nitro_lookup_dir} --recursive
sudo cp ${nitro_lookup_dir}/start*.sh /bin/
sudo cp ${nitro_lookup_dir}/terminate-enclave.sh /bin/terminate-enclave.sh
sudo cp ${nitro_lookup_dir}/nitro-lookup.sh /bin/nitro-lookup.sh
sudo chmod 0755 /bin/nitro-lookup.sh
sudo chmod 0755 /bin/terminate-enclave.sh
sudo chmod 0755 /bin/start-enclave*.sh
sudo cp ${nitro_lookup_dir}/nitro-lookup.service /etc/systemd/system/nitro-lookup.service
sudo cp ${nitro_lookup_dir}/lookup-server.service /etc/systemd/system/lookup-server.service
sudo systemctl start nitro-lookup.service && sudo systemctl enable nitro-lookup.service
sleep 10
sudo systemctl start lookup-server.service && sudo systemctl enable lookup-server.service
sudo systemctl start nitro-enclaves-acm.service && sudo systemctl enable nitro-enclaves-acm

#sudo shutdown -r now
