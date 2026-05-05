const express = require('express');
const cors = require('cors');
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');

const app = express();

app.use(cors({ origin: true }));
app.use(express.json({ limit: '1mb' }));

const OPENROUTER_ENDPOINT = 'https://openrouter.ai/api/v1';
const DEFAULT_CHAT_MODEL = 'nvidia/nemotron-3-nano-30b-a3b:free';
const DEFAULT_IMAGE_MODEL = 'blackforestlabs/flux-1.0-schnell:free';
const OPENROUTER_API_KEY = defineSecret('OPENROUTER_API_KEY');

function getOpenRouterKey() {
  return OPENROUTER_API_KEY.value() || process.env.OPENROUTER_API_KEY || '';
}

function requireOpenRouterKey() {
  const apiKey = getOpenRouterKey();
  if (!apiKey) {
    const error = new Error(
      'Missing OPENROUTER_API_KEY. Set it with firebase functions:secrets:set OPENROUTER_API_KEY'
    );
    error.statusCode = 500;
    throw error;
  }

  return apiKey;
}

async function proxyOpenRouter(path, body) {
  const response = await fetch(`${OPENROUTER_ENDPOINT}${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${requireOpenRouterKey()}`,
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
    // Keep the raw response text when it is not JSON.
  }

  return {
    status: response.status,
    body: responseBody,
  };
}

app.get('/health', (_request, response) => {
  response.json({ ok: true });
});

app.post('/chat', async (request, response) => {
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

    return response.json({ content: String(content).trim() });
  } catch (error) {
    const statusCode = error.statusCode || 500;
    return response.status(statusCode).json({ error: error.message || 'Chat proxy failed' });
  }
});

app.post('/image', async (request, response) => {
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

    return response.json({ url });
  } catch (error) {
    const statusCode = error.statusCode || 500;
    return response.status(statusCode).json({ error: error.message || 'Image proxy failed' });
  }
});

exports.api = onRequest({ secrets: [OPENROUTER_API_KEY] }, app);