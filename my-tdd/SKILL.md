---
name: my-tdd
description: Usare quando si sta implementando una storia/feature e c'è da scrivere codice produttivo. Forza il ciclo red-green-refactor, la copertura dei path non-happy, i test di sicurezza per gli endpoint, e — quando i test automatici non sono possibili — la definizione di un test plan manuale strutturato prima del codice.
---

# TDD — test prima del codice, sempre

Le regole sotto nascono da bug concreti emersi solo in produzione o in review perché i test erano stati scritti dopo l'implementazione (o erano mancanti del tutto).

## Regola di base: red prima di green

- Scrivere il test, vederlo fallire, *poi* implementare.
- Se il test passa al primo colpo prima di toccare il codice produttivo, è probabilmente un test sbagliato — verificare l'assertion.
- Pattern tipico mancato: un bug di configurazione del cache (es. cache store "no-op" in test) sarebbe emerso in locale durante un test red-first, invece di emergere in produzione.

## Localizzare il codice con precisione (tool semantici)

Per trovare la funzione/endpoint sotto test, i suoi call-site e i side-effect da asserire, se il progetto ha un tool LSP-based (es. **serena**) preferire le query a livello di simbolo alla lettura di interi file:
- `find_symbol` con body per leggere esattamente la funzione da testare o rifattorizzare.
- `search_for_pattern` (grep semantico) per mappare i call-site e i punti che producono side-effect — es. dove si fa `Resource.find(params[:id])` invece di `current_user.resources.find(...)`, il bug che il test cross-user deve catturare.
- In fase di **refactor** (la R di red-green-refactor): prima di cambiare una firma, mappare tutti i riferimenti. `find_referencing_symbols` è lo strumento ideale **ma** è inaffidabile a LSP freddo (timeout o risultato vuoto) → fallback su `search_for_pattern` finché l'indice non è caldo.

Vantaggio: posizioni e firme esatte con molto meno contesto consumato rispetto a leggere interi file. La precisione delle righe evita assertions o edit basati su numeri di riga stimati.

## Coprire i path non-happy con assertions precise

I test del solo happy path lasciano passare bug strutturali. Per ogni endpoint/feature, prevedere assertions su:
- **Codici di stato** specifici: `429` per throttle, `401`/`403` per auth, `422` per validation, ecc.
- **Content-Type** della response: un `429` con `text/html` invece di `application/json` è un bug che solo un'assertion esplicita cattura.
- **Body della response** per errori: shape, campi, messaggi.
- **Side effect mancanti**: es. richiesta throttlata → nessuna scrittura su DB.

Esempio canonico: un test che simula N+1 richieste contro un endpoint con rate-limit e verifica `status 429` + `Content-Type: application/json` cattura sia eventuali bug del cache store sia il formato sbagliato della response di errore.

## Sicurezza: test esplicito per ogni endpoint

I bug di authorization (cross-user / cross-tenant access) emergono in review se non li copri con test. Per ogni endpoint con dati per-utente:

- **Test cross-user obbligatorio**: utente A autenticato tenta di leggere/modificare risorsa di utente B → deve fallire (`403` o `404`).
- Vale per: `show`, `update`, `destroy`, e qualsiasi action con `:id` di risorsa scopata all'utente.
- Pattern di bug ricorrente: una action che fa `Resource.find(params[:id])` invece di `current_user.resources.find(params[:id])` espone le risorse di tutti gli utenti — un test cross-user lo cattura subito.

Considera questo test parte della definizione di "done", non un extra.

## Quando i test automatici non sono possibili: test plan manuale

Alcune parti del codice non hanno una suite (es. UI con setup manuale, integrazioni con sistemi esterni in sandbox, browser extension senza build step). In quei casi:

- **Definire il test plan PRIMA di scrivere codice**, non dopo.
- Test plan = lista di step verificabili su ambiente reale.
- Includere il test plan nello **stesso commit** della feature, non in un commit successivo o nella PR description aggiunta dopo.
- Ogni step deve avere: precondizione, azione, risultato atteso.

