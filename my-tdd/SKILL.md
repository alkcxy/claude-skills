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

## Output dell'implementazione TDD

Prima di considerare l'implementazione "done":
1. **Test rossi visti** prima di scrivere il codice produttivo (red-green-refactor reale).
2. **Path non-happy coperti** con assertions precise (status, content-type, body).
3. **Test cross-user** per ogni endpoint scopato all'utente.
4. **Test plan manuale** scritto nello stesso commit, se la suite automatica non copre.
5. **Test plan eseguito** almeno una volta sull'ambiente reale (vedi skill `my-review`).

## Anti-pattern da evitare

- Scrivere il codice e poi i test "per coprire".
- Test che asseriscono solo `expect(response).to be_successful` senza controllare status code e content-type.
- Endpoint API senza un test esplicito di authorization cross-user.
- "Aggiungerò il test plan dopo nella PR description".
- Saltare il test plan manuale perché "tanto la feature funziona, l'ho provata al volo".
