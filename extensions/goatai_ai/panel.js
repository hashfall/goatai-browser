// Goatai IA — painel de chat com controle do navegador.
//
// Segurança:
//  - a chave fica em chrome.storage.local (no perfil, em disco);
//  - as requisições partem do processo da extensão, nunca da página visitada;
//  - nenhuma chave é gravada em log.

'use strict';

const DEFAULT_MODELS = {
  gpt: 'gpt-4.1-mini',
  gemini: 'gemini-2.5-flash',
  deepseek: 'deepseek-chat',
  claude: 'claude-sonnet-4-5',
};

const MAX_STEPS = 8;
const KEYS_STORAGE = 'goatai.keys';
const SETTINGS_STORAGE = 'goatai.settings';

const state = {
  provider: 'gpt',
  model: DEFAULT_MODELS.gpt,
  control: true,
  messages: [],
  busy: false,
};

const $ = (id) => document.getElementById(id);

// ---------------------------------------------------------------- utilidades

function escapeHtml(text) {
  return String(text)
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

function renderMarkdown(text) {
  const parts = String(text).split(/```/);
  return parts.map((part, index) => {
    if (index % 2 === 1) {
      return `<pre><code>${escapeHtml(part.replace(/^\w*\n/, ''))}</code></pre>`;
    }
    return escapeHtml(part)
        .replace(/`([^`]+)`/g, '<code>$1</code>')
        .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  }).join('');
}

function addMessage(role, text) {
  const el = document.createElement('div');
  el.className = `msg ${role}`;
  if (role === 'assistant') {
    el.innerHTML = renderMarkdown(text);
  } else {
    el.textContent = text;
  }
  $('messages').appendChild(el);
  $('messages').scrollTop = $('messages').scrollHeight;
  return el;
}

function setBusy(busy) {
  state.busy = busy;
  $('send').disabled = busy;
  $('status').hidden = !busy;
}

function setStatus(text) {
  $('status').textContent = text;
}

// ------------------------------------------------------------------ armazen

async function loadKeys() {
  const stored = await chrome.storage.local.get(KEYS_STORAGE);
  return stored[KEYS_STORAGE] || {};
}

async function getKey(provider) {
  const keys = await loadKeys();
  return keys[provider] || '';
}

async function saveKey(provider, key) {
  const keys = await loadKeys();
  keys[provider] = key;
  await chrome.storage.local.set({[KEYS_STORAGE]: keys});
}

async function removeKey(provider) {
  const keys = await loadKeys();
  delete keys[provider];
  await chrome.storage.local.set({[KEYS_STORAGE]: keys});
}

async function loadSettings() {
  const stored = await chrome.storage.local.get(SETTINGS_STORAGE);
  const settings = stored[SETTINGS_STORAGE] || {};
  state.provider = settings.provider || 'gpt';
  state.control = settings.control !== false;
  state.model = (settings.models || {})[state.provider] ||
      DEFAULT_MODELS[state.provider];
}

async function saveSettings() {
  const stored = await chrome.storage.local.get(SETTINGS_STORAGE);
  const settings = stored[SETTINGS_STORAGE] || {};
  settings.provider = state.provider;
  settings.control = state.control;
  settings.models = settings.models || {};
  settings.models[state.provider] = state.model;
  await chrome.storage.local.set({[SETTINGS_STORAGE]: settings});
}

// ------------------------------------------------------------------ provedor

function maskKey(key) {
  if (!key) return '';
  if (key.length <= 4) return '****';
  return `••••${key.slice(-4)}`;
}

async function refreshKeyState() {
  const key = await getKey(state.provider);
  $('keyState').textContent = key ?
      `Chave salva (disco): ${maskKey(key)}` :
      'Nenhuma chave salva.';
  $('settings').hidden = !!key;
}

function buildMessages(system) {
  return [{role: 'system', content: system}, ...state.messages];
}

function providerRequest(provider, system, model, key) {
  const messages = buildMessages(system);
  if (provider === 'claude') {
    return {
      url: 'https://api.anthropic.com/v1/messages',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': key,
        'anthropic-version': '2023-06-01',
      },
      body: {
        model,
        max_tokens: 2048,
        system,
        messages: messages.filter((m) => m.role !== 'system'),
      },
    };
  }
  if (provider === 'gemini') {
    return {
      url: `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': key,
      },
      body: {
        systemInstruction: {parts: [{text: system}]},
        contents: messages.filter((m) => m.role !== 'system').map((m) => ({
          role: m.role === 'assistant' ? 'model' : 'user',
          parts: [{text: m.content}],
        })),
        generationConfig: {maxOutputTokens: 2048},
      },
    };
  }
  // GPT e DeepSeek (API compatível).
  return {
    url: provider === 'deepseek' ?
        'https://api.deepseek.com/chat/completions' :
        'https://api.openai.com/v1/chat/completions',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${key}`,
    },
    body: {model, messages, temperature: 0.7},
  };
}

