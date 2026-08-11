# Stashly

App per non lasciare "a prendere polvere" i contenuti salvati sui social — Instagram, TikTok, Pinterest e in futuro altri — raccogliendoli in un unico posto, organizzati in categorie personalizzabili.

Il problema che risolve: i "salvati" di Instagram, i preferiti di TikTok, le board di Pinterest restano isolati ognuno nella propria app, senza un modo semplice per cercarli, categorizzarli o ritrovarli a distanza di tempo. Stashly li raccoglie tutti in un unico posto che controlli tu.

## Come funziona

- **Aggiunta manuale**: incolli un link e Stashly riconosce automaticamente la piattaforma (Instagram, TikTok, Pinterest o altro).
- **Condivisione diretta**: da Instagram/TikTok/Pinterest premi "Condividi" → scegli Stashly → il link viene precompilato pronto per essere salvato, senza copia/incolla.
- **Categorie**: ogni salvato può appartenere a più categorie contemporaneamente. Le categorie sono entità persistenti (restano anche se vuote), rinominabili e con un colore personalizzabile scelto da una tavolozza.
- **Nome personalizzato**: puoi dare un titolo a ogni salvato, mostrato al posto del link nudo nella lista principale.
- **Modifica**: ogni carta salvata può essere modificata in un secondo momento (link, nome, categorie, nota).
- **Account**: l'app funziona da subito in modalità anonima (i dati restano legati al dispositivo); puoi creare un account email/password in qualsiasi momento senza perdere i salvati già fatti.
- **Aggiornamenti in-app**: l'app controlla da sola se è disponibile una versione più recente (all'avvio e su richiesta dal menu), mostrando changelog e un tasto per scaricare/installare — niente più reinstallazioni manuali.
- **Log errori**: un log locale degli errori tecnici, consultabile dal menu, utile per il debug.

## Perché esiste, filosoficamente

L'obiettivo non è duplicare o scaricare i contenuti dei social (questione di diritti d'autore e termini di servizio), ma organizzare i **link** che porteresti comunque a salvare manualmente. Stashly si limita a raccogliere metadati pubblici (link, piattaforma, categorizzazione data dall'utente) e riapre il contenuto originale nell'app di provenienza quando lo tocchi.

## Stack tecnico

- **Flutter** (Dart) — un'unica codebase pensata per Android, con supporto futuro per iOS.
- **Firebase**:
  - **Authentication** — accesso anonimo di default, upgrade a email/password mantenendo i dati.
  - **Cloud Firestore** — database dei salvati e delle categorie, sincronizzato in tempo reale.
  - **Hosting** — distribuisce il file `version.json` usato dal meccanismo di aggiornamento in-app.
- **GitHub Releases** — ospita i file APK delle build (Firebase Hosting sul piano gratuito non permette di servire file eseguibili).

## Struttura del progetto

```
lib/
  models/       # Modelli dati (SavedItem, Category)
  services/      # Logica: Firestore, autenticazione, condivisione, aggiornamenti, log errori, tema
  screens/       # Schermate: home, account, categorie, impostazioni, versione, log errori
  widgets/       # Componenti UI riutilizzabili (card, foglio di aggiunta/modifica, dialog aggiornamento)
android/         # Configurazione nativa Android (intent di condivisione, Firebase)
public/          # File pubblicati su Firebase Hosting (version.json)
apk/             # Build APK locali di riferimento (non versionate su git)
```

## Stato del progetto

In sviluppo attivo. Roadmap prevista:
- Riconoscimento automatico di titolo/anteprima dai link condivisi (oEmbed)
- Ricerca e ordinamento più avanzati
- App per iOS
- Eventuale analisi/tag automatici tramite AI

## Sviluppo locale

Progetto Flutter standard:

```bash
flutter pub get
flutter run
```

Richiede un progetto Firebase configurato (vedi `lib/firebase_options.dart`, generato con FlutterFire CLI) e le regole Firestore in `firestore.rules`.
