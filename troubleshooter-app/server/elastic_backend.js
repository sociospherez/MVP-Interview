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
