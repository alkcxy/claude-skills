---
name: my-agentic-docs
description: Usare quando si imposta, audita o sistema i file di contesto per agenti AI (AGENTS.md, CLAUDE.md, copilot-instructions.md, file annidati per sottocartella/area/account). Copre il pattern symlink AGENTS.md↔CLAUDE.md, quando creare file scoped per area/funzionalità invece di un unico file enorme, cosa includere nei contenuti, come verificare che non siano disallineati dallo stato reale del repo, e come evitare che contesto di un altro account/dominio (es. lavoro vs personale) finisca caricato dove non serve.
---

# Agentic docs — impostare e correggere i file di contesto di un progetto

I file `AGENTS.md`/`CLAUDE.md` sono il modo in cui un agente scopre come funziona un repo senza dover indovinare. Le regole sotto evitano gli errori più comuni: file che l'agente non legge davvero, contenuti duplicati o scollegati dalla realtà, scoping sbagliato (tutto in un unico file enorme, o frammentato dove non serve).

## 1. Inventario prima di tutto

Cerca tutti i file esistenti, alla radice e annidati:
```bash
find . \( -iname "AGENTS.md" -o -iname "CLAUDE.md" -o -iname "copilot-instructions.md" -o -iname "CLAUDE.local.md" \) -not -path "*/node_modules/*" -not -path "*/.git/*"
```
Per ognuno, controlla con `ls -la` se è un file vero o un symlink, e se più file hanno contenuti che si sovrappongono o divergono (drift tra fonti).

## 2. Pattern corretto: AGENTS.md come fonte, CLAUDE.md come symlink

**Claude Code non legge `AGENTS.md` nativamente** — solo `CLAUDE.md` (richiesta aperta `anthropics/claude-code#34235`, migliaia di upvote, non ancora implementata a metà 2026). `AGENTS.md` è invece lo standard cross-tool (stewardship Linux Foundation / AAIF, 60k+ repo) letto da Codex, Cursor, Copilot, Windsurf, ecc.

La soluzione che chiude il cerchio: scrivere `AGENTS.md` come fonte di verità e creare `CLAUDE.md` come **symlink** ad esso, nella stessa cartella:
```bash
ln -s AGENTS.md CLAUDE.md
```
Un file su disco, due nomi, zero disallineamento. Applicalo a ogni cartella che ha (o dovrebbe avere) un file di contesto.

Casi da correggere quando li trovi:
- **Solo `CLAUDE.md` con contenuto reale**: rinominalo in `AGENTS.md` e ricrea `CLAUDE.md` come symlink — si guadagna compatibilità cross-tool senza perdere nulla per Claude.
- **`AGENTS.md` e `CLAUDE.md` come file separati con contenuti diversi**: è drift. Scegli quale tenere come fonte (di solito il più completo/aggiornato), elimina l'altro, ricrea il symlink.
- **`copilot-instructions.md` o varianti analoghe**: stesso trattamento — symlink al file sorgente, non copie.

## 3. Quando creare file scoped per area (e quando no)

Claude Code carica i file annidati **on demand**: un `CLAUDE.md`/`AGENTS.md` in una sottocartella si attiva solo quando l'agente tocca file di quella sottocartella, non all'avvio. È il meccanismo corretto per "non riempire il contesto con info che servono solo qualche volta" — l'alternativa a un unico file monolitico che cresce senza controllo.

**Crea un file scoped solo se la sottocartella ha davvero uno stack, build/test o convenzioni diversi dal resto del repo** — es. un'estensione browser in JS vanilla dentro un'app Rails, un frontend in un monorepo backend. Indizi concreti: linguaggio diverso, comandi di build/test diversi, suite di test diversa o assente, dipendenze/runtime separati.

**Non frammentare un progetto piccolo o uniforme**: se tutto il repo condivide stack e convenzioni, un solo file alla radice basta — spezzarlo aggiunge manutenzione (sincronizzare N file) senza guadagno reale.

Quando crei un file scoped, evita di ripetere quanto già detto nel file radice: deve aggiungere solo ciò che è *diverso* in quel sottoalbero, e può rimandare al file radice per il resto.

## 4. Cosa deve contenere ogni file (e cosa no)