function providerText(provider, json) {
  if (provider === 'claude') {
    const blocks = json.content || [];
    return blocks.filter((b) => b.type === 'text').map((b) => b.text).join('');
  }
  if (provider === 'gemini') {
    const candidate = (json.candidates || [])[0];
    const parts = candidate?.content?.parts || [];
    return parts.map((p) => p.text || '').join('');
  }
  return json.choices?.[0]?.message?.content || '';
}

async function callModel(system) {
  const key = await getKey(state.provider);
  if (!key) throw new Error('Configure a chave de API do provedor.');

  setStatus(`Consultando ${state.provider}…`);
  const req = providerRequest(state.provider, system, state.model, key);
  const response = await fetch(req.url, {
    method: 'POST',
    headers: req.headers,
    body: JSON.stringify(req.body),
  });

  const text = await response.text();
  let json = null;
  try {
    json = JSON.parse(text);
  } catch (e) {
    json = null;
  }

  if (!response.ok) {
    const detail = json?.error?.message || text.slice(0, 300) ||
        `HTTP ${response.status}`;
    throw new Error(`Erro do provedor (HTTP ${response.status}): ${detail}`);
  }
  if (!json) throw new Error('Resposta do provedor não é JSON válido.');

  const reply = providerText(state.provider, json);
  if (!reply) throw new Error('O provedor não retornou texto.');
  return reply;
}

// ------------------------------------------------------------------ sistema

async function activeTab() {
  const [tab] = await chrome.tabs.query({active: true, lastFocusedWindow: true});
  return tab;
}

function systemPrompt() {
  let prompt =
      'Você é o Goatai IA, um assistente dentro do navegador Goatai. ' +
      'Responda em português do Brasil, de forma direta e útil. ' +
      'Nunca invente o resultado de uma ação; use as ações para ler a página. ';
  if (!state.control) {
    return prompt +
        'O controle do navegador está DESATIVADO. Apenas converse; não emita ações.';
  }
  prompt +=
      'Você pode controlar o navegador. Quando precisar agir, responda SOMENTE ' +
      'com um JSON válido, sem markdown: {"action":"nome","args":{...}}. ' +
      'Uma ação por resposta. Depois de cada ação você receberá ' +
      '"Resultado da ação: ...". Quando terminar, responda em texto normal. ' +
      'Ações disponíveis:\n' +
      '- open_tab {"url":"https://..."}\n' +
      '- list_tabs {}\n' +
      '- switch_tab {"index":0}\n' +
      '- close_tab {"index":0}\n' +
      '- navigate {"url":"https://..."} (aba ativa)\n' +
      '- back {}\n- forward {}\n- reload {}\n' +
      '- read_page {} (texto visível da aba ativa)\n' +
      '- click {"selector":"..."} ou {"text":"..."}\n' +
      '- type {"selector":"...","text":"...","submit":false}\n' +
      '- scroll {"direction":"down"} ou {"direction":"up"}\n' +
      'Apenas http/https. Não acesse arquivos locais nem páginas internas.';
  return prompt;
}

async function contextLine() {
  const tab = await activeTab();
  if (!tab) return '';
  return `\nContexto: aba ativa "${tab.title}" em ${tab.url}.`;
}

// ---------------------------------------------------------------- ferramentas

async function ensureHttp(url) {
  const parsed = new URL(url);
  if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
    throw new Error('apenas http/https');
  }
  return parsed.toString();
}

