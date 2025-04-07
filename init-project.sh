#!/bin/bash

echo "📁 Creating project folders..."
mkdir -p soho-troubleshooter-app/client/src
mkdir -p soho-troubleshooter-app/server

echo "📄 Creating and populating files..."

cat <<EOF > soho-troubleshooter-app/client/src/TroubleshootingDashboard.jsx
// React TroubleshootingDashboard starter component
export default function TroubleshootingDashboard() {
  return <div className=\"p-6\">Hello from Dashboard!</div>;
}
EOF

cat <<EOF > soho-troubleshooter-app/server/elastic_backend.js
// ElasticSearch Express backend
import express from 'express';
import { Client } from '@elastic/elasticsearch';
import cors from 'cors';

const app = express();
const port = 3001;

app.use(cors());

const esClient = new Client({ node: 'http://localhost:9200' });

app.get('/api/search', async (req, res) => {
  const { q = '', module = '', severity = '', category = '' } = req.query;
  const must = [];
  if (q) must.push({ multi_match: { query: q, fields: ['ErrorMessage', 'QuickFix', 'RootCause'], fuzziness: 'AUTO' }});
  if (module) must.push({ match: { Module: module }});
  if (severity) must.push({ match: { Severity: severity }});
  if (category) must.push({ match: { Category: category }});

  const result = await esClient.search({
    index: 'error-log-index',
    body: { query: { bool: { must } } }
  });

  res.json(result.hits.hits.map(hit => hit._source));
});

app.listen(port, () => console.log(`Elastic API running on port ${port}`));
EOF

cat <<EOF > soho-troubleshooter-app/errors.csv
ErrorID,ErrorMessage,Module,Category,Frequency,Severity,QuickFix,RootCause,EscalationTeam
504,API Timeout,Integration,MostOccurred,132,High,Restart Logic App,Delay in Logic App,Integration Team
PDR-01,Posting Date Not Within Range,Finance,MostOccurred,121,Medium,Update GL Setup,Incorrect Posting Range,Finance Lead
WH-12,Warehouse Activity Pending,Warehouse,MostOccurred,98,Medium,Complete Tasks,Open Warehouse Docs,Ops Manager
DIM-09,Dimension Mismatch,Finance,LeastOccurred,12,High,Correct Dimensions,Wrong Code Mapping,Finance Lead
FX-17,Currency Conversion Failure,Sales,LeastOccurred,9,High,Recheck FX Rates,Missing Rate Setup,Finance Team
PAF-02,Power Automate Flow Failed,Automation,LeastOccurred,7,Medium,Review Flow History,Trigger Misfire,Automation Support
EOF

cat <<EOF > soho-troubleshooter-app/elastic_bulk_errors.json
{"index":{"_index":"error-log-index"}}
{"ErrorID":"504","ErrorMessage":"API Timeout","Module":"Integration","Category":"MostOccurred","Frequency":132,"Severity":"High","QuickFix":"Restart Logic App","RootCause":"Delay in Logic App","EscalationTeam":"Integration Team"}
{"index":{"_index":"error-log-index"}}
{"ErrorID":"PDR-01","ErrorMessage":"Posting Date Not Within Range","Module":"Finance","Category":"MostOccurred","Frequency":121,"Severity":"Medium","QuickFix":"Update GL Setup","RootCause":"Incorrect Posting Range","EscalationTeam":"Finance Lead"}
EOF

cat <<EOF > soho-troubleshooter-app/start.sh
#!/bin/bash

echo "🚀 Starting ElasticSearch, Backend, and Frontend..."

docker run -d --name soho-es -p 9200:9200 -e "discovery.type=single-node" elasticsearch:8.11.1
sleep 20

curl -XPOST "http://localhost:9200/_bulk" -H "Content-Type: application/json" --data-binary @elastic_bulk_errors.json

cd server
npm install
node elastic_backend.js &
cd ../client
npm install
npm run dev
EOF

cat <<EOF > soho-troubleshooter-app/README.md
# Soho Troubleshooter App

A self-serve error diagnostics tool powered by CSV/Fuse.js or ElasticSearch, built with React + Vite.

## Quick Start

1. Clone the repo or run `init-project.sh`
2. Run `chmod +x start.sh && ./start.sh`
3. App launches at [localhost:5173](http://localhost:5173)
EOF

cat <<EOF > soho-troubleshooter-app/.gitignore
# Ignore node_modules and build artifacts
client/node_modules/
server/node_modules/
client/dist/
.env
.DS_Store
*.log
npm-debug.log*
EOF

echo "✅ Project scaffold fully created and populated in ./soho-troubleshooter-app"
