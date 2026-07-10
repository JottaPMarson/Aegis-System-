# AEGIS — Sistema de Sub-Agents, Hooks e Skills para Claude Code

> **Nome do plugin:** `aegis` (Adaptive Engineering & Governance Intelligence System) — decisão fechada.

**Status:** documento de arquitetura / planejamento (nenhum arquivo de código foi criado ainda — a implementação será feita depois, dentro do Claude Code, no repositório real do plugin).

---

## 1. Objetivo

Criar um plugin de Claude Code **novo e independente**, inspirado na filosofia do [`obra/superpowers`](https://github.com/obra/superpowers) (skills-first, metodologia de desenvolvimento, brainstorm → plan → execute, TDD), mas que resolve a principal limitação identificada: **os sub-agents do superpowers são genéricos**. Aegis substitui isso por um **time de sub-agents especializados por disciplina** (engenharia por stack, segurança, QA, arquitetura, infraestrutura), com:

1. Um **agente principal (orquestrador)** que herda o *comportamento* do superpowers (metodologia, disciplina, forma de conduzir o trabalho) — mas delega a execução técnica para sub-agents especialistas.
2. **Sub-agents especializados**, cada um com seu próprio prompt, skills, ferramentas permitidas e (quando fizer sentido) MCPs dedicados.
3. **Hooks de segurança** que interceptam ações perigosas (`git push`, `rm -rf`, `git reset --hard`, alterações em produção, etc.) e **bloqueiam por padrão, exigindo confirmação explícita do usuário** para liberar.
4. **Commands** (`/`) para acionar fluxos específicos (plan, security-review, architecture, deploy-check, etc.), inspirados no superpowers e no ECC.
5. **Integração com MCPs externos** já usados (Serena, Lumen) e planejados (Graphify, drawio-mcp-server), cada um atribuído ao(s) sub-agent(s) que faz sentido usá-lo.

---

## 2. Referências analisadas (o que cada uma contribui)

| Projeto | O que é | O que aproveitamos para o Aegis |
|---|---|---|
| [`obra/superpowers`](https://github.com/obra/superpowers) | Framework de skills + metodologia (brainstorm → spec → plano em chunks → execução com TDD e subagent-driven-development). Comandos `/brainstorm`, `/write-plan`, `/execute-plan`. Hook de `SessionStart` que injeta contexto. | A **metodologia do agente principal**: nunca parte direto para o código, sempre extrai spec → plano revisável → execução disciplinada. Vamos manter esse "cérebro" do orquestrador, mas trocar a forma como ele delega trabalho técnico. |
| [`affaan-m/ECC`](https://github.com/affaan-m/ECC) | 67 agents especializados, 278 skills, `rules/` por linguagem (typescript, python, golang, php...), hooks reutilizáveis, dashboard visual. | O **modelo de organização**: `agents/` com um `.md` por especialista, `rules/<linguagem>/` com convenções de código por stack, hooks como componente de primeira classe (não um extra). Vamos usar essa estrutura de pastas como base, mas com escopo mais enxuto e curado (não 67 agents genéricos — um conjunto pequeno e realmente especializado nas stacks que você usa). |
| [`oraios/serena`](https://github.com/oraios/serena) | MCP de retrieval/edição semântica de código **ao vivo** via LSP (símbolos, referências, renomeações cross-file). Não constrói índice persistente — cada chamada consulta o language server na hora. Guarda só "memórias" de onboarding (`.serena/memories/`, notas sobre a estrutura do projeto). | Ferramenta de **execução precisa** para os sub-agents de Engenharia e Database: é quem efetivamente lê/edita o código depois que Graphify/Lumen já indicaram onde ir (§7.1). |
| [`ory/lumen`](https://github.com/ory/lumen) | MCP de busca semântica local (embeddings locais via Ollama/LM Studio + SQLite-vec, indexado em disco). Expõe `semantic_search` como ferramenta **preferencial**, mas — diferente do Graphify — não bloqueia `Grep`/`Read` via hook; a disciplina de usá-lo primeiro depende do prompt/skill. | Ferramenta de **descoberta por significado** ("onde está o código que faz X") — útil para todo mundo, mas principalmente Engenharia e QA (§7.1). |
| [`Graphify-Labs/graphify`](https://github.com/Graphify-Labs/graphify) | Constrói um **grafo de conhecimento** (mapa estrutural, não o código-fonte) via AST + análise semântica; consultável (`graph_search`/`query`, `graph_impact`, `graph_path`, `graph_explain`, comunidades, hotspots). No Claude Code, instala um hook `PreToolUse` próprio que intercepta busca e `Read`/`Glob` **antes** de rodarem, empurrando o agente pro grafo — esse bloqueio já vem de graça da própria ferramenta, não depende só de prompt. | Ferramenta de **análise de impacto e arquitetura**: perfeito para o sub-agent Arquiteto ("se eu mudar este módulo, o que mais quebra?"), Segurança (mapear superfícies de ataque/dependências) e Database (quem acessa quais tabelas). É sempre a primeira parada pra pergunta sobre estrutura/relação (§7.1). |
| [drawio-mcp-server](https://www.drawio.com/docs/manual/generate/drawio-mcp-server/) | MCP para gerar/editar diagramas `.drawio` programaticamente. | Ferramenta do sub-agent Arquiteto para **produzir diagramas de arquitetura** (C4, sequência, infraestrutura) como artefato real, não só texto. |

> A ordem de uso entre Serena, Lumen e Graphify (o que consultar primeiro, o que cada um efetivamente devolve, e por que nenhum dos três dispensa leitura de arquivo real na hora de editar) está formalizada como skill em §7.1 — vale ler antes de implementar qualquer sub-agent de engenharia.

---

## 3. Visão geral da arquitetura

```
                         ┌─────────────────────────────┐
                         │      CLAUDE.md (raiz)        │
                         │  orquestrador — metodologia  │
                         │  skills base (genéricas)     │
                         └───────────────┬──────────────┘
                                         │ delega via Task tool
   ┌────────────┬────────────┬───────────┼───────────┬────────────┬────────────┐
   ▼            ▼            ▼           ▼           ▼            ▼
┌────────┐ ┌──────────┐ ┌─────────┐ ┌────────┐ ┌──────────┐ ┌──────────┐
│ARQUITE-│ │ENGENHARIA│ │SEGURANÇA│ │   QA   │ │  INFRA/  │ │ DATABASE │
│  TO    │ │(por ling.)│ │(OWASP) │ │        │ │  DEVOPS  │ │ / CACHE  │
└───┬────┘ └────┬─────┘ └────┬────┘ └───┬────┘ └────┬─────┘ └────┬─────┘
    │           │            │          │           │            │
 drawio-mcp   serena       graphify   serena     (aws/k8s     (postgres/
 graphify     lumen      graphify(audit) lumen     docs)     dynamodb/redis)
                        web_search(OWASP)

                    ┌───────────────────────────────┐
                    │        HOOKS DE SEGURANÇA      │
                    │  intercepta TODO PreToolUse     │
                    │  bloqueia + pede confirmação    │
                    └───────────────────────────────┘
```

O agente principal **nunca escreve código de produção diretamente** quando existe um especialista aplicável — ele planeja, quebra em tarefas e despacha via `Task` para o sub-agent certo, revisando o resultado. Isso é a evolução direta do padrão `subagent-driven-development` do superpowers, só que com destino especializado em vez de um subagent genérico.

---

## 4. Estrutura de diretórios do plugin

```
aegis/
├── .claude-plugin/
│   ├── plugin.json                 # metadados do plugin
│   └── marketplace.json            # se for distribuir via marketplace próprio
│
├── agents/                         # sub-agents especializados (definição .md com front-matter)
│   ├── architect.md                # Arquiteto de Software
│   ├── security-reviewer.md        # Segurança (OWASP)
│   ├── qa-engineer.md              # QA / testes
│   ├── infra-engineer.md           # Infra/DevOps (AWS, K8s, Docker)
│   ├── code-reviewer.md            # Revisão de qualidade geral (cross-stack)
│   ├── database-engineer.md        # Banco de dados & cache (ex.: Postgres, DynamoDB, Redis — extensível)
│   │
│   ├── lang-js-ts.md      # Engenharia — JavaScript & TypeScript (Node, React, Angular etc. via rules/frameworks)
│   ├── lang-python.md              # Engenharia — Python (Django/FastAPI/Flask via rules/frameworks)
│   ├── lang-csharp.md              # Engenharia — C# (.NET/ASP.NET Core via rules/frameworks)
│   ├── lang-cpp.md                 # Engenharia — C++
│   ├── lang-php.md                 # Engenharia — PHP (Laravel/Symfony via rules/frameworks)
│   ├── lang-go.md                  # Engenharia — Go
│   ├── lang-kotlin.md              # Engenharia — Kotlin (Android/multiplatform via rules/frameworks)
│   ├── lang-swift.md               # Engenharia — Swift (iOS/macOS via rules/frameworks)
│   ├── lang-java.md                # Engenharia — Java (Spring/JVM via rules/frameworks)
│   ├── lang-rust.md                # Engenharia — Rust
│   ├── lang-ruby.md                # Engenharia — Ruby (Rails via rules/frameworks)
│   ├── lang-dart.md                # Engenharia — Dart (Flutter via rules/frameworks)
│   │
│   └── docs-writer.md              # Documentação técnica (README/CHANGELOG/ADRs)
│
├── skills/                         # skills GENÉRICAS (comportamento do agente principal)
│   ├── brainstorming/SKILL.md
│   ├── writing-plans/SKILL.md
│   ├── executing-plans/SKILL.md
│   ├── test-driven-development/SKILL.md
│   ├── subagent-delegation/SKILL.md      # como e quando delegar para cada especialista
│   ├── codebase-navigation/SKILL.md      # ordem de uso Graphify → Lumen → Serena → Read (§7.1)
│   ├── debugging/SKILL.md
│   ├── git-workflow/SKILL.md
│   └── requesting-code-review/SKILL.md
│
├── rules/                          # convenções técnicas por LINGUAGEM (referenciadas pelos sub-agents)
│   ├── common/
│   ├── js-ts/
│   │   ├── base.md                 # regras de JS e TS JUNTAS num arquivo só (poucas diferenças reais entre os dois)
│   │   └── frameworks/             # 1 arquivo por framework que você realmente usa (React, Angular, Nest...)
│   │       ├── react.md
│   │       ├── angular.md
│   │       └── nestjs.md           # (exemplo — só criar se você usar)
│   ├── python/
│   │   ├── base.md
│   │   └── frameworks/             # django.md, fastapi.md, flask.md — conforme uso real
│   ├── csharp/
│   │   ├── base.md
│   │   └── frameworks/             # aspnet-core.md, etc.
│   ├── cpp/
│   ├── php/
│   │   ├── base.md
│   │   └── frameworks/             # laravel.md, symfony.md
│   ├── go/
│   ├── kotlin/
│   │   ├── base.md
│   │   └── frameworks/             # android.md, ktor.md, kmp.md
│   ├── swift/
│   │   ├── base.md
│   │   └── frameworks/             # swiftui.md, uikit.md
│   ├── java/
│   │   ├── base.md
│   │   └── frameworks/             # spring-boot.md
│   ├── rust/
│   ├── ruby/
│   │   ├── base.md
│   │   └── frameworks/             # rails.md
│   ├── dart/
│   │   ├── base.md
│   │   └── frameworks/             # flutter.md
│   ├── database/                   # ex.: postgresql.md, dynamodb.md, redis-cache.md — adicione outros conforme o uso
│   ├── security/                   # owasp-top10-2025.md, dangerous-patterns.md, production-scope.md
│   └── infra/                      # padrões de IaC, k8s, docker
│
├── commands/                       # slash commands
│   ├── architect.md                # /aegis:architect
│   ├── security-review.md          # /aegis:security-review
│   ├── qa-review.md                # /aegis:qa-review
│   ├── db-review.md                # /aegis:db-review
│   ├── infra-review.md             # /aegis:infra-review
│   ├── code-review.md              # /aegis:code-review
│   ├── deploy-check.md             # /aegis:deploy-check
│   └── diagram.md                  # /aegis:diagram (usa drawio-mcp)
│
├── hooks/
│   ├── hooks.json                  # registro dos hooks (matchers de eventos)
│   ├── guard-dangerous-bash.sh     # PreToolUse(Bash) — bloqueia comandos perigosos
│   ├── guard-file-deletion.sh      # PreToolUse(Bash|Write) — protege deleção em massa
│   ├── guard-git-push.sh           # PreToolUse(Bash) — bloqueia push/force-push
│   ├── require-confirmation.py     # utilitário compartilhado de "pedir confirmação"
│   └── session-start-context.sh    # injeta contexto do projeto no início da sessão
│
├── mcp-config/
│   └── recommended-mcp.json        # exemplo de configuração dos MCPs recomendados (serena, lumen, graphify, drawio)
│
├── scripts/                        # instalação e desinstalação de um comando só (ver §9.5)
│   ├── install.sh                  # Linux/macOS
│   ├── install.ps1                 # Windows (PowerShell)
│   ├── uninstall.sh                # Linux/macOS
│   ├── uninstall.ps1               # Windows (PowerShell)
│   └── doctor.sh                   # verificação de saúde pós-instalação (plugin + MCPs recomendados)
│
├── docs/
│   └── architecture/                # ADRs e diagramas gerados pelo sub-agent Arquiteto (fonte viva)
│
├── README.md                       # raiz — GitHub/Claude Code esperam encontrar aqui
├── CHANGELOG.md                    # raiz
├── SETUP.md                        # raiz
├── CONTRIBUTING.md                 # raiz
└── CLAUDE.md                       # instruções do agente principal (metodologia + regras de delegação)
```

---

## 5. Agente principal (orquestrador) — é o `CLAUDE.md`, não é opcional

**Decisão fechada:** o orquestrador **é o `CLAUDE.md` na raiz do plugin**, não um sub-agent à parte em `agents/`. Não existe `agents/orchestrator.md` — o `CLAUDE.md` é lido automaticamente pelo Claude Code no início de toda sessão, então é o lugar certo pra metodologia que precisa estar sempre ativa, sem depender de delegação via `Task` (que é como os outros sub-agents são acionados).

**Responsabilidade:** metodologia, não execução técnica.

Herdado do superpowers:
- Nunca parte direto para código: brainstorm → spec curta e revisável → plano em blocos pequenos → execução.
- TDD como padrão de trabalho.
- Disciplina de git (commits pequenos, mensagens claras).

Adicionado pelo Aegis:
- **Skill de delegação (`subagent-delegation`)**: mapa de decisão de "qual sub-agent chamar" baseado no tipo de tarefa e na stack **detectada automaticamente pela leitura do arquivo marcador correspondente** no repositório (decisão confirmada — detalhamento em §6.7).
- Toda tarefa técnica não trivial é despachada via `Task` para o especialista certo; o orquestrador revisa o output antes de prosseguir (2 estágios: conformidade com o plano, depois qualidade — igual ao `subagent-driven-development` do superpowers, só que aplicado por especialista).
- Se nenhum especialista cobre a stack, o orquestrador executa diretamente mas registra isso como "gap" (ver §10 Roadmap — é sinal de que falta criar um novo sub-agent).

---

## 6. Sub-agents especializados

Cada sub-agent é um arquivo `agents/<nome>.md` com front-matter definindo `description` (usado pelo orquestrador para decidir quando delegar), `tools` permitidas, e o prompt do especialista. Abaixo, o escopo de cada um:

### 6.1 Arquiteto (`architect.md`)
- Decisões de design de sistema, trade-offs, ADRs (Architecture Decision Records).
- Usa **Graphify** para entender impacto/blast radius antes de propor mudanças estruturais (é a primeira ferramenta a consultar, conforme §7.1).
- Usa **drawio-mcp-server** para gerar diagramas C4 (contexto, container, componente) e diagramas de sequência.
- Produz artefatos em `docs/architecture/` (ADRs + diagramas).

### 6.2 Segurança (`security-reviewer.md`)
- Checklist baseado no **OWASP Top 10:2025** (confirmado em [owasp.org/Top10/2025](https://owasp.org/Top10/2025/0x00_2025-Introduction/) — mudou bastante da versão 2021, duas categorias novas e uma consolidação):
  1. **A01 — Broken Access Control** (SSRF foi incorporado aqui em 2025, não é mais categoria separada)
  2. **A02 — Security Misconfiguration**
  3. **A03 — Software Supply Chain Failures** (expansão do antigo "Vulnerable and Outdated Components", agora cobre build systems e infraestrutura de distribuição)
  4. **A04 — Cryptographic Failures**
  5. **A05 — Injection**
  6. **A06 — Insecure Design**
  7. **A07 — Authentication Failures**
  8. **A08 — Software or Data Integrity Failures**
  9. **A09 — Security Logging & Alerting Failures**
  10. **A10 — Mishandling of Exceptional Conditions** *(categoria nova em 2025 — tratamento de erro, falhas lógicas, fail-open)*
- Registrado em `rules/security/owasp-top10-2025.md`, com o link oficial acima como fonte — revisar periodicamente, já que o OWASP pode publicar atualizações menores após o release inicial.
- Revisão complementar via OWASP ASVS onde aplicável (controles mais granulares que o Top 10 não cobre em detalhe).
- Usa **Graphify** para mapear superfícies de ataque (quem chama quem, quais módulos tocam dados sensíveis) — segue a mesma ordem de consulta descrita em §7.1.
- Usa `web_search` para confirmar CVEs recentes de dependências quando necessário (a A03 depende de dados vivos, não só do texto do Top 10).
- **É o mesmo sub-agent que valida os hooks de segurança periodicamente** — audita se as regras dos hooks (§8) ainda cobrem os riscos atuais do projeto.

### 6.3 QA (`qa-engineer.md`)
- Estratégia de testes (pirâmide: unitário/integração/E2E), cobertura, casos de borda.
- Gera planos de teste a partir da spec, não só depois do código pronto.
- Usa **Lumen** pra localizar testes existentes por significado e **Serena** pra ler/confirmar o que já está coberto, nessa ordem (§7.1) — evita duplicar cobertura.

### 6.4 Infra/DevOps (`infra-engineer.md`)
- AWS (IAM, ECS/EKS, Lambda, RDS, S3, VPC), Kubernetes, Docker, CI/CD, Terraform/CloudFormation.
- Revisão de Dockerfiles, manifests k8s, pipelines — com foco em segurança de infraestrutura (least privilege, secrets fora do código, imagens mínimas).
- Trabalha em conjunto com Segurança para revisão de infra (hand-off explícito no plano).

### 6.5 Code Reviewer (`code-reviewer.md`)
- Revisão de qualidade cross-stack (legibilidade, duplicação, complexidade, aderência às `rules/` da stack).
- É o "segundo par de olhos" antes de qualquer commit relevante — reforça o padrão de dois estágios do superpowers (compliance de spec + qualidade).

### 6.6 Engenharia por linguagem (frameworks ficam *dentro* do agent)

Um sub-agent por linguagem — **12 no total** (JavaScript e TypeScript ficam no mesmo agent e nas mesmas `rules/`, já que TS é um superset de JS: mesmo runtime, mesma toolchain, poucas regras realmente divergem — ver §6.6.1). Framework não gera um novo agent; é uma camada de conhecimento à parte, que o próprio agent consulta.

| Sub-agent | Linguagem(ns) | Frameworks cobertos via `rules/<lang>/frameworks/` (exemplos — você define os reais) |
|---|---|---|
| `lang-js-ts.md` | JavaScript **e** TypeScript | React, Angular, Node puro, Express, Nest, Fastify |
| `lang-python.md` | Python | Django, FastAPI, Flask |
| `lang-csharp.md` | C# | ASP.NET Core, EF Core |
| `lang-cpp.md` | C++ | (build systems específicos, se houver) |
| `lang-php.md` | PHP | Laravel, Symfony |
| `lang-go.md` | Go | (gin/echo/fiber, se houver) |
| `lang-kotlin.md` | Kotlin | Android nativo, Kotlin Multiplatform, Ktor |
| `lang-swift.md` | Swift | SwiftUI, UIKit |
| `lang-java.md` | Java | Spring / Spring Boot |
| `lang-rust.md` | Rust | (axum/actix, se houver) |
| `lang-ruby.md` | Ruby | Rails |
| `lang-dart.md` | Dart | Flutter |

Cada um segue a ordem de navegação descrita em §7.1: **Lumen** pra achar por significado (cobre as linguagens listadas via chunking com AST/tree-sitter) e **Serena** pra ler/editar de fato por símbolo (cobre todas via LSP) — nessa ordem, não em paralelo.

#### 6.6.1 Como JS/TS e framework entram no agent

1. O agent (`lang-js-ts.md`) sempre lê `rules/js-ts/base.md` — **um único arquivo com as regras de JavaScript e TypeScript juntas**, já que a diferença real entre os dois é pequena (tipagem estática, `interface`/`type`, `strict mode`). Não existe um arquivo TS separado nem carga condicional: o que muda entre JS puro e TS fica anotado dentro do próprio `base.md`, e o agent aplica a parte que se encaixa no arquivo que está editando.
2. Ele também tenta ler `rules/js-ts/frameworks/<framework-detectado>.md`, quando existir — detectado por sinal secundário (ex.: dependência `@angular/core` no `package.json` → lê `angular.md`; dependência `react` → lê `react.md`, funciona com ou sem TS).
3. **Frameworks que você não usa simplesmente não têm arquivo lido** — o agent não perde tempo/contexto com eles. Adicionar um framework novo é criar um `.md` a mais em `rules/js-ts/frameworks/`, sem tocar no agent nem em nenhum outro lugar.
4. Isso significa que você não precisa listar frameworks agora, no documento — quando for implementar de fato, é só ir criando os arquivos conforme for usando cada um (ou me passar a lista quando quiser que eu monte os arquivos).

> Essa lista cobre as linguagens que você indicou como mais prováveis (JS, TS, Python, C#, C++, PHP, Go, Kotlin, Swift, Java, Rust, Ruby, Dart). Se surgir uma nova no futuro (ex.: Elixir, Scala), o processo é o mesmo: um novo `agents/lang-<x>.md` + `rules/<x>/` + uma linha na tabela de detecção do §6.7 — sem reescrever nada do resto do sistema.

### 6.7 Detecção automática de linguagem (arquivo marcador)

**Decisão confirmada:** o orquestrador detecta a **linguagem** sozinho, lendo o **arquivo marcador correspondente** na raiz (ou subpasta relevante) do repositório — sem precisar que você indique manualmente qual sub-agent chamar. O framework é um sinal **secundário**, lido pelo próprio agent depois de acionado (§6.6.1), não muda qual agent é chamado.

Mecanismo:
1. No início da sessão (ou antes de delegar uma tarefa técnica), a skill `subagent-delegation` consulta uma tabela de mapeamento **arquivo marcador → agent de linguagem**.
2. O orquestrador faz um `Glob`/`Read` desses marcadores (rápido, não lê o projeto inteiro) e decide o(s) agent(s) aplicável(is) — um monorepo pode ter mais de um marcador (ex.: `frontend/tsconfig.json` + `backend/*.csproj`), e nesse caso mais de um especialista entra em cena para a mesma feature.
3. Se nenhum marcador bater, o orquestrador avisa que não há especialista para aquela linguagem (gap registrado — ver §12 Roadmap) e executa diretamente, de forma mais genérica.

| Arquivo marcador | Agent acionado |
|---|---|
| `package.json` (com ou sem `tsconfig.json` no mesmo escopo) | `lang-js-ts` — JS e TS são o mesmo agent e as mesmas `rules/js-ts/base.md` (§6.6.1); `tsconfig.json` não muda qual agent é chamado |
| `requirements.txt`, `pyproject.toml`, `Pipfile`, `manage.py` (Django) | `lang-python` |
| `*.csproj` / `*.sln` | `lang-csharp` |
| `CMakeLists.txt`, `*.vcxproj`, `Makefile` com fontes `.cpp`/`.hpp` | `lang-cpp` |
| `composer.json` | `lang-php` |
| `go.mod` | `lang-go` |
| `build.gradle.kts`/`build.gradle` com plugin Kotlin, `*.kt` predominante | `lang-kotlin` |
| `Package.swift`, `*.xcodeproj`, `*.xcworkspace` | `lang-swift` |
| `pom.xml` / `build.gradle` (Java puro, sem plugin Kotlin) | `lang-java` |
| `Cargo.toml` | `lang-rust` |
| `Gemfile` | `lang-ruby` |
| `pubspec.yaml` | `lang-dart` |
| `Dockerfile`, `docker-compose.yml`, `*.tf`, manifests `k8s/*.yaml` | `infra-engineer` (em paralelo, não substitui o agent da linguagem da aplicação) |

Essa tabela vive em `rules/common/stack-detection.md` (fonte única, editável) — adicionar uma linguagem nova é só adicionar uma linha ali, sem tocar em código. Em monorepos, cada subpasta é checada de forma independente (ex.: `apps/mobile/pubspec.yaml` → `lang-dart`, `apps/api/go.mod` → `lang-go`, na mesma feature).

### 6.8 Documentação (`docs-writer.md`)
- Mantém `README.md`, `CHANGELOG.md` (Keep a Changelog + SemVer), ADRs e docs de API sincronizados com o código.
- Acionado automaticamente ao final de features relevantes, como parte do pipeline padrão do `CLAUDE.md` (§5) — não depende de um comando específico.

### 6.9 Banco de Dados / Cache (`database-engineer.md`)

Cobre banco de dados e cache de forma geral — **PostgreSQL, DynamoDB e Redis são só os exemplos mais prováveis pelo que você usa hoje**, não uma lista fechada. O agent é pensado por *paradigma* (relacional, NoSQL de item/documento, cache, grafo, busca, etc.), então cobrir um banco novo (MySQL, MongoDB, SQLite, Cassandra, Elasticsearch, Neo4j...) é só adicionar um `.md` novo em `rules/database/`, sem mudar o agent. Mesmo quando o Redis está sendo usado só como cache, esse escopo fica com este agent só, não dividido — sua intuição sobre isso está correta.

- **Modelagem e schema**: design de tabelas em bancos relacionais, de tabelas/GSIs/LSIs em bancos NoSQL de item (ex.: DynamoDB), de coleções/documentos em bancos de documento (ex.: MongoDB) — normalização vs. denormalização conforme o paradigma.
- **Migrations**: escreve e revisa migrations em bancos relacionais (Flyway/EF Core Migrations/Prisma/Django migrations, conforme a linguagem envolvida); em bancos schemaless, cuida da evolução dos *access patterns* (que não são livres mesmo sem schema fixo).
- **Performance e indexação**: índices e `EXPLAIN ANALYZE` em bancos relacionais; índices secundários e estratégias de particionamento em bancos NoSQL; identificação de N+1 queries no código (em conjunto com o agent de linguagem responsável pelo ORM).
- **Cache**: o que cachear e por quê, TTL, estratégia de invalidação (write-through, cache-aside, etc.), quando um cache é a escolha certa vs. quando é over-engineering. **Essa é a razão de o cache ficar aqui e não no Infra** — decidir a estratégia de cache é decisão de modelagem/acesso a dados, não de provisionamento.
- **Divisão de responsabilidade com o Infra (`infra-engineer.md`)**: o Infra **provisiona** a instância (RDS, tabela DynamoDB via Terraform, cluster de cache); o Database **decide como ela é usada** (schema, índices, queries, política de cache). Os dois colaboram no plano quando a tarefa envolve as duas pontas (ex.: criar uma tabela nova end-to-end).
- **Divisão de responsabilidade com os agents de linguagem**: o agent de linguagem escreve o código de acesso a dados (repositório, ORM, query builder); o Database revisa/decide o schema, os índices e a estratégia de query por trás desse código — funciona parecido com o hand-off entre Segurança e Code Reviewer.
- Usa **Graphify** para mapear quais módulos/serviços acessam quais tabelas/coleções (útil pra avaliar impacto de uma migration ou de uma mudança de índice) — como primeira ferramenta de consulta, conforme §7.1.

Fica registrado em `rules/database/` com um `.md` por tecnologia (`postgresql.md`, `dynamodb.md`, `redis-cache.md` de início — cada paradigma é bem diferente entre si mesmo sob o mesmo agent). Quando você usar um banco novo, é só me avisar (ou criar o arquivo direto) que ele entra na mesma estrutura, sem tocar em mais nada.

---

## 7. Skills: o que fica no agente principal vs. nos sub-agents

Ponto central da sua ideia — replicado aqui com clareza:

- **Skills genéricas (agente principal)**: como *conduzir* o trabalho — brainstorming, escrita de plano, execução disciplinada, TDD como prática geral, workflow de git, como pedir revisão de código, **e a skill de delegação** (o "roteador" para os especialistas).
- **Skills/regras técnicas (sub-agents)**: o *conhecimento de domínio* — convenções Angular, padrões OWASP, práticas de Kubernetes, etc. Vivem em `rules/` e são referenciadas pelo prompt de cada sub-agent, não pelo orquestrador.

Isso evita dois problemas comuns: (a) o agente principal virar um "sabe-tudo" genérico com prompt gigante e inconsistente; (b) os sub-agents perderem a metodologia disciplinada do superpowers por serem chamados "crus".

### 7.1 `codebase-navigation` — ordem de uso Graphify → Lumen → Serena → Read

Skill genérica (todo sub-agent que mexe em código herda isso, não só o orquestrador) que documenta a ordem correta de ferramentas de descoberta/edição de código, baseada em como cada MCP realmente funciona por baixo dos panos — não em suposição:

1. **Graphify primeiro, para perguntas sobre estrutura/relação** ("o que chama isso", "o que quebra se eu mudar X", "como X se conecta a Y"). No Claude Code, o próprio Graphify já reforça isso sozinho via um hook `PreToolUse` que intercepta chamadas de busca e de `Read`/`Glob` antes de rodarem, empurrando pro grafo — então essa parte do comportamento **já vem de graça** quando o Graphify está instalado; a skill só formaliza pros outros casos e documenta o porquê.
2. **Lumen em seguida, para "onde está o código que faz X"** quando a pergunta é sobre *localização por significado*, não sobre relação estrutural. Diferente do Graphify, o Lumen **não bloqueia** `Grep`/`Read` via hook — ele só expõe `semantic_search` como ferramenta preferencial. Ou seja: aqui a disciplina depende da skill/prompt, não é garantida pela ferramenta sozinha.
3. **Serena para ler/editar de fato, uma vez que já se sabe onde ir** — símbolo exato, referências cruzadas, renomeação segura. Importante: **nem Graphify nem Lumen substituem isso**. O grafo do Graphify é um mapa estrutural (nós/arestas), não o código-fonte; os chunks do Lumen são trechos candidatos, não uma edição segura. A edição real sempre passa por Serena (ou por `Read`/`Edit` cru, quando Serena não cobre a linguagem/caso).
4. **`Read` cru só como último recurso** — quando as três ferramentas acima não têm a resposta (ex.: arquivo fora do escopo indexado, grafo desatualizado, linguagem sem LSP no Serena).

**Regra prática que a skill impõe:** nenhum sub-agent de engenharia, QA, Code Reviewer, Arquiteto, Segurança ou Database pula direto pro `Read`/`Grep` de um arquivo sem antes checar se Graphify ou Lumen já respondem a pergunta — exceto quando a tarefa já chegou com o caminho exato do arquivo (ex.: veio de um `graph_explain` anterior na mesma sessão).

**Ressalva registrada para verificar na implementação, não assumir resolvida:** já existiu um comportamento documentado do MCP server do Graphify de cachear `graph.json` no startup sem recarregar sozinho após um `--update` (há hoje um modo `--watch` e hook de `post-commit` que devem cobrir isso, mas fica como item de validação real na Fase 4 do roadmap — §12).

---

## 8. Hooks de segurança

**Comportamento padrão definido por você: bloquear por padrão, mas pedir confirmação explícita do usuário para liberar** (não é bloqueio cego, nem passa batido).

### 8.1 Mecanismo
Hooks do tipo `PreToolUse` interceptam chamadas de `Bash` (e `Write`/`Edit` quando relevante) **antes** da execução. O hook roda um script que:
1. Faz *pattern-match* do comando contra uma lista de padrões perigosos (regex).
2. Se casar, retorna decisão `block` via JSON no stdout (`{"decision": "block", "reason": "..."}`) e sai com código não-zero — Claude Code bloqueia o comando e exibe o motivo para o usuário. O usuário precisa adicionar `AEGIS_ALLOW=1` ao comando para passar explicitamente.
3. Registra a tentativa em log local (`~/.aegis/security-hook.log`) para auditoria posterior (o sub-agent de Segurança pode revisar esse log periodicamente).

### 8.2 Categorias cobertas (exemplos — a lista completa vai em `rules/security/dangerous-patterns.md`)
- **Git destrutivo**: `git push --force`, `git push -f`, `git reset --hard`, `git clean -fd`, `git branch -D` em branches protegidas, push direto para `main`/`master`/`production`.
- **Deleção de arquivos**: `rm -rf`, `rm -r` em paths sensíveis (`/`, `~`, raiz do projeto, `.git`), `find ... -delete`.
- **Infra destrutiva**: `terraform destroy`, `kubectl delete namespace/deployment` em contexto de produção, `docker system prune -a`, `aws ... delete-*` / `terminate-instances`.
- **Banco de dados**: `DROP TABLE/DATABASE`, `TRUNCATE`, migrations `down` em produção.
- **Segredos**: commits contendo padrões de chave/API key/token (checagem antes do `git commit`/`git add`), edição de `.env` versionado.
- **Permissões/sistema**: `chmod -R 777`, `sudo` em comandos não whitelisted, alteração de variáveis de ambiente de CI/CD sensíveis.

### 8.3 Estrutura técnica
- `hooks/hooks.json`: registra os matchers (ex.: evento `PreToolUse`, matcher `Bash`) apontando para os scripts.
- `hooks/guard-git-push.py`: intercepta `git push --force` / `git push -f`; bloqueia e sugere `--force-with-lease`.
- `hooks/guard-dangerous-bash.py`: intercepta `rm -rf` e `git reset --hard`; bloqueia com motivo e alternativa segura.
- `hooks/require-confirmation.py`: utilitário compartilhado — parsing do stdin JSON, lógica `AEGIS_ALLOW=1`, escrita de log, formatação da resposta `block`.
- Testável isoladamente (scripts recebem o payload do hook via stdin/JSON e podem ser testados com casos de exemplo, sem precisar rodar o Claude Code completo).
- **Nota**: padrões adicionais documentados em `rules/security/dangerous-patterns.md §Phase 2` (terraform destroy, kubectl delete, DROP TABLE, etc.) estão planejados mas não implementados — a adição de cada um exige adicionar o regex ao script de guarda correspondente.

### 8.4 Extensibilidade
Novos padrões perigosos: (1) documenta em `rules/security/dangerous-patterns.md` (fonte única de descrições e intenção); (2) adiciona o regex ao script de guarda correspondente (`hooks/guard-git-push.py` ou `hooks/guard-dangerous-bash.py`). Os scripts não leem o `.md` em runtime — o arquivo é referência humana, não configuração dinâmica.

### 8.5 Como o hook sabe que é "produção" (decisão fechada)

**Melhor opção: arquivo de config editável, não nome de branch hardcoded no script.** Motivo: nome de branch varia entre projetos (`main` vs `master` vs `production` vs `prod` vs `release/*`), e hardcodar isso no script obrigaria editar código toda vez que um projeto novo usar uma convenção diferente — o mesmo princípio de "fonte única editável" que já vale pra `dangerous-patterns.md` (§8.4).

- Arquivo: `rules/security/production-scope.md` (ou `.json`, mais fácil de o script parsear) — lista de padrões de branch consideradas produção. Vem com um default sensato (`main`, `master`, `production`, `prod`, `release/*`), editável por projeto.
- **Variável de ambiente não é o critério primário** — é frágil (depende de quem/o quê define a variável naquele terminal, inconsistente entre sua máquina e CI) — mas pode ser um *reforço opcional*: se `AEGIS_ENV=production` estiver setada, o hook trata como produção mesmo numa branch que não bateu no padrão, útil pra pipelines de deploy.
- O hook lê esse arquivo antes de decidir a agressividade do bloqueio: comando destrutivo numa branch de produção → sempre pede confirmação (nunca pula essa checagem); fora de produção, ainda bloqueia comandos genuinamente perigosos (`rm -rf /`), mas com uma barra mais permissiva pra coisas como `git push --force` numa branch de feature pessoal seria caso de revisão futura, não coberto por este documento.

---

## 9. Commands

Inspirados no superpowers (`/brainstorm`, `/write-plan`, `/execute-plan`) e no ECC (namespace `/ecc:*`, comandos `/multi-*`). No Aegis, tudo fica sob o namespace `/aegis:*` — mas só existe comando pra fluxo que ganha algo real com isso: **determinismo** (evita o orquestrador interpretar o pedido diferente do que você queria), **scriptabilidade** (rodar fora de conversa interativa, ex.: em CI) ou **atalho** pra algo que você repete sempre do mesmo jeito. Por esse critério, dois comandos que pareciam óbvios ficaram de fora:

- **`/aegis:plan`** — brainstorm → spec → plano já é comportamento padrão do `CLAUDE.md` em qualquer pedido não trivial (§5); um comando pra isso só duplicaria o que o orquestrador já faz sozinho.
- **`/aegis:new-feature`** — pelo mesmo motivo: o `CLAUDE.md` já dispara o pipeline completo (plano → engenharia → QA → segurança → docs) quando a tarefa é uma feature de verdade, e já *não* dispara tudo isso quando é só um ajuste pontual (a disciplina escala com o tamanho da tarefa, não é "sempre processo completo"). Manter um comando pra forçar o pipeline completo seria uma segunda rede de segurança em cima da primeira. Se em algum momento você tiver dúvida se o `CLAUDE.md` cobriu tudo, a saída é rodar os comandos específicos abaixo (`/aegis:security-review`, `/aegis:qa-review`, etc.) um a um — que é exatamente pra isso que eles existem.

| Comando | O que faz |
|---|---|
| `/aegis:architect` | Aciona o sub-agent Arquiteto para decisões de design + diagrama |
| `/aegis:diagram` | Gera/atualiza diagrama via drawio-mcp-server |
| `/aegis:security-review` | Aciona o sub-agent de Segurança num escopo (PR, diretório, feature) |
| `/aegis:qa-review` | Aciona QA para gerar/validar plano de testes |
| `/aegis:db-review` | Aciona o sub-agent de Banco de Dados/Cache para revisar schema, migration, índices ou estratégia de cache num escopo (ex.: antes de mergear uma migration) |
| `/aegis:infra-review` | Aciona o sub-agent de Infra/DevOps para revisar Dockerfile, manifest k8s ou IaC num escopo, isolado do `/aegis:deploy-check` completo |
| `/aegis:code-review` | Aciona o sub-agent Code Reviewer num escopo específico (ex.: PR de outra pessoa, trecho colado), fora do pipeline automático padrão |
| `/aegis:deploy-check` | Checklist pré-deploy (infra + segurança + QA + banco de dados, se houver migration pendente) antes de liberar |

### 9.5 Scripts de instalação / desinstalação (um comando só)

Ponto que você pediu: baixar o sistema inteiro e desinstalar sem sobra, sem precisar lembrar de vários passos manuais. Segue o mesmo espírito do `install.sh --profile full` do ECC e do padrão de reinstalação do superpowers, mas cobrindo também o lado do Aegis que não é só plugin (as `rules/` precisam ser copiadas — plugins de Claude Code não distribuem isso sozinhos, é uma limitação da própria plataforma, o ECC documenta o mesmo problema).

**`scripts/install.sh` (e `install.ps1` no Windows) faz, em sequência:**
1. Clona/atualiza o repositório do Aegis num diretório fixo (ex.: `~/.aegis/repo`).
2. Registra a marketplace e instala o plugin no Claude Code (`/plugin marketplace add ...` + `/plugin install aegis@aegis`, via CLI não-interativa quando o Claude Code suportar; senão imprime o comando exato pra você rodar).
3. Copia `rules/` para `~/.claude/rules/aegis` (instalação a nível de usuário, todos os projetos) **ou** `.claude/rules/aegis` dentro do projeto atual, se a flag `--project` for passada.
4. Registra os `hooks/` no `hooks.json` do Claude Code (merge, não sobrescreve hooks que você já tenha de outros plugins).
5. Roda `scripts/doctor.sh` no final, confirmando que plugin, rules e hooks estão todos ativos, e avisando quais MCPs recomendados (Serena, Lumen, Graphify, drawio-mcp-server) ainda não estão configurados — sem instalá-los sozinho, já que são projetos externos com instalação própria (documentado em `SETUP.md`).
6. É **idempotente**: rodar de novo atualiza (`git pull` + recopia `rules/`) em vez de duplicar — mesmo cuidado que o ECC teve com o problema de "skills duplicadas" ao rodar instalação completa em cima de instalação via plugin.

**`scripts/uninstall.sh` (e `uninstall.ps1`) reverte exatamente os passos acima:**
1. Remove o plugin do Claude Code (`/plugin uninstall aegis@aegis` ou instrução equivalente).
2. Remove `~/.claude/rules/aegis` (ou `.claude/rules/aegis` do projeto, se instalado assim).
3. Remove as entradas do Aegis em `hooks.json` — só as do Aegis, sem tocar em hooks de outros plugins que você tenha.
4. Pergunta antes de apagar `~/.aegis/repo` (o clone local) — só remove se confirmado, para não perder customizações que você tenha feito ali.
5. Não mexe nos MCPs externos (Serena/Lumen/Graphify/drawio) — eles são instalados/desinstalados de forma independente, cada um com seu próprio ciclo de vida.

**`scripts/doctor.sh`**: script de verificação isolado (pode ser rodado a qualquer momento, não só durante install/uninstall) — confirma se o plugin está ativo, se as `rules/` estão no lugar certo, se os hooks estão registrados, e lista quais MCPs recomendados respondem/estão configurados. Inspirado no `/lumen:doctor` do Ory Lumen.

---

## 10. Integrações MCP — quem usa o quê

| MCP | Instalado por | Sub-agents que usam |
|---|---|---|
| Graphify | a instalar | Arquiteto, Segurança (impacto/blast radius, mapeamento de dependências), Database (quem acessa quais tabelas) — primeira parada para pergunta de estrutura/relação (§7.1) |
| Lumen | você já tem | Engenharia, QA, Code Reviewer — segunda parada, busca por significado (§7.1) |
| Serena | você já tem | Engenharia (todas as linguagens), Code Reviewer, Database (edição de migrations/schema) — quem efetivamente lê/edita, depois de Graphify/Lumen indicarem onde (§7.1) |
| drawio-mcp-server | a instalar | Arquiteto (diagramas C4/sequência/infra) |

Ficam registrados em `mcp-config/recommended-mcp.json` como referência — a instalação/configuração real de cada MCP acontece direto no Claude Code (`claude mcp add ...`), documentada no `SETUP.md` do projeto. A ordem de uso entre os três primeiros (não a ordem de instalação) está em `skills/codebase-navigation/SKILL.md`, detalhada em §7.1.

---

## 11. Documentos do projeto (a criar junto com o repositório real)

Quando formos criar o repositório de fato no Claude Code, os seguintes documentos devem existir **na raiz do repositório** (não dentro de `docs/` — README, CHANGELOG, SETUP e CONTRIBUTING são esperados na raiz por convenção do GitHub e por quem for instalar o plugin, `docs/` fica reservado só para a arquitetura viva):

- **`README.md`** — o que é o Aegis, instalação rápida (aponta pro `scripts/install.sh`), lista de sub-agents e commands, exemplo de uso.
- **`SETUP.md`** — passo a passo detalhado: o que `scripts/install.sh`/`scripts/uninstall.sh` fazem automaticamente (§9.5), e o passo manual que sobra (instalação de cada MCP externo — Serena, Lumen, Graphify, drawio-mcp-server — com os comandos exatos `claude mcp add ...` e a verificação via `scripts/doctor.sh`).
- **`CHANGELOG.md`** — formato Keep a Changelog + SemVer, começando em `0.1.0`.
- **`CONTRIBUTING.md`** — como adicionar um novo sub-agent, uma nova regra de hook, ou uma nova linguagem (`rules/<lang>/`), garantindo consistência com o padrão dos demais.
- **`docs/architecture/`** — única coisa que continua dentro de `docs/`: ADRs e diagramas gerados pelo sub-agent Arquiteto (fonte viva, não só este documento inicial).

---

## 12. Roadmap sugerido de implementação

1. **Fase 0 — Esqueleto**: `plugin.json`, `CLAUDE.md` do orquestrador, estrutura de pastas vazia, hooks básicos (git push + rm -rf) funcionando e testados isoladamente.
2. **Fase 1 — Segurança primeiro**: todos os hooks de §8 implementados e validados antes de qualquer outra coisa (é a rede de proteção para tudo que vem depois).
3. **Fase 2 — Sub-agents core**: Arquiteto, Segurança, QA, Code Reviewer, Infra, Database/Cache (o "esqueleto do ciclo de vida", independente de linguagem).
4. **Fase 3 — Sub-agents de engenharia**: as linguagens confirmadas (§6.6), 12 sub-agents no total, um por vez. Ordem sugerida por ubiquidade típica de uso (ajuste livremente se sua prioridade real for outra):
   1. `lang-js-ts` (JS/TS — base do ecossistema, frameworks como Angular/React entram depois, via `rules/`)
   2. `lang-python`
   3. `lang-csharp`
   4. `lang-php`
   5. `lang-go`
   6. `lang-kotlin`, `lang-swift`, `lang-dart` (mobile, em paralelo se fizer sentido)
   7. `lang-java`, `lang-ruby`
   8. `lang-cpp`, `lang-rust`
5. **Fase 4 — Integrações MCP**: Serena/Lumen (já tem) → Graphify → drawio-mcp-server, um de cada vez, validando com um sub-agent real antes de seguir para o próximo. Inclui escrever `skills/codebase-navigation/SKILL.md` (§7.1) e confirmar na prática o comportamento do hook do Graphify e a atualização do `graph.json` (a ressalva de hot-reload citada em §7.1).
6. **Fase 5 — Commands restantes** (`/aegis:architect`, `/aegis:diagram`, `/aegis:security-review`, `/aegis:qa-review`, `/aegis:db-review`, `/aegis:infra-review`, `/aegis:code-review`, `/aegis:deploy-check`), validando que cada um aciona o sub-agent certo isoladamente.
7. **Fase 6 — Scripts de instalação/desinstalação** (§9.5): `install.sh`/`install.ps1`, `uninstall.sh`/`uninstall.ps1`, `doctor.sh` — testados num ambiente limpo antes do release, incluindo o caso de rodar `install` duas vezes seguidas (idempotência) e o caso de `uninstall` não deixar sobra.
8. **Fase 7 — Documentação final** (README/SETUP/CHANGELOG/CONTRIBUTING na raiz) e primeiro release `0.1.0`.

---

## 13. Pendência real para quando formos implementar

Só sobrou uma coisa que só você pode resolver (nome, escopo de produção e OWASP já foram fechados nas seções acima):

- **Frameworks por linguagem**: quando quiser, me passe a lista real (ex.: TypeScript → Angular; Python → FastAPI; Dart → Flutter) e eu monto os arquivos `rules/<lang>/frameworks/<framework>.md` já no padrão certo — não precisa ser agora.