Esempio di formato accettabile:
```
1. Setup: ambiente X configurato con credenziali Y.
2. Azione: chiama endpoint Z con payload W.
3. Atteso: risposta 200, body contiene campo `foo` valorizzato.
4. Atteso (side effect): record creato in tabella `bar` con `user_id = current_user.id`.
```

## Commenti: quasi sempre sono codice scritto male

La R di red-green-**refactor** include togliere i commenti rendendoli superflui.

- **Docstring sì, commenti inline no.** Se un blocco ha bisogno di un commento
  per spiegarsi, estrarre un metodo con un nome che dica quello che direbbe il
  commento, o una costante autodescrittiva. Il nome resta corretto anche quando
  il codice cambia; il commento no.
- **Una docstring dice cosa fa il codice adesso, non come era prima.** Niente
  "ogni getter riparsava il file", niente "prima erano tre variabili globali",
  niente misure del miglioramento: il racconto del difetto e di come è stato
  risolto sta nel commit e nella PR, dove resta datato. Nel codice invecchia, e
  chi legge deve attraversare la storia per arrivare all'unica riga che gli
  serve. Vale anche per le docstring delle classi di test e per gli header dei
  file di configurazione.
- **Inglese** per tutto ciò che resta nel codice: docstring, nomi, messaggi.
- **Mai riferimenti a numeri di issue** (`#44`, `#22`) nel codice: invecchiano
  male e legano il sorgente a una storia finita. Le motivazioni legate a una
  storia vanno nel messaggio di commit o nella descrizione della PR, che sono
  il posto giusto per il contesto temporaneo.
- **File di configurazione**: `config.ini` e simili sono l'unico posto dove i
  commenti *servono* davvero — li legge un operatore, non uno sviluppatore, e
  spiegano cablaggi e soglie che il nome della chiave non dice. Anche lì però
  l'inglese, come nel resto.
- **Codice commentato** (righe di codice disattivate con `#`): si cancella. Se
  serviva, è nella storia git.

Prima di lasciare un commento, chiedersi: *un nome migliore lo elimina?* Se sì,
il commento è il sintomo, non la cura.

## Output dell'implementazione TDD

Prima di considerare l'implementazione "done":
1. **Test rossi visti** prima di scrivere il codice produttivo (red-green-refactor reale).
2. **Path non-happy coperti** con assertions precise (status, content-type, body).
3. **Test cross-user** per ogni endpoint scopato all'utente.
4. **Test plan manuale** scritto nello stesso commit, se la suite automatica non copre.
5. **Push del branch e creazione della PR** — dopo che i test automatici passano, fare push e aprire la PR.
6. **Test plan eseguito** almeno una volta sull'ambiente reale, **dopo la creazione della PR** (vedi skill `my-review`).

## Creare la PR

Dopo che i test automatici passano, push del branch e apertura della PR:

```bash
git push -u origin <branch>
gh pr create --title "<titolo>" --body "$(cat <<'EOF'
## Summary
- <bullet point delle modifiche>

## Test plan manuale
<copiare qui il test plan manuale se presente, altrimenti "N/A — copertura automatica completa">

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- Il titolo segue il formato dei commit recenti del repo.
- Il test plan manuale va nel body della PR, non in un commit separato dopo.
- I test manuali si eseguono **dopo** aver aperto la PR, non prima.

## Anti-pattern da evitare

- Scrivere il codice e poi i test "per coprire".
- Test che asseriscono solo `expect(response).to be_successful` senza controllare status code e content-type.
- Endpoint API senza un test esplicito di authorization cross-user.
- Spiegare con un commento quello che un nome di metodo o costante direbbe meglio.
- Aprire una docstring raccontando com'era il codice prima della modifica, o di quanto è migliorato.
- Citare numeri di issue nel codice invece che nel commit o nella PR.
- Lasciare righe di codice commentate "per sicurezza": c'è git.
- "Aggiungerò il test plan dopo nella PR description".
- Saltare il test plan manuale perché "tanto la feature funziona, l'ho provata al volo".
- Eseguire i test manuali prima di aprire la PR.
- Rinominare o spostare un simbolo senza prima mappare tutti i suoi riferimenti (a LSP caldo via `find_referencing_symbols`, altrimenti via `search_for_pattern`).
