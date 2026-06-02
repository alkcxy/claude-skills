---
name: review
description: Usare prima di considerare una storia/PR "done", quando si riepiloga lo stato al utente, o quando si descrivono gli endpoint/funzionalità disponibili. Forza la verifica manuale, l'allineamento tra descrizione e codice reale del branch, la documentazione dei workaround temporanei e un tono non paternalistico.
---

# Review — chiudere una storia senza tradire la realtà

Le regole sotto nascono da disallineamenti tra descrizione e realtà, e da output paternalistici che hanno irritato l'utente in passato.

## Regola di base: descrivere il branch, non il default

Quando si comunica all'utente cosa è disponibile (endpoint, comandi, funzionalità):
- Riferirsi al **codice della storia in lavorazione**, non al branch di default (`main`/`master`).
- L'utente può aver deployato un feature branch senza mergiarlo: lo stato del deploy non si deduce dallo stato della PR.
- Se non sei certo di quale ref l'utente sta guardando, chiedi (`git branch --show-current`, `git log -1 --oneline`).

## Test manuale come parte di "done"

I test automatici passanti **non** sono sufficienti per chiudere una storia.

**Per storie API / backend:**
- Avviare il server locale nell'ambiente verificato in fase di plan.
- Eseguire almeno le richieste rappresentative degli endpoint toccati dalla storia (es. `curl`, `httpie`).
- Verificare: status code, content-type, body, side-effect su DB.
- Riportare il comando eseguito e l'output osservato all'utente prima di dichiarare "done".

**Per storie con UI o componenti senza suite automatica:**
- Avviare l'ambiente reale di esecuzione.
- Eseguire il test plan manuale definito in fase TDD.
- Riportare quali step hanno passato e quali no.

Se il test manuale non è stato eseguito, dirlo esplicitamente invece di affermare che la feature funziona.

## Documentare i workaround temporanei

Se durante l'implementazione si è usato un placeholder o un workaround che andrà aggiornato:
- **Scriverlo nella PR description**, non solo nei commenti del codice o nella chat.
- Specificare: cos'è il placeholder, perché è temporaneo, **come e quando** sostituirlo.

Formato consigliato:
> Workaround: il valore X in `path/to/file.ext` è un placeholder. Va sostituito con il valore definitivo Y ottenuto da Z, prima del rilascio in produzione.

## Non essere paternalistici

L'utente ha già preso decisioni: rispettarle.

**Da evitare:**
- Avvertimenti su scelte che l'utente ha già fatto consapevolmente (es. token in plain text in un contesto di sviluppo).
- Richiedere conferma per operazioni già autorizzate ("sicuro di voler procedere con X?").
- Aggiungere disclaimer/cautele non richieste a fine risposta.
- Riepiloghi del tipo "ricorda che in produzione dovresti..." quando l'utente sta lavorando in sviluppo e lo sa.

**Da fare:**
- Se hai un dubbio fondato basato su evidenza concreta nel codice, sollevarlo *una volta*, in modo specifico, e procedere.
- Se l'utente conferma "lo so", non riproporlo.
- Output asciutti: cosa è stato fatto, cosa serve verificare. Niente padding.

## Output di chiusura storia

Quando si riporta all'utente la chiusura di una storia, includere:
1. **Branch e ref** su cui si è lavorato (`git log -1 --oneline`).
2. **Test automatici eseguiti** e risultato.
3. **Test manuale eseguito**: comandi/step e output osservato.
4. **Workaround temporanei** presenti e dove sono documentati.
5. **Endpoint/funzionalità disponibili** descritti in base al codice del branch.

Nessuna delle voci sopra va omessa per brevità. Se una non si applica, scrivere esplicitamente "n/a perché ..." invece di saltarla.

## Anti-pattern da evitare

- "I test passano, è pronto" senza aver eseguito un test manuale.
- Descrivere endpoint guardando il branch di default quando l'utente è su un feature branch.
- Workaround lasciati solo come `# TODO` nel codice senza essere ripresi nella PR description.
- Trailing summary con avvertimenti non richiesti.
- Chiedere conferma per azioni già esplicitamente autorizzate dall'utente.
