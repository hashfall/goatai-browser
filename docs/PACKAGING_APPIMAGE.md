# Goatai — AppImage (Linux)

O AppImage empacota o build `src/out/Default` num único arquivo executável.

## Gerar

```bash
./scripts/package-appimage.sh
```

Saída: `dist/Goatai-<versão>-x86_64.AppImage` (~275 MB com o build atual).

O script:

1. copia o binário `goatai`, todas as `.so` componentizadas (RUNPATH `$ORIGIN`),
   `.pak`, `icudtl.dat`, snapshots, `resources/`, `hyphen-data/` e locales
   (`en-US`, `pt-BR`, `es`);
2. copia `extensions/external_extensions.json` e a extensão `goatai_ai`;
3. faz `strip --strip-unneeded` **nas cópias** (os originais em `out/Default`
   não são alterados);
4. escreve `AppRun`, `.desktop` e o ícone;
5. baixa o `appimagetool` contínuo para `dist/.tools` (na primeira vez) e gera
   o AppImage com compressão zstd.

## Executar

```bash
./dist/Goatai-0.5.4-x86_64.AppImage
# se o sistema não tiver FUSE2:
APPIMAGE_EXTRACT_AND_RUN=1 ./dist/Goatai-0.5.4-x86_64.AppImage
```

- Perfil: `~/.config/goatai/profile` (ou `GOATAI_USER_DATA_DIR=/caminho`).
- A extensão Goatai IA é copiada para `~/.config/goatai/extensions/goatai_ai`
  (caminho fixo ⇒ ID estável ⇒ a chave salva continua valendo).
- O AppRun passa `--disable-setuid-sandbox` (usa o sandbox de namespaces).
  Se o sistema bloquear user namespaces, use `--no-sandbox`.

## Observações

- O build atual é **componentizado** (`is_component_build=true`), por isso o
  AppImage leva centenas de `.so`. Um build release não-componente geraria um
  AppImage bem menor, mas exige recompilar/linkar tudo.
- O AppImage não instala o navegador como padrão; para isso, use o
  `goatai.desktop` do projeto (`scripts/install-desktop.sh`).
