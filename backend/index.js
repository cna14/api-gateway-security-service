const express = require('express');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());

app.get('/public', (req, res) => {
  res.json({ message: 'This is a public endpoint' });
});

app.get('/secure', (req, res) => {
  const auth = req.headers.authorization;
  if (!auth) return res.status(401).json({ error: 'Missing token' });
  const token = auth.split(' ')[1];
  try {
    const decoded = jwt.decode(token);
    res.json({ message: 'Token valid', user: decoded });
  } catch (e) {
    res.status(403).json({ error: 'Invalid token' });
  }
});

app.listen(3000, () => console.log('Backend running on port 3000'));
