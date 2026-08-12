# Stashly — Contesto di progetto

Documento di riepilogo per riprendere il lavoro su Stashly in una nuova conversazione senza dover rispiegare tutto da capo. Ultimo aggiornamento: versione app **0.5.0** (build 9).

## Modi di operare concordati con l'utente

- **Numerazione versione**: dalla release build 9 in poi, il numero di versione mostrato (`X.Y.Z` in `pubspec.yaml`) **non segue più un incremento automatico deciso da Claude**. Prima di ogni build/release, chiedere sempre all'utente quale sarà il numero della prossima versione. Il build number interno (`+N` dopo il version name) invece continua sempre a crescere in modo lineare e non va mai né riusato né diminuito, perché è quello che il meccanismo di aggiornamento in-app usa per confrontare le versioni (vedi `versionCode` in `version.json`).

## Cos'è Stashly

App Android (in futuro anche iOS) per raccogliere in un unico posto, organizzati per categoria, i contenuti salvati sui social (Instagram, TikTok, Pinterest, in futuro altri) — invece di lasciarli sparsi e dimenticati in ogni singola app.

**Filosofia**: non scarica/duplica i contenuti altrui (problemi di copyright/ToS), ma organizza i **link**. L'utente condivide un post dal social o lo aggiunge a mano, Stashly lo salva con categorie/nome/nota personalizzati, e al tap riapre il contenuto originale nell'app di provenienza.

## Dove si trova tutto

