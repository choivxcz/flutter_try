const OPENROUTER_ENDPOINT = 'https://openrouter.ai/api/v1';
const DEFAULT_CHAT_MODEL = 'nvidia/nemotron-3-nano-30b-a3b:free';
const DEFAULT_IMAGE_MODEL = 'blackforestlabs/flux-1.0-schnell:free';

function getApiKey() {
  return process.env.OPENROUTER_API_KEY || '';
}

function requireApiKey() {
  const apiKey = getApiKey();
  if (!apiKey) {
    const error = new Error('Missing OPENROUTER_API_KEY. Set it in Vercel project environment variables.');
    error.statusCode = 500;
    throw error;
  }

  return apiKey;
}

async function proxyOpenRouter(path, body) {
  const response = await fetch(`${OPENROUTER_ENDPOINT}${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${requireApiKey()}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://localhost',
      'X-Title': 'Choi AI App',
    },
    body: JSON.stringify(body),
  });

  const responseText = await response.text();
  let responseBody = responseText;

  try {
    responseBody = JSON.parse(responseText);
  } catch (_) {
    // Keep raw response text when OpenRouter doesn't return JSON.
  }

  return {
    status: response.status,
    body: responseBody,
  };
}

module.exports = {
  DEFAULT_CHAT_MODEL,
  DEFAULT_IMAGE_MODEL,
  proxyOpenRouter,
};