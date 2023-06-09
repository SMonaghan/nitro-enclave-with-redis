# nitro-enclave-with-redis

## Names:
- Kim Diaz
- Carol Holloway
- Richard Dorsey
- Willie Harris
- Susan Rodriguez
- Jennifer Jones
- Hannah Powell
- Rebecca Alvarado
- Linda Murray
- Rebecca Edwards
- Suzanne Bryant
- Curtis Jones
- Lisa Ray
- Jason Delgado
- Megan Reid
- Dustin Chavez
- Rebecca Edwards
- Lisa Reynolds
- Krista Parsons
- Maria Allison
- William Rice
- Patricia Williams
- Noah Gibson PhD
- Katherine Goodwin
- Heather Grant
- Dawn Jones
- Anthony Jackson
- Cheryl Cisneros
- Sherry Spencer
- Larry Ibarra
- Jessica Figueroa
- Mark Reed
- Harold Rhodes
- Michelle Lee
- Mr. Juan Moore
- Sarah Long
- Phillip Weber
- Christopher Harrison
- Erica Johnson
- Margaret Parker
- Kimberly Norman
- Courtney Torres
- James Fields
- Robert Farmer
- Robert Miller
- Grace Skinner
- Joseph Wheeler
- Charles Trevino
- Jamie Fowler
- David Williams
- Christy Nichols
- Lauren Garcia
- Tiffany Wagner
- Maria Davidson
- Alan Hernandez DVM
- Marie Gilbert
- Nancy Smith
- Carla Walton
- Michelle Lloyd
- Robert Nunez
- Allison Simmons
- Ashley Jackson
- Susan Mccoy
- Brooke Gonzalez
- Joshua Barr
- Danielle Rocha
- Darren French
- Juan Kennedy
- Benjamin Charles
- Heather Carpenter
- Timothy Shelton
- Amy Pierce
- Matthew Sanders
- Justin Mitchell
- Adriana York
- Jacob Saunders
- Peter Brown
- Amy Gill
- Lisa Sanders
- Jonathan Leonard
- Benjamin Lopez
- Margaret Mueller
- Daniel Morrison
- Danny Lopez
- Tyler Mills
- Ashley Glass
- Anthony Mckinney
- Ronald Nguyen DDS
- Erin Hale
- Joshua Terry
- Michael Sanders
- James Baird
- Lucas Hamilton
- Willie Harper
- Kristina Huber
- William Nunez
- Nichole Johnson
- Darren Oliver
- Dakota Morrow

## Example Commands

```
journalctl -u nitro-lookup.service  | cut -d " " -f 6- | less
curl -XGET "https://lookup.example.com/$(aws kms encrypt --plaintext $(echo -n 'Kim Diaz'|base64) --key-id alias/nitro-enclave --query 'CiphertextBlob' --output text)" -H 'Content-Type: text/plain'
curl -XPUT 'https://lookup.example.com' -d $(aws kms encrypt --plaintext $(echo -n '{"Kim Diaz":"value"}'|base64) --key-id alias/nitro-enclave --query 'CiphertextBlob'|tr -d '"') -H 'Content-Type: text/plain'
journalctl -u nitro-lookup.service -f
sudo sed -i 's|ExecStart=/bin/start-enclave-in-debug-mode.sh|ExecStart=/bin/start-enclave.sh|g' /etc/systemd/system/nitro-lookup.service
systemctl daemon-reload
systemctl restart nitro-lookup.service
journalctl -u nitro-lookup.service -f
systemctl restart lookup-server.service
curl -XGET "https://lookup.example.com/$(aws kms encrypt --plaintext $(echo -n 'Kim Diaz'|base64) --key-id alias/nitro-enclave --query 'CiphertextBlob' --output text)" -H 'Content-Type: text/plain'
curl -XGET "https://lookup.example.com/$(aws kms encrypt --plaintext $(echo -n 'Kim Diazd'|base64) --key-id alias/nitro-enclave --query 'CiphertextBlob' --output text)" -H 'Content-Type: text/plain'
curl -XPUT 'https://lookup.example.com' -d $(aws kms encrypt --plaintext $(echo -n '{"Kim Diazd":"value"}'|base64) --key-id alias/nitro-enclave --query 'CiphertextBlob'|tr -d '"') -H 'Content-Type: text/plain'
curl -XGET "https://lookup.example.com/$(aws kms encrypt --plaintext $(echo -n 'Kim Diazd'|base64) --key-id alias/nitro-enclave --query 'CiphertextBlob' --output text)" -H 'Content-Type: text/plain'
journalctl -u nitro-lookup.service -f
```