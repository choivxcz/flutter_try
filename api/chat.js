const { DEFAULT_CHAT_MODEL, proxyOpenRouter } = require('./_lib/openrouter');

module.exports = async function handler(request, response) {
  response.setHeader('Access-Control-Allow-Origin', '*');
  response.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  response.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (request.method === 'OPTIONS') {
    return response.status(204).end();
  }

  if (request.method !== 'POST') {
    return response.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const messages = Array.isArray(request.body?.messages) ? request.body.messages : [];
    const model = request.body?.model || DEFAULT_CHAT_MODEL;

    if (messages.length === 0) {
      return response.status(400).json({ error: 'messages must be a non-empty array' });
    }

    const filteredMessages = messages
      .filter((message, index) => {
        return message && typeof message.role === 'string' && typeof message.content !== 'undefined' && (message.role !== 'system' || index === 0);
      })
      .map((message) => ({
        role: message.role,
        content: message.content,
      }));

    const upstream = await proxyOpenRouter('/chat/completions', {
      model,
      messages: filteredMessages,
    });

    if (upstream.status !== 200) {
      return response.status(upstream.status).json({ error: upstream.body });
    }

    const content = upstream.body?.choices?.[0]?.message?.content;
    if (!content) {
      return response.status(502).json({ error: 'OpenRouter returned an empty response' });
    }

    return response.status(200).json({ content: String(content).trim() });
  } catch (error) {
    const statusCode = error.statusCode || 500;
    return response.status(statusCode).json({ error: error.message || 'Chat proxy failed' });
  }
};