async function tabByIndex(index) {
  const tabs = await chrome.tabs.query({lastFocusedWindow: true});
  const tab = tabs[index];
  if (!tab) throw new Error('índice inválido');
  return tab;
}

async function executeAction(action, args = {}) {
  switch (action) {
    case 'open_tab': {
      const url = await ensureHttp(args.url || '');
      const tab = await chrome.tabs.create({url, active: true});
      return {ok: true, tabId: tab.id, url};
    }
    case 'list_tabs': {
      const tabs = await chrome.tabs.query({lastFocusedWindow: true});
      return {
        ok: true,
        tabs: tabs.map((t, i) => ({
          index: i, title: t.title, url: t.url, active: t.active,
        })),
      };
    }
    case 'switch_tab': {
      const tab = await tabByIndex(Number(args.index));
      await chrome.tabs.update(tab.id, {active: true});
      return {ok: true};
    }
    case 'close_tab': {
      const tab = await tabByIndex(Number(args.index));
      await chrome.tabs.remove(tab.id);
      return {ok: true};
    }
    case 'navigate': {
      const url = await ensureHttp(args.url || '');
      const tab = await activeTab();
      if (!tab) throw new Error('sem aba ativa');
      await chrome.tabs.update(tab.id, {url});
      return {ok: true, url};
    }
    case 'back': {
      const tab = await activeTab();
      await chrome.tabs.goBack(tab.id);
      return {ok: true};
    }
    case 'forward': {
      const tab = await activeTab();
      await chrome.tabs.goForward(tab.id);
      return {ok: true};
    }
    case 'reload': {
      const tab = await activeTab();
      await chrome.tabs.reload(tab.id);
      return {ok: true};
    }
    case 'read_page': {
      const tab = await activeTab();
      if (!tab) throw new Error('sem aba ativa');
      const [result] = await chrome.scripting.executeScript({
        target: {tabId: tab.id},
        func: () => ({
          ok: true,
          title: document.title,
          url: location.href,
          text: (document.body ? document.body.innerText : '').slice(0, 12000),
        }),
      });
      return result?.result || {ok: false, error: 'sem retorno'};
    }
    case 'click': {
      const tab = await activeTab();
      if (!tab) throw new Error('sem aba ativa');
      const [result] = await chrome.scripting.executeScript({
        target: {tabId: tab.id},
        args: [args.selector || '', args.text || ''],
        func: (selector, text) => {
          let el = null;
          if (selector) {
            try {
              el = document.querySelector(selector);
            } catch (e) {
              el = null;
            }
          }
          if (!el && text) {
            const needle = text.toLowerCase();
            const candidates = Array.from(document.querySelectorAll(
                'a,button,[role="button"],input[type="submit"],' +
                'input[type="button"]'));
            el = candidates.find((node) => {
              const label = (node.innerText || node.value ||
                  node.getAttribute('aria-label') || '').toLowerCase();
              return label.trim().includes(needle);
            });
          }
          if (!el) return {ok: false, error: 'elemento não encontrado'};
          el.scrollIntoView({block: 'center'});
          el.click();
          return {ok: true, info: (el.innerText || el.tagName || '').slice(0, 80)};
        },
      });
      return result?.result || {ok: false, error: 'sem retorno'};
    }
    case 'type': {
      const tab = await activeTab();
      if (!tab) throw new Error('sem aba ativa');
      const [result] = await chrome.scripting.executeScript({
        target: {tabId: tab.id},
        args: [args.selector || '', args.text || '', !!args.submit],
        func: (selector, value, submit) => {
          const el = document.querySelector(selector);
          if (!el) return {ok: false, error: 'campo não encontrado'};
          el.focus();
          if (el.isContentEditable) {
            el.textContent = value;
          } else {
            const proto = el instanceof HTMLTextAreaElement ?
                HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
            const setter = Object.getOwnPropertyDescriptor(proto, 'value').set;
            setter.call(el, value);
          }
          el.dispatchEvent(new Event('input', {bubbles: true}));
          el.dispatchEvent(new Event('change', {bubbles: true}));
          if (submit && el.form) el.form.requestSubmit();
          return {ok: true};
        },
      });
      return result?.result || {ok: false, error: 'sem retorno'};
    }
    case 'scroll': {
      const tab = await activeTab();
      if (!tab) throw new Error('sem aba ativa');
      const direction = args.direction === 'up' ? -1 : 1;
      const [result] = await chrome.scripting.executeScript({
        target: {tabId: tab.id},
        args: [direction],
        func: (dir) => {
          window.scrollBy(0, dir * window.innerHeight * 0.8);
          return {ok: true};
        },
      });
      return result?.result || {ok: true};
    }
    default:
      throw new Error(`ação desconhecida: ${action}`);
  }
}

