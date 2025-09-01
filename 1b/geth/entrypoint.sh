#!/bin/sh
set -e

# geth 이미지의 기본 ENTRYPOINT를 덮어쓰고 직접 geth 실행
exec /usr/local/bin/geth --dev \
  --http --http.addr 0.0.0.0 --http.port 8545 \
  --http.api eth,net,web3,personal,txpool \
  --http.corsdomain="*" \
  --http.vhosts="*" \
  --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api eth,net,web3 \
  --allow-insecure-unlock