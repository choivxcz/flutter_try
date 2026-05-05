module.exports = async function handler(_request, response) {
  response.setHeader('Access-Control-Allow-Origin', '*');
  response.setHeader('Content-Type', 'application/json');
  return response.status(200).json({
    ok: true,
    message: 'OpenRouter proxy is running. Use /api/chat and /api/image.',
  });
};