function parseAction(text) {
  let candidate = text;
  const fence = candidate.indexOf('```');
  if (fence !== -1) {
    const end = candidate.indexOf('```', fence + 3);
    if (end !== -1) candidate = candidate.slice(fence + 3, end);
  }
  const start = candidate.indexOf('{');
  const end = candidate.lastIndexOf('}');
  if (start === -1 || end === -1 || end <= start) return null;
  try {
    const parsed = JSON.parse(candidate.slice(start, end + 1));
    if (typeof parsed.action !== 'string') return null;
    return parsed;
  } catch (e) {
    return null;
  }
}

// --------------------------------------------------------------------- chat

async function sendPrompt(text) {
  if (state.busy) return;
  const key = await getKey(state.provider);
  if (!key) {
    $('settings').hidden = false;
    addMessage('system', 'Configure a chave de API antes de conversar.');
    return;
  }

  addMessage('user', text);
  $('input').value = '';
  setBusy(true);
  state.messages.push({role: 'user', content: text});

  try {
    for (let step = 0; step < MAX_STEPS; step++) {
      const system = systemPrompt() + await contextLine();
      const reply = await callModel(system);
      const action = parseAction(reply);

      if (action && state.control) {
        addMessage('action', `▶ ${action.action}`);
        let result;
        try {
          result = await executeAction(action.action, action.args || {});
        } catch (e) {
          result = {ok: false, error: String(e)};
        }
        state.messages.push({role: 'assistant', content: reply});
        state.messages.push({
          role: 'user',
          content: `Resultado da ação: ${JSON.stringify(result)}`,
        });
        continue;
      }

      addMessage('assistant', reply);
      state.messages.push({role: 'assistant', content: reply});
      setBusy(false);
      return;
    }
    addMessage('system', 'Limite de ações atingido nesta rodada.');
  } catch (error) {
    addMessage('system', error instanceof Error ? error.message : String(error));
  } finally {
    setBusy(false);
  }
}

// ----------------------------------------------------------------------- UI

function init() {
  $('settingsToggle').addEventListener('click', () => {
    $('settings').hidden = !$('settings').hidden;
  });

  $('provider').addEventListener('change', async () => {
    state.provider = $('provider').value;
    state.model = DEFAULT_MODELS[state.provider];
    $('model').value = state.model;
    await saveSettings();
    await refreshKeyState();
  });

  $('model').addEventListener('change', async () => {
    state.model = $('model').value.trim() || DEFAULT_MODELS[state.provider];
    $('model').value = state.model;
    await saveSettings();
  });

  $('control').addEventListener('change', async () => {
    state.control = $('control').checked;
    await saveSettings();
  });

  $('saveKey').addEventListener('click', async () => {
    const key = $('apiKey').value.trim();
    if (!key) return;
    await saveKey(state.provider, key);
    $('apiKey').value = '';
    await refreshKeyState();
  });

  $('apiKey').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      $('saveKey').click();
    }
  });

  $('clearKey').addEventListener('click', async () => {
    await removeKey(state.provider);
    await refreshKeyState();
  });

  $('send').addEventListener('click', () => {
    const text = $('input').value.trim();
    if (text) sendPrompt(text);
  });

  $('input').addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      const text = $('input').value.trim();
      if (text) sendPrompt(text);
    }
  });

  loadSettings().then(async () => {
    $('provider').value = state.provider;
    $('model').value = state.model;
    $('control').checked = state.control;
    await refreshKeyState();
  });
}

document.addEventListener('DOMContentLoaded', init);
