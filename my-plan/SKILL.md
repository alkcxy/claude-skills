---
name: my-plan
description: Usare quando si inizia a lavorare su una storia/issue/feature e serve fare planning prima di scrivere codice. Forza la lettura dell'issue, la verifica dell'ambiente di esecuzione, il controllo della config del framework e l'identificazione dei prerequisiti tecnici.
---

# Plan — preparare il terreno prima di scrivere codice

Le regole sotto evitano i fallimenti più tipici della fase di planning: assunzioni sull'ADR, comandi lanciati sull'ambiente sbagliato, dipendenze aggiunte senza verificare la config su cui poggiano, prerequisiti scoperti a metà implementazione.

## Checklist da eseguire prima di toccare codice

### 0. Creare il branch della storia (PRIMO PASSO, sempre)

- Tornare su master/main ed aggiornarlo da origin **prima** di creare il branch:
  ```bash
  git checkout master
  git pull origin master
  git checkout -b feature/<nome-storia>
  ```
- Non creare il branch da un branch di una storia precedente, anche se ci si trova già lì: il punto di partenza deve essere sempre master/main sincronizzato con origin.
- Questo va fatto **prima** di leggere l'issue, prima di toccare qualsiasi file.

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
- Modalità di test disponibili: c'è una suite automatizzata? Se no, va previsto un test plan manuale (vedi skill `my-tdd`).

## Output del planning

Prima di passare all'implementazione, comunicare in forma sintetica:
1. **Cosa dice l'issue** che non è nell'ADR (o conferma che l'ADR copre tutto).
2. **Ambiente scelto** e perché.
3. **Verifiche di config eseguite** e risultato.
4. **Prerequisiti** identificati con piano per ciascuno (placeholder, riuso, vincoli).
5. **Strategia di test** (automatica o manuale strutturata).

Se uno di questi punti è incerto, fermarsi e chiarire prima di scrivere codice.

### Salvare il piano su file (senza committare)

Dopo aver comunicato il piano, salvarlo in `docs/piano-<nome-storia>.md` nel progetto **senza fare commit**. Questo permette all'utente di resettare il contesto di Claude e avviare l'implementazione in una sessione fresca, con il piano già disponibile come file di riferimento.

## Anti-pattern da evitare

- Iniziare a lavorare senza aver fatto `git pull` e creato il branch dedicato.
- Iniziare a scrivere codice basandosi solo sull'ADR.
- Lanciare comandi del framework senza aver verificato che la toolchain sia disponibile sull'ambiente corrente.
- Aggiungere una dipendenza senza aver controllato la config su cui poggia.
- Duplicare logica già presente perché non si è cercato nel codice esistente.
- Rimandare la definizione del test plan a "dopo".
- Lasciare il piano solo nella conversazione senza salvarlo su file: il contesto può essere resettato prima dell'implementazione.
