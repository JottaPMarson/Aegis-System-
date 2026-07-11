# Aegis — guia de desenvolvimento deste repositório

Este repositório É o plugin Aegis. Se você chegou aqui pra usar o Aegis num projeto seu, instale via marketplace — este arquivo é pra quem desenvolve o próprio Aegis.

## Onde está o quê

- Comportamento real do orquestrador (carregado quando o Aegis é instalado como plugin): `skills/orchestrator/SKILL.md`
- Arquitetura completa e decisões já tomadas: `docs/architecture/AEGIS-ARCHITECTURE.md` — leia antes de adicionar ou mudar qualquer componente
- Roadmap de implementação, fase por fase: seção 12 do documento de arquitetura acima

## Regras pra trabalhar neste repo

- Siga o roadmap fase por fase, sem pular etapas
- Antes de qualquer commit, rode `claude plugin validate ./ --strict`
- Hooks novos: sempre testados isolados antes de registrar em `hooks/hooks.json`
- Toda skill precisa de frontmatter (`description` no mínimo)
- Mensagens de commit: `<tipo>: <resumo>` — sem Co-Authored-By nem referência ao Claude

## Como testar localmente sem publicar

```bash
claude --plugin-dir .
```

Roda o plugin diretamente da raiz do repo, sem precisar instalar via marketplace.
