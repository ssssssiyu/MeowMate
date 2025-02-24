const natural = require('natural');
const tokenizer = new natural.WordTokenizer();

function analyzeInput(input) {
    const tokens = tokenizer.tokenize(input);
    // 这里可以添加更多的分析逻辑
    return tokens;
}

module.exports = { analyzeInput }; 