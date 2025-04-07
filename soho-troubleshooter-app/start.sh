#!/bin/bash

set -e

echo "🚀 Starting ElasticSearch, Backend, and Frontend..."

docker run -d --rm --name soho-es -p 9200:9200 -e "discovery.type=single-node" elasticsearch:8.11.1
sleep 20

curl -XPOST "http://localhost:9200/_bulk" -H "Content-Type: application/json" --data-binary @../elastic_bulk_errors.json

cd ../server
npm install
node elastic_backend.js &
cd ../client
npm install
npm run dev