Contenuto utile, in ordine di priorità:
1. **Comandi che funzionano davvero per *questo* progetto** — non `npm test` generico se in realtà serve `docker compose run --rm <service> bundle exec rails test`. Se esistono comandi diversi per scenari diversi (es. unit test vs system test che richiede un servizio Selenium dedicato), spiega quale usare quando e perché — l'agente non può dedurre da solo che il servizio sbagliato produce `Errno::ECONNREFUSED`.
2. **Vincoli e gotcha non derivabili dal codice**: limiti hardware, versioni bloccate, "sembra che si possa fare X ma in realtà serve Y per motivo Z".
3. **Stack e versioni concrete** (linguaggio, framework, DB, runtime).
4. **Mappa del repo** con puntatori ai file scoped per area, se esistono.

Tieni i file **snelli**: quello radice è caricato a ogni sessione, quelli annidati ogni volta che si tocca quell'area. Dettagli molto specifici o voluminosi vanno linkati da fonti esterne (memoria, `docs/`, ADR), non incollati per intero.

Se conoscenze rilevanti sul progetto vivono solo nella memoria esterna dell'agente (es. `~/.claude*/projects/.../memory/`), valuta di consolidarle qui: nel repo sono visibili a chiunque (umani e altri tool), sopravvivono al reset della memoria, e viaggiano col codice.

## 5. Verifica drift: i contenuti corrispondono ancora alla realtà?

I file di contesto invecchiano: comandi rinominati, percorsi spostati, versioni cambiate. Prima di fidarti di un file esistente (o dopo averlo scritto/corretto), verifica che le affermazioni fattuali siano ancora vere:
- I comandi citati esistono e girano? (`docker compose config`, `<tool> --help`, dry-run quando possibile)
- I percorsi/file citati esistono ancora? (`ls`, `find`)
- Le versioni dichiarate combaciano con lockfile/manifest? (`Gemfile.lock`, `package.json`, `.tool-versions`, ecc.)

Se trovi affermazioni non più vere, correggile sul posto invece di lasciarle — un file di contesto sbagliato è peggio di nessun file, perché l'agente lo tratta come verità.

## 6. Lo scope non finisce al progetto: controlla anche cosa arriva dall'alto

Claude Code non carica solo i file del repo: risale la gerarchia delle directory raccogliendo ogni `CLAUDE.md` che trova fino alla radice, oltre al file utente globale (`~/.claude/CLAUDE.md`). Un audit incompleto guarda solo dentro il progetto — il contesto "che arriva da fuori" può essere altrettanto rilevante, o dannoso quanto uno scoping sbagliato dentro il repo.

**Caso concreto da cercare**: contenuti specifici di un account/dominio finiti in un file caricato ovunque. Esempio reale riscontrato: un `CLAUDE.md` globale che mischiava setup e workflow dell'account di lavoro (ricerca interna aziendale, workflow Jira, pattern di un progetto Android specifico) con quelli dell'account personale — risultato: ogni sessione su un progetto privato si portava dietro contesto aziendale del tutto irrilevante (e viceversa). È lo stesso problema di scoping del punto 3, ma un livello più in alto — e altrettanto concreto: un agente che cita un pattern Android aziendale come esempio mentre lavora su un'app Rails privata non sta semplicemente "sbagliando esempio", sta dimostrando che il contesto sbagliato gli è arrivato in tasca.

**Come correggere**: sposta i contenuti specifici-di-dominio al livello di directory che corrisponde davvero al loro confine — non al singolo progetto (troppo stretto), né al file utente globale (troppo largo). Tipicamente la directory che raggruppa i progetti di un account/contesto (es. `~/workspace/mine/CLAUDE.md` per progetti personali, `~/workspace/expedia/CLAUDE.md` per progetti aziendali): Claude Code li carica automaticamente — e solo — quando si lavora in quell'albero, mentre il file globale resta snello con le sole regole davvero universali (stile di comunicazione, lingua, convenzioni di PR review). In ciascun file scoped per account, vale la pena scrivere esplicitamente la regola "non mescolare": non confrontare, citare esempi o portare pattern da progetti dell'altro account/contesto, salvo richiesta esplicita.

Per vedere cosa carica davvero una sessione, controlla l'elenco dei file di memoria mostrato all'avvio o usa `/memory`.
