const express = require('express');
const { analyzeInput } = require('./nlpService');
const app = express();
const port = 3000;

app.use(express.json());

// 示例路由
app.get('/', (req, res) => {
    res.send('MeowMate AI服务');
});

app.post('/analyze', (req, res) => {
    const userInput = req.body.input;
    const analysisResult = analyzeInput(userInput);
    res.json({ analysis: analysisResult });
});

app.listen(port, () => {
    console.log(`服务器正在运行在 http://localhost:${port}`);
}); 