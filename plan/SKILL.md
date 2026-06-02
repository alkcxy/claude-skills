---
name: plan
description: Usare quando si inizia a lavorare su una storia/issue/feature e serve fare planning prima di scrivere codice. Forza la lettura dell'issue, la verifica dell'ambiente di esecuzione, il controllo della config del framework e l'identificazione dei prerequisiti tecnici.
---

# Plan — preparare il terreno prima di scrivere codice

Le regole sotto evitano i fallimenti più tipici della fase di planning: assunzioni sull'ADR, comandi lanciati sull'ambiente sbagliato, dipendenze aggiunte senza verificare la config su cui poggiano, prerequisiti scoperti a metà implementazione.

## Checklist da eseguire prima di toccare codice

### 1. Leggere l'issue, non solo l'ADR

- Aprire l'issue collegata alla storia come primo passo, sempre.
- L'ADR descrive la decisione; l'issue spesso contiene: formato esatto delle response, casi limite, dipendenze precise, vincoli di sicurezza.
- Non assumere che l'ADR sia esaustivo. Se manca un dettaglio nell'issue, chiarirlo con l'utente prima di proporre un'implementazione.

### 2. Verificare l'ambiente di esecuzione

- Molti progetti supportano più modalità (es. container vs runtime nativo, opzioni A/B nel README). Verificare quale è disponibile *prima* di eseguire qualsiasi comando.
- Comandi tipici di verifica: `which <toolchain>`, `docker ps`, lettura della sezione setup del README.
- Evita tentativi a vuoto: un controllo costa secondi, un comando lanciato sull'ambiente sbagliato può sporcare lo stato del progetto.

### 3. Controllare la config del framework prima di aggiungere dipendenze

- Librerie/middleware spesso dipendono da configurazioni preesistenti (es. un cache store reale e non un no-op, un middleware già montato, una struttura di routing).
- Eseguire un controllo preventivo della config prima di aggiungere la dipendenza: scoprire un componente "no-op" o assente *prima* evita bug che altrimenti emergono solo in produzione.
- Esempio di pattern: leggere la config attiva del cache/queue/auth via runner del framework, ispezionare la lista middleware, controllare initializer rilevanti.

### 4. Anticipare i prerequisiti tecnici

Prima di dichiarare il planning completo, elencare esplicitamente:
- Configurazioni esterne richieste (es. ID di un'estensione, secret, env var, chiavi API).
- Codice esistente da riutilizzare invece di duplicare (cercare con grep prima di scrivere).
- Vincoli del runtime (es. ambienti senza stato in-memory persistente, sandbox con permessi limitati).
- Modalità di test disponibili: c'è una suite automatizzata? Se no, va previsto un test plan manuale (vedi skill `tdd`).

## Output del planning

Prima di passare all'implementazione, comunicare in forma sintetica:
1. **Cosa dice l'issue** che non è nell'ADR (o conferma che l'ADR copre tutto).
2. **Ambiente scelto** e perché.
3. **Verifiche di config eseguite** e risultato.
4. **Prerequisiti** identificati con piano per ciascuno (placeholder, riuso, vincoli).
5. **Strategia di test** (automatica o manuale strutturata).

Se uno di questi punti è incerto, fermarsi e chiarire prima di scrivere codice.

## Anti-pattern da evitare

- Iniziare a scrivere codice basandosi solo sull'ADR.
- Lanciare comandi del framework senza aver verificato che la toolchain sia disponibile sull'ambiente corrente.
- Aggiungere una dipendenza senza aver controllato la config su cui poggia.
- Duplicare logica già presente perché non si è cercato nel codice esistente.
- Rimandare la definizione del test plan a "dopo".