- **Codice sorgente**: `C:\Users\napol\OneDrive\Desktop\Claude\stashly`
- **Repository GitHub** (pubblico): https://github.com/napoliste95-develop/stashly
- **Progetto Firebase**: `stashly-napoli-77201` (console: https://console.firebase.google.com/project/stashly-napoli-77201)
- **Build APK locali di riferimento**: cartella `apk/` nel progetto (non versionate su git, escluse da `.gitignore`)

## Stack tecnico

- **Flutter** (Dart), SDK installato in `C:\src\flutter`
- **Android SDK**: `C:\Users\napol\AppData\Local\Android\Sdk` (via Android Studio)
- **Firebase**:
  - **Authentication** — accesso anonimo di default; l'utente può creare un account email/password in qualsiasi momento mantenendo i dati (collegamento tramite `linkWithCredential`)
  - **Cloud Firestore** — database principale (vedi struttura dati sotto)
  - **Hosting** — pubblica solo `public/version.json`, il manifest letto dall'app per il controllo aggiornamenti
- **GitHub Releases** — ospita i file APK delle build pubblicate (Firebase Hosting sul piano gratuito Spark blocca i file eseguibili come gli .apk, quindi non può ospitarli)
- **GitHub CLI** (`gh`) — autenticato come `napoliste95-develop`, usato per creare release e pubblicare l'APK come asset

## Struttura dati Firestore

```
users/{uid}/items/{itemId}
  - url: string
  - platform: 'instagram' | 'tiktok' | 'pinterest' | 'other'
  - title: string           (nome personalizzato, mostrato al posto del link)
  - categoryIds: string[]   (un item può appartenere a più categorie)
  - note: string
  - createdAt: timestamp

users/{uid}/categories/{categoryId}
  - name: string
  - color: int              (ARGB, da tavolozza fissa in lib/models/category.dart)

feedback/{feedbackId}        (collezione top-level, non per-utente)
  - type: 'bug' | 'feature'
  - message: string
  - userId: string
  - createdAt: timestamp
  # Regole: chiunque autenticato può creare, nessuno può leggere/modificare
  # (le segnalazioni si consultano solo dalla console Firebase)
```

Regole di sicurezza in `firestore.rules`: ogni utente accede solo ai propri dati sotto `users/{uid}/...`.

## Struttura del progetto Flutter

```
lib/
  models/
    saved_item.dart        # Modello SavedItem + enum SocialPlatform
    category.dart          # Modello Category + tavolozza colori fissa
  services/
    firestore_service.dart # CRUD items/categorie, migrazione dati legacy, feedback
    error_log_service.dart # Log errori locale persistito (SharedPreferences)
    theme_service.dart     # Tema chiaro/scuro/sistema persistito
    share_intent_service.dart # Riceve condivisioni da altre app (Android SEND intent)
    update_service.dart    # Controlla version.json e confronta con versione installata
    apk_installer_service.dart # Scarica l'APK e avvia l'installer di sistema
  screens/
    home_screen.dart       # Schermata principale: lista + filtro categorie + drawer
    account_screen.dart    # Login/registrazione, upgrade da anonimo
    category_management_screen.dart # Rinomina/elimina/cambia colore categorie
    settings_screen.dart   # Tema, controlla aggiornamenti, versione, log errori, feedback
    feedback_screen.dart   # Form segnalazione bug / proposta funzionalità
    error_log_screen.dart
    version_screen.dart
  widgets/
    item_card.dart         # Card di un salvato (avatar iniziale piattaforma, categorie)
    add_item_sheet.dart    # Foglio aggiunta/modifica (multi-categoria, nome, nota)
    item_sheet_helper.dart # Helper condiviso per aprire il foglio con le categorie aggiornate
    update_dialog.dart     # Dialog di aggiornamento con progress bar download+installazione
    welcome_dialog.dart    # Popup di benvenuto al primo avvio (con "non mostrare più")
android/
  app/src/main/AndroidManifest.xml
    - intent-filter per ricevere condivisioni (ACTION_SEND, text/plain)
    - permesso REQUEST_INSTALL_PACKAGES (per installare l'APK scaricato in-app)
  app/build.gradle.kts: compileSdk = 37 (richiesto da receive_sharing_intent)
public/
  version.json            # {versionCode, version, apkUrl, changelog} — pubblicato su Firebase Hosting
firestore.rules
firestore.indexes.json
firebase.json             # Config Hosting (public/) + Firestore rules/indexes
```

## Funzionalità implementate (in ordine cronologico)

1. **Salvataggio manuale**: link + categoria + nota, riconoscimento automatico piattaforma dall'URL
2. **Sincronizzazione Firebase** con autenticazione anonima
3. **Condivisione diretta** da Instagram/TikTok/Pinterest tramite il menu "Condividi" di Android
4. **Menu laterale**: Account, Gestisci categorie, Impostazioni
5. **Account**: login/registrazione email+password, upgrade da anonimo senza perdere i dati
6. **Avatar piattaforma**: cerchio colorato con iniziale (I/T/P) invece di icone generiche
7. **Modifica salvati** esistenti (non solo aggiunta)
8. **Categorie persistenti**: entità vere in Firestore (restano anche se vuote), non più dedotte al volo dagli item
9. **Multi-categoria**: un salvato può appartenere a più categorie contemporaneamente
10. **Colori categoria personalizzabili**, sempre univoci tra categorie diverse (tavolozza fissa, colori già usati disabilitati nel selettore)
11. **Nome personalizzato** per ogni salvato (mostrato al posto del link nudo)
12. **Bug fix**: il drawer ora resta "aperto sotto" quando si naviga in una sezione, così tornando indietro lo si ritrova aperto
13. **Aggiornamenti in-app**:
    - v1 (basato su browser): `version.json` + link diretto aperto con `url_launcher`
    - v2 (attuale): download dell'APK dentro l'app con barra di progresso (`http` + `path_provider`) e avvio automatico dell'installer di sistema (`open_filex`), senza aprire il browser
14. **Impostazioni consolidate**: tema, controlla aggiornamenti, versione, log errori, feedback tutti in un'unica schermata (drawer semplificato)
15. **Form di feedback**: segnalazione bug o proposta funzionalità, salvata su Firestore (collezione `feedback`, scrivibile ma non leggibile dal client)
16. **Popup di benvenuto** al primo avvio, con checkbox "non mostrare più" (persistito via `SharedPreferences`)
17. **Rinumerazione versioni**: da schema 1.x a schema 0.x (l'app è considerata ancora in sviluppo attivo, pre-1.0); il build number interno (versionCode) continua comunque a crescere in modo continuo per non rompere il meccanismo di aggiornamento
18. **Bug fix critico — sessioni multiple**: `android:launchMode="singleTop"` combinato con `android:taskAffinity=""` nel `AndroidManifest.xml` faceva sì che Android creasse un nuovo "task" separato (visibile come sessione/scheda duplicata nel multitasking) ogni volta che l'app veniva aperta da un punto di ingresso diverso (icona, condivisione da altra app). Corretto impostando `launchMode="singleTask"` e rimuovendo `taskAffinity=""`, così tutte le aperture condividono lo stesso task/istanza.
19. **Gestione categorie**: aggiunto pulsante "+" nell'AppBar per creare una categoria direttamente da questa schermata (non solo dal foglio di aggiunta salvato), e contatore "N salvati" per ogni categoria (calcolato incrociando lo stream degli item con `categoryIds`)
20. **Rinumerazione versione**: riportata a schema 0.5.0 su richiesta esplicita dell'utente (non un errore — vedi "Modi di operare concordati" sopra)

## Come funziona il rilascio di una nuova versione

Procedura seguita ad ogni modifica (da ripetere identica in futuro):

1. Modificare il codice, verificare con `flutter analyze`
2. Incrementare `version:` in `pubspec.yaml` (formato `X.Y.Z+N`, dove N è il build number progressivo — **non va mai riusato o diminuito**)
3. Build: `flutter build apk --release` (richiede le variabili d'ambiente per il truststore custom, vedi sotto)
4. Copiare l'APK in `apk/stashly-vX.Y.Z.apk`
5. Creare una release GitHub: `gh release create vX.Y.Z apk/stashly-vX.Y.Z.apk --title "Stashly vX.Y.Z" --notes "..."`
6. Aggiornare `public/version.json` con `versionCode`, `version`, `apkUrl` (puntando all'asset della release appena creata) e `changelog`
7. Deploy: `firebase deploy --only hosting --project stashly-napoli-77201`
8. Commit e push su GitHub del codice sorgente

L'app installata controlla `version.json` all'avvio (banner automatico) e su richiesta (Impostazioni → Controlla aggiornamenti), scarica l'APK e avvia l'installazione da sola.

## Note tecniche e workaround dell'ambiente di sviluppo (Windows)

Problemi incontrati durante il setup, utili se si ripresenta la stessa macchina/ambiente:

- **Antivirus AVG** intercetta il traffico HTTPS (SSL/TLS scanning) con un certificato proprio, non incluso nel truststore separato della JVM di Android Studio → le build Gradle fallivano con `PKIX path building failed`. Workaround: copiato il certificato radice AVG in un truststore Java personalizzato (`C:\temp_certs\cacerts_custom`), usato impostando la variabile d'ambiente `JAVA_TOOL_OPTIONS` prima di ogni build:
  ```
  JAVA_TOOL_OPTIONS=-Djavax.net.ssl.trustStore=C:\temp_certs\cacerts_custom -Djavax.net.ssl.trustStorePassword=changeit
  ```
- **Spazio su disco**: le build Gradle/Android SDK richiedono diversi GB liberi; con meno di ~5GB liberi falliscono in modo poco chiaro (es. installazione NDK corrotta a metà). Se ricompare un errore tipo `NDK ... did not have a source.properties file`, di solito basta cancellare la cartella NDK parzialmente scaricata in `Android/Sdk/ndk/` e rilanciare la build.
- **compileSdk**: impostato manualmente a `37` in `android/app/build.gradle.kts` (richiesto dal plugin `receive_sharing_intent`, superiore al default generato da Flutter).
- **Modalità sviluppatore Windows**: necessaria per i symlink creati da Flutter durante la build dei plugin (Impostazioni → Privacy e sicurezza → Per sviluppatori).
- **Repository GitHub pubblico**: reso pubblico deliberatamente (non conteneva segreti reali, solo config Firebase client-side già protetta dalle security rules) per permettere il download diretto degli APK dal telefono senza login.

## Prossimi passi possibili (non ancora fatti)

- Riconoscimento automatico di titolo/anteprima dai link condivisi (oEmbed di Instagram/TikTok/Pinterest)
- Ricerca testuale tra i salvati
- App per iOS (stesso codice Flutter, richiede Apple Developer Account e configurazione separata)
- Eventuale tagging/categorizzazione automatica via AI
- Rendere il README più curato con screenshot
