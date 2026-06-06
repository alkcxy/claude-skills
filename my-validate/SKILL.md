---
name: my-validate
description: Usare quando l'utente chiede di validare, verificare, fact-checkare o "stress-testare" un testo argomentativo (articolo, post, saggio, tesi, paper). Applica un processo strutturato in 5 fasi — inventario delle affermazioni verificabili, verifica fattuale, coerenza affermazioni-evidenze, flusso logico, analisi controfattuale (steelmanning) — e produce un riepilogo classificato 🟢/🟡/🔴.
---

# Validate — verificare un testo argomentativo in 5 fasi

Metodologia per analizzare un testo argomentativo (non per dare un'opinione generica su "se piace o no"): separa ciò che è oggettivamente verificabile da ciò che è interpretazione, e sottopone la tesi a uno stress test onesto prima di giudicarla solida.

## Fase 1 — Inventario delle affermazioni verificabili

Prima di entrare nel merito, catalogare **tutto ciò che è controllabile** nel testo:
- Cifre e dati numerici
- Date ed eventi storici
- Fatti storici/cronologici
- Attribuzioni (citazioni, dichiarazioni, paternità di idee/azioni)
- Affermazioni comparative ("più di", "meno di", "a differenza di")
- Affermazioni causali ("X ha causato Y", "per via di X")
- Definizioni tecniche o di concetti

Output di questa fase: una lista numerata delle affermazioni verificabili individuate, con riferimento al punto del testo in cui compaiono. Senza questo elenco esplicito, le fasi successive diventano selettive e arbitrarie.

## Fase 2 — Verifica fattuale

Per **ciascuna** affermazione dell'inventario:
1. Cercare conferme con ricerche mirate (non genericamente "il claim sembra plausibile").
2. Privilegiare fonti primarie — bilanci, comunicati ufficiali, atti, dati istituzionali — rispetto ad aggregatori o riassunti di terzi.
3. Controllare la **precisione**, non solo la direzione: "+15%" dichiarato contro "+11%" reale è un errore anche se la direzione (crescita) è corretta.
4. Verificare il **contesto temporale**: il dato citato è ancora valido? si riferisce al periodo corretto?
5. Controllare le **attribuzioni**: la frase/idea è davvero di chi viene citato, e nel modo in cui viene citata?

Per ogni affermazione registrare l'esito: confermata / smentita / parzialmente corretta / non verificabile (e perché).

## Fase 3 — Coerenza affermazioni-evidenze

Indipendentemente dal fatto che i singoli dati siano corretti, valutare se **l'argomentazione regge sulle sue stesse basi**:
- Le tesi proposte sono effettivamente supportate dai dati citati (non solo adiacenti a essi)?
- Le evidenze portate sono **sufficienti** a sostenere la portata della conclusione, o la conclusione eccede ciò che i dati permettono di affermare?
- Esistono **contraddizioni interne** tra parti diverse del testo?
- Le **analogie** usate reggono al confronto, o sono superficiali/fuorvianti?
- Le **eccezioni** note al ragionamento vengono riconosciute e gestite, o ignorate?

## Fase 4 — Flusso logico

Analizzare la costruzione argomentativa a prescindere dal contenuto:
- **Chiarezza strutturale**: il percorso logico è seguibile? si capisce cosa sostiene cosa?
- **Salti logici**: ci sono passaggi che danno per scontato un nesso non dimostrato?
- **Ridondanze**: parti che ripetono lo stesso punto senza aggiungere forza argomentativa?
- **Coerenza conclusioni-corpo**: la conclusione discende da quanto argomentato nel corpo, o introduce elementi nuovi/più forti?
- **Proporzione tono-evidenze**: il tono (certezza, enfasi, perentorietà) è proporzionato alla qualità e quantità delle evidenze portate?

## Fase 5 — Analisi controfattuale (steelmanning)

Per **ogni argomento principale** del testo:
1. Costruire onestamente la **migliore tesi opposta possibile** — non la più debole (strawman), ma la più forte (steelman): quella che un avversario competente e in buona fede presenterebbe.
2. Valutare se l'argomento originale resiste a questo confronto.
3. Classificare l'argomento:
   - 🟢 **solido** — regge anche di fronte alla migliore controargomentazione
   - 🟡 **da rafforzare** — regge ma ha punti deboli che un oppositore competente sfrutterebbe
   - 🔴 **vulnerabile** — la controargomentazione è più convincente, o espone una falla sostanziale

Per la **tesi complessiva** del testo, fare un passo ulteriore: tentare di costruire una **contro-narrazione alternativa** che, partendo dagli **stessi fatti verificati** (fase 2), arrivi a **conclusioni diverse**. Se da quegli stessi dati è costruibile una contro-narrazione altrettanto coerente, è un segnale che la tesi originale non è l'unica spiegazione plausibile.

## Output finale

Restituire sempre un riepilogo strutturato con:
1. **Affermazioni verificate**: quante, e il loro stato (confermate / smentite / parziali / non verificabili).
2. **Problemi principali** riscontrati (fattuali, di coerenza, logici).
3. **Argomenti analizzati**, con relativa classificazione 🟢/🟡/🔴 e motivazione sintetica.
4. **Vulnerabilità rilevate**, in particolare se è stato possibile costruire una contro-narrazione alternativa coerente con gli stessi fatti.

## Anti-pattern da evitare

- Saltare l'inventario (fase 1) e iniziare a giudicare "a sensazione".
- Verificare solo la direzione di un dato ("è cresciuto") ignorando l'entità ("di quanto, esattamente?").
- Costruire uno *strawman* nella fase controfattuale invece di uno *steelman*: indebolisce l'intero esercizio e produce un falso senso di solidità.
- Giudicare la tesi complessiva sommando i singoli argomenti, senza tentare la contro-narrazione alternativa di fase 5.
- Restituire un giudizio generico ("il testo è convincente / poco convincente") invece del riepilogo strutturato richiesto in output.
