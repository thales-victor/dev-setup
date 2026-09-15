# Dev SETUP

Ambiente Docker para usar Node.js, npm e Codex CLI sem instalar essas ferramentas diretamente no Windows.

## Requisitos

- Docker Desktop instalado e funcionando
- `C:\Workfolder` contendo seus projetos

## Criar e iniciar

No PowerShell, dentro desta pasta:

```powershell
docker compose build
docker compose up -d
```

Entrar no container:

```powershell
docker compose exec codex bash
```

Dentro do container:

```bash
node --version
npm --version
codex --version
```

## Usar um projeto

Exemplo:

```bash
cd /workspace/MeuProjeto
codex
```

Os arquivos alterados dentro de `/workspace` são alterados diretamente em:

```text
C:\Workfolder
```

## Autenticação do Codex

Este ambiente utiliza a OpenAI API através da variável:

OPENAI_API_KEY

A chave fica armazenada localmente no arquivo `.env`,
que não deve ser versionado.

Para verificar se a chave está disponível:

```bash
test -n "$OPENAI_API_KEY" && echo "API key configurada" || echo "API key NÃO configurada"

A configuração do Codex fica em um volume Docker chamado `codex_home`, para não ser perdida quando o container for recriado.

## Parar o ambiente

```powershell
docker compose down
```

Isso remove o container, mas mantém o volume `codex_home`.

Para apagar também a configuração persistida do Codex:

```powershell
docker compose down -v
```

## Trocar a pasta de trabalho

Por padrão:

```text
C:\Workfolder -> /workspace
```

Para usar outra pasta no PowerShell:

```powershell
$env:WORKSPACE_PATH="C:/OutraPasta"
docker compose up -d --build
```
