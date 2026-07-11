# Aegis — Plano de Correção e Continuação (Imediato + Médio Prazo)

> Este documento cobre só os itens **imediatos** e de **médio prazo** do plano que o Claude Code sugeriu. Os itens de **longo prazo** (frameworks por linguagem, milestone v0.2.0) ficam de fora de propósito — entram num `.md` separado depois da sua pesquisa.

Auditoria feita direto contra o repositório real (`github.com/JottaPMarson/Aegis-System-`, branch `main`) e contra a documentação oficial de plugins do Claude Code (`code.claude.com/docs/en/plugins-reference`), não só contra a autoavaliação do Claude Code.

---

## 0. Correções ao diagnóstico original — leia antes de executar

O plano que o Claude Code te deu acertou a maior parte, mas **dois pontos do item 1 estão descrevendo como "inválido" algo que a documentação oficial trata como válido**. Corrigido abaixo pra não desfazer o que já está certo.

### ✅ Confirmado: `CLAUDE.md` → precisa virar skill
Isso está certo e é bem fundamentado. A documentação oficial diz literalmente:
> "A CLAUDE.md file at the plugin root is not loaded as project context. Plugins contribute context through skills, agents, and hooks rather than CLAUDE.md. To ship instructions that load into Claude's context, put them in a skill."

Ou seja: o `CLAUDE.md` da raiz (conferido no repo — existe e tem a metodologia certa) **nunca é carregado** quando o Aegis é instalado como plugin via `/plugin install`. Precisa mesmo virar `skills/orchestrator/SKILL.md`.

### ⚠️ Duvidoso: "remover `agents`/`commands`/`skills` como arrays do `plugin.json`"
Conferido no repo, o `plugin.json` atual tem:
```json
"commands": ["./commands/"],
"agents": ["./agents/"],
"skills": ["./skills/"],
```
A documentação oficial mostra explicitamente arrays como formato válido pra esses campos (exemplo direto da doc: `"agents": ["./agents", "./specialized-agents"]`). O problema real aqui, se houver algum, não é o tipo array — é que esses caminhos já são os **defaults auto-descobertos**, então declará-los explicitamente é **redundante, não inválido** (a doc confirma: campos de path só existem pra quando seu layout foge do padrão). Rodar `claude plugin validate --strict` localmente antes de mexer nisso, pra ver se ele realmente reclama de algo ou se é seguro só remover os três campos (deixando auto-discovery cuidar disso) sem que isso seja "consertar um erro" de fato.

### ⚠️ Provavelmente errado: "ajustar `hooks` por estar como string de caminho"
Conferido no repo: `"hooks": "./hooks/hooks.json"`. A documentação oficial mostra literalmente esse mesmo formato como exemplo válido: `"hooks": "./config/hooks.json"`. **Isso não deveria precisar de correção.** Se `claude plugin validate` reclamar de algo relacionado a hooks, o problema provavelmente está dentro do `hooks/hooks.json` (conferido também — usa `PreToolUse` + matcher `Bash` + dois scripts Python via `${CLAUDE_PLUGIN_ROOT}`, que bate com o padrão documentado) ou em algo mais específico, não no tipo do campo no manifest.

**Ação prática pro item 1, revisada:** rode `claude plugin validate ./aegis --strict` primeiro e leia a saída real, em vez de assumir os três problemas como estão descritos. Corrija só o que o validador de fato apontar. Isso evita reescrever coisa que já está certa.

### ✅ Confirmado: `SKILL.md` sem frontmatter
Conferido em `skills/brainstorming/SKILL.md` — começa direto com `# Skill: Brainstorming`, sem bloco YAML de frontmatter. A documentação mostra o padrão esperado com `description` (e opcionalmente `when_to_use`, `allowed-tools`) no frontmatter. Isso é real e precisa ser corrigido nos 9 skills.

### ✅ Confirmado: `scripts/doctor.ps1` não existe
Testado direto — `raw.githubusercontent.com/.../scripts/doctor.ps1` retorna 404. `install.ps1` chama um script que não existe.

### ✅ Confirmado: `rules/infra/` vazio
Só tem `.gitkeep`, nenhum `.md` de conteúdo (`docker.md` testado, 404).

### ✅ Confirmado: nenhum workflow de CI existe ainda
`.github/workflows/` sem `validate.yml`, `ci.yml` ou `plugin-validate.yml` — item 3 é mesmo trabalho novo, não retrabalho.

---

## 1. Ordem de execução revisada

A ordem sugerida pelo Claude Code (1→3→2→4→5→6) já tinha uma boa correção (2 antes de 3, pra não montar CI sobre um `doctor.ps1` quebrado). Mantendo essa lógica, só reordenando o item 1 pra depender do validador real:

1. **Rodar `claude plugin validate ./aegis --strict`** e registrar a saída completa — essa é a fonte de verdade, não a suposição de quais campos estão errados.
2. **Corrigir só o que o validador apontar** no `plugin.json`/`hooks.json` (provavelmente nada nos dois pontos marcados ⚠️ acima — mas confirme antes de mexer).
3. **Converter `CLAUDE.md` → `skills/orchestrator/SKILL.md`**, com frontmatter (`description` cobrindo quando essa skill deve carregar — no caso, sempre, é o orquestrador). O conteúdo metodológico que já está no `CLAUDE.md` atual (brainstorm → spec → plano → execução, disciplina de delegação) migra quase copiado pra essa skill — só ganha o frontmatter.

   **O `CLAUDE.md` da raiz não fica vazio — muda de função.** Importante não confundir escopos:

   | Onde | Escopo | Quando carrega |
   |---|---|---|
   | `~/.claude/CLAUDE.md` (fora de qualquer repo) | Global, pessoal | Sempre, em qualquer projeto seu |
   | `CLAUDE.md` na raiz do repo do Aegis | Local a este repositório | Só quando alguém abre a pasta do Aegis pra desenvolver o plugin em si |
   | `skills/orchestrator/SKILL.md` | Vai junto com o plugin | Em qualquer projeto de quem instalar o Aegis |

   Depois da migração, o `CLAUDE.md` da raiz vira um guia **pra quem desenvolve o Aegis**, não pra quem usa o Aegis instalado. Conteúdo sugerido:

   ```markdown
   # Aegis — guia de desenvolvimento deste repositório

   Este repositório É o plugin Aegis. Se você chegou aqui pra usar o Aegis
   num projeto seu, instale via marketplace — este arquivo é pra quem
   desenvolve o próprio Aegis.

   ## Onde está o quê
   - Comportamento real do orquestrador (o que é carregado quando o Aegis
     é instalado como plugin): `skills/orchestrator/SKILL.md`
   - Arquitetura completa e decisões já tomadas: `docs/architecture/AEGIS-ARCHITECTURE.md`
     — leia antes de adicionar/mudar qualquer componente
   - Roadmap de implementação, fase por fase: seção 12 do documento acima

   ## Regras pra trabalhar neste repo
   - Siga o roadmap fase por fase, sem pular etapas
   - Antes de qualquer commit, rode `claude plugin validate ./ --strict`
   - Hooks novos: sempre testados isolados antes de registrar em hooks.json
   - Toda skill precisa de frontmatter (description no mínimo)

   ## Como testar localmente sem publicar
   `claude --plugin-dir .` na raiz do repo carrega o plugin local pra teste,
   sem precisar instalar via marketplace.
   ```
4. **Adicionar frontmatter (`description`, e `when_to_use` onde fizer sentido) nos 9 `SKILL.md`** existentes.
5. **Criar `scripts/doctor.ps1`**, espelhando exatamente o que `doctor.sh` já verifica (plugin ativo, `rules/` no lugar certo, hooks registrados, status dos MCPs recomendados).
6. **Criar o workflow de CI** (`.github/workflows/plugin-validate.yml`): roda `claude plugin validate --strict` e `hooks/test_phase1.sh` em todo PR, bloqueia merge se falhar.
7. **Fase 2 de hooks de segurança** (a que ficou como "planned" em `dangerous-patterns.md`): `git clean -fd`, `git branch -D` em branch protegida, `terraform destroy`, `kubectl delete namespace`, `DROP TABLE`/`DROP DATABASE`/`TRUNCATE`, `chmod -R 777`, detecção de secrets em commit (`git add .env`, padrões de API key) — mesmo comportamento já validado na Fase 1: bloquear por padrão, pedir confirmação explícita.
8. **Publicar no marketplace** (`claude plugin marketplace add` + submissão pro `anthropics/claude-plugins-official`) — só depois dos itens 1–3 confirmados, já que são bloqueadores reais de marketplace.
9. **Preencher `rules/infra/`** com conteúdo real pra Docker, Kubernetes e Terraform (convenções, não só estrutura vazia) — este é o único item de "médio prazo" que sobra depois do marketplace; pode rodar em paralelo com o item 8.

---

## 2. Critério de aceite por item (pra saber quando está pronto)

| Item | Pronto quando... |
|---|---|
| 1–2 (validate) | `claude plugin validate ./aegis --strict` roda sem erros nem warnings |
| 3 (CLAUDE.md→skill) | Plugin instalado via `/plugin install` carrega a metodologia do orquestrador automaticamente, sem depender de abrir o repo direto; **e** o `CLAUDE.md` da raiz foi reescrito como guia de desenvolvimento local (não ficou vazio nem duplicado com a skill) |
| 4 (frontmatter) | Os 9 `SKILL.md` têm bloco YAML com `description` no topo |
| 5 (doctor.ps1) | `install.ps1` roda até o fim no Windows sem erro de script ausente |
| 6 (CI) | Um PR de teste com erro proposital de validação é bloqueado automaticamente |
| 7 (hooks fase 2) | Cada padrão perigoso novo tem teste isolado (mesmo padrão da Fase 1: bloquear + pedir confirmação, nunca allow automático nem deny silencioso) |
| 8 (marketplace) | Plugin instalável por outra pessoa via `claude plugin marketplace add` sem erro |
| 9 (rules/infra) | Pelo menos `docker.md`, `kubernetes.md` e `terraform.md` com convenções reais, não só `.gitkeep` |

---

## 3. Fora de escopo deste documento (fica pro próximo `.md`)

- Item 7 original do Claude Code (rules de frameworks — `react.md`, `angular.md`, `fastapi.md`, etc.) — depende da sua pesquisa.
- Item 8 original do Claude Code (milestone v0.2.0) — natural só depois que os itens 1–9 acima estiverem fechados.
