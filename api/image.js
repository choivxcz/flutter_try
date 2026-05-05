const { DEFAULT_IMAGE_MODEL, proxyOpenRouter } = require('./_lib/openrouter');

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
    const prompt = typeof request.body?.prompt === 'string' ? request.body.prompt.trim() : '';
    const model = request.body?.model || DEFAULT_IMAGE_MODEL;

    if (!prompt) {
      return response.status(400).json({ error: 'prompt is required' });
    }

    const upstream = await proxyOpenRouter('/images/generations', {
      model,
      prompt,
      num_images: 1,
    });

    if (upstream.status !== 200) {
      return response.status(upstream.status).json({ error: upstream.body });
    }

    const url = upstream.body?.data?.[0]?.url;
    if (!url) {
      return response.status(502).json({ error: 'OpenRouter returned an empty image response' });
    }

    return response.status(200).json({ url });
  } catch (error) {
    const statusCode = error.statusCode || 500;
    return response.status(statusCode).json({ error: error.message || 'Image proxy failed' });
  }
};