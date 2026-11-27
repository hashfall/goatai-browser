# Regras do projeto Goatai

## Perfil do usuário (`.run/profile`)

O diretório `.run/profile` é o **perfil oficial** do usuário no Goatai e contém
histórico, abas, bookmarks, extensões e configurações reais.

- **Nunca apague, mova, renomeie, limpe ou sobrescreva** `.run/profile` (nem
  partes dele, como `Default/Preferences`, `Bookmarks`, `History`, `Extensions`
  ou `chrome.storage`).
- Não rode `rm -rf .run/profile`, nem restaure backups por cima do perfil sem
  pedido explícito do usuário.
- Para testes, use sempre um perfil temporário:
  - novo: `--user-data-dir=/tmp/opencode/<nome>`; ou
  - cópia: `cp -a .run/profile /tmp/opencode/<nome>` e use a cópia.
- Se um teste precisar do perfil real (ex.: conferir um visual), apenas abra e
  observe; não altere preferências nem conteúdo. Para qualquer teste que
  altere estado, use a cópia.
- `--load-extension` e flags de teste podem ser usados no perfil real sem
  problema, mas nunca com reset/limpeza do perfil.
