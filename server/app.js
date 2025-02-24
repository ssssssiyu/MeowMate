const express = require('express');
const app = express();
const port = 3000;

// 示例路由
app.get('/', (req, res) => {
  res.send('Hello, MeowMate!');
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});