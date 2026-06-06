# claude-skills

Skill personali per [Claude Code](https://claude.com/claude-code), pensate per essere installate a livello utente (`~/.claude/skills/`) via symlink in modo da poterle aggiornare con un semplice `git pull`.

## Skill disponibili

| Skill | Quando si attiva |
| --- | --- |
| `plan` | Prima di scrivere codice su una storia/issue/feature: lettura issue, verifica ambiente, controllo config framework, prerequisiti tecnici. |
| `tdd` | Durante l'implementazione: ciclo red-green-refactor, path non-happy, test cross-user per gli endpoint, test plan manuale strutturato. |
| `review` | Prima di chiudere una storia: test manuale, allineamento descrizione/branch, documentazione dei workaround, tono non paternalistico. |
| `validate` | Per validare/fact-checkare un testo argomentativo: inventario delle affermazioni, verifica fattuale, coerenza affermazioni-evidenze, flusso logico, analisi controfattuale (steelmanning) con classificazione 🟢/🟡/🔴. |
| `agentic-docs` | Per impostare/audire/correggere i file di contesto per agenti AI di un progetto (`AGENTS.md`/`CLAUDE.md` e varianti annidate): pattern symlink, scoping per area, contenuti, verifica drift rispetto allo stato reale del repo. |

Ogni skill è una directory con un `SKILL.md` dotato di frontmatter `name` + `description`. Claude Code carica la skill quando la `description` matcha l'intento dell'utente o quando si chiama esplicitamente via `/<nome-skill>` o dal tool `Skill`.

## Installazione

Requisiti: `git`, `bash`, una versione di Claude Code che supporti le user skills in `~/.claude/skills/`.

```bash
git clone https://github.com/alkcxy/claude-skills.git ~/workspace/claude-skills
cd ~/workspace/claude-skills
./install.sh
```

`install.sh` crea (se non esiste) `~/.claude/skills/` e per ogni directory contenente un `SKILL.md` crea un symlink dentro `~/.claude/skills/` puntando alla copia nel repo. Il symlink è non distruttivo: se un nome collide con qualcosa di preesistente in `~/.claude/skills/` lo script salta quella skill e segnala il conflitto invece di sovrascriverlo.

Puoi clonare in qualsiasi path: lo script usa il path assoluto della directory in cui si trova.

## Aggiornamento

```bash
cd ~/workspace/claude-skills
./update.sh
```

`update.sh` fa `git pull --ff-only` e poi rigira `install.sh` per linkare eventuali skill nuove aggiunte nel frattempo. Le skill esistenti sono già aggiornate automaticamente grazie ai symlink.

## Disinstallazione

```bash
cd ~/workspace/claude-skills
./uninstall.sh
```

Rimuove solo i symlink che puntano effettivamente a questo repo. Skill di terze parti o file regolari in `~/.claude/skills/` non vengono toccati.

## Aggiungere una nuova skill

1. Crea una directory con un nome breve, kebab-case: `mkdir nome-skill`.
2. Dentro, scrivi `SKILL.md` con il frontmatter:
   ```markdown
   ---
   name: nome-skill
   description: Una frase che descrive *quando* la skill va attivata. Claude la usa per decidere se caricarla.
   ---

   # Nome skill

   Corpo della skill in markdown.
   ```
3. Commit e push.
4. Sugli host già installati basta `./update.sh`.

## Licenza

MIT — vedi `LICENSE`.
