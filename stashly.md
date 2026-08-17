# Stashly — Contesto di progetto

Documento di riepilogo per riprendere il lavoro su Stashly in una nuova conversazione senza dover rispiegare tutto da capo. Ultimo aggiornamento: versione app **0.6.2** (build 16).

## Modi di operare concordati con l'utente

- **Numerazione versione**: il numero mostrato (`X.Y.Z` in `pubspec.yaml`) non segue un incremento automatico deciso da Claude — chiedere sempre all'utente quale sarà la prossima versione prima di ogni build/release. Il build number interno (`+N`) invece cresce sempre in modo lineare e non va mai riusato né diminuito (è quello che l'aggiornamento in-app usa per confrontare le versioni, vedi `versionCode` in `version.json`).

## Cos'è Stashly

App Android (in futuro anche iOS) per raccogliere in un unico posto, organizzati per categoria, i contenuti salvati sui social — invece di lasciarli sparsi e dimenticati in ogni singola app.

**Filosofia**: non scarica/duplica i contenuti altrui (problemi di copyright/ToS), ma organizza i **link**. L'utente condivide un post dal social o lo aggiunge a mano, Stashly lo salva con categorie/nome/nota personalizzati, e al tap riapre il contenuto originale nell'app di provenienza.

## Dove si trova tutto

- **Codice sorgente**: `C:\Users\napol\OneDrive\Desktop\Claude\stashly`
- **Repository GitHub** (pubblico): https://github.com/napoliste95-develop/stashly
- **Progetto Firebase**: `stashly-napoli-77201` (console: https://console.firebase.google.com/project/stashly-napoli-77201)
- **Build APK locali di riferimento**: cartella `apk/` nel progetto (non versionate su git)

## Stack tecnico

- **Flutter** (Dart), SDK in `C:\src\flutter`
- **Android SDK**: `C:\Users\napol\AppData\Local\Android\Sdk` (via Android Studio)
- **Firebase**: Authentication (anonimo di default, upgrade a email/password senza perdere dati), Cloud Firestore (database principale), Hosting (pubblica solo `public/version.json` per il controllo aggiornamenti)
- **GitHub Releases** — ospita gli APK delle build (Firebase Hosting sul piano gratuito Spark non può servire eseguibili)
- **GitHub CLI** (`gh`) — autenticato come `napoliste95-develop`

## Struttura dati Firestore

```
users/{uid}/items/{itemId}
  - url: string
  - platform: 'instagram' | 'tiktok' | 'pinterest' | 'youtube' | 'x' | 'facebook' | 'reddit' | 'threads' | 'twitch' | 'other'
  - title: string           (nome personalizzato, mostrato al posto del link)
  - categoryIds: string[]   (un item può appartenere a più categorie)
  - note: string
  - createdAt: timestamp
  - seenAt: timestamp | null   (null = mai aperto dall'utente; impostato al tap)

users/{uid}/categories/{categoryId}
  - name: string
  - color: int              (ARGB, da tavolozza fissa in lib/models/category.dart)

feedback/{feedbackId}        (collezione top-level, non per-utente)
  - type: 'bug' | 'feature'
  - message: string
  - userId: string
  - createdAt: timestamp
  # Regole: chiunque autenticato può creare, nessuno può leggere/modificare
```

Regole di sicurezza in `firestore.rules`: ogni utente accede solo ai propri dati sotto `users/{uid}/...`.

## Struttura del progetto Flutter

```
lib/
  models/
    saved_item.dart        # Modello SavedItem + enum SocialPlatform (9 piattaforme + 'altro')
    category.dart          # Modello Category + tavolozza colori fissa
  services/
    firestore_service.dart # CRUD items/categorie, migrazione dati legacy, feedback
    error_log_service.dart # Log errori locale persistito (SharedPreferences)
    theme_service.dart     # Tema chiaro/scuro/sistema persistito
    share_intent_service.dart # Riceve condivisioni da altre app (Android SEND intent)
    update_service.dart    # Controlla version.json e confronta con versione installata
    apk_installer_service.dart # Scarica l'APK e avvia l'installer di sistema
    notification_service.dart  # Promemoria settimanale locale (workmanager + flutter_local_notifications)
  screens/
    home_screen.dart       # Schermata principale: lista/griglia + filtro categorie + ricerca/ordina + drawer
    account_screen.dart    # Login/registrazione, upgrade da anonimo
    category_management_screen.dart # Card colorate, swipe per rinominare/eliminare
    settings_screen.dart   # Tema, promemoria, controlla aggiornamenti, versione, log errori, feedback
    feedback_screen.dart   # Form segnalazione bug / proposta funzionalità
    error_log_screen.dart
    version_screen.dart
  widgets/
    item_card.dart         # ItemCard (lista) + ItemGridTile (griglia), icone brand reali per piattaforma
    add_item_sheet.dart    # Foglio aggiunta/modifica (multi-categoria, nome, nota)
    item_sheet_helper.dart # Helper condiviso per aprire il foglio con le categorie aggiornate
    update_dialog.dart     # Dialog di aggiornamento con progress bar download+installazione
    welcome_dialog.dart    # Popup di benvenuto al primo avvio (con "non mostrare più")
android/
  app/src/main/AndroidManifest.xml
    - intent-filter per ricevere condivisioni (ACTION_SEND, text/plain)
    - permessi REQUEST_INSTALL_PACKAGES, POST_NOTIFICATIONS
    - launchMode="singleTask" (evita sessioni/task duplicati aprendo l'app da punti diversi)
  app/build.gradle.kts: compileSdk = 37, core library desugaring abilitato (richiesti da receive_sharing_intent e flutter_local_notifications)
public/
  version.json            # {versionCode, version, apkUrl, changelog} — pubblicato su Firebase Hosting
scripts/
  generate_notification_icon.ps1  # Rigenera l'icona monocroma di notifica (System.Drawing)
firestore.rules
firestore.indexes.json
firebase.json             # Config Hosting (public/) + Firestore rules/indexes
```

## Funzionalità principali

**Salvataggio e organizzazione**
- Aggiunta manuale (link + nome + nota + categorie) o condivisione diretta da altre app, con riconoscimento automatico della piattaforma dall'URL
- Categorie persistenti multi-selezione, colore personalizzabile da tavolozza fissa (sempre univoco tra categorie), gestibili in una schermata dedicata con card colorate e swipe per rinominare/eliminare (conferma richiesta per l'eliminazione)
- Home con ricerca testuale, ordinamento (data/nome/piattaforma) e scelta tra vista a lista e vista a griglia (preferenza ricordata)
- Tracking "visto/non visto" per ogni salvato (si aggiorna al tap), usato dal promemoria settimanale

**Account e sincronizzazione**
- Accesso anonimo di default; upgrade a email/password in qualsiasi momento senza perdere i dati, sincronizzazione realtime via Firestore

**Notifiche**
- Promemoria settimanale locale (no backend) dei salvati mai aperti, attivo di default, configurabile/disattivabile da Impostazioni (giorno/ora), saltato se il conteggio è zero
- **Rischio noto**: la consegna non è garantita al minuto (Doze mode, risparmio energetico OEM aggressivo) — segnalato in UI

**Aggiornamenti in-app**
- L'app controlla `version.json` all'avvio e su richiesta, scarica l'APK e avvia l'installazione da sola (con retry automatico su reti instabili)

**Altro**
- Tema chiaro/scuro/sistema, log errori locale consultabile, form di feedback (bug/proposte) su Firestore, popup di benvenuto al primo avvio
- Icona app personalizzata (S rossa su nero); nome "Stashly" ancora provvisorio

## Come funziona il rilascio di una nuova versione

1. Modificare il codice, verificare con `flutter analyze` (e `flutter test`)
2. Incrementare `version:` in `pubspec.yaml` (formato `X.Y.Z+N`, N progressivo, mai riusato/diminuito)
3. Build: `flutter build apk --release` (richiede `JAVA_TOOL_OPTIONS`, vedi sotto)
4. Copiare l'APK in `apk/stashly-vX.Y.Z.apk`
5. `gh release create vX.Y.Z apk/stashly-vX.Y.Z.apk --title "Stashly vX.Y.Z" --notes "..."`
6. Aggiornare `public/version.json` (versionCode, version, apkUrl, changelog)
7. `firebase deploy --only hosting --project stashly-napoli-77201`
8. Commit e push su GitHub

## Note tecniche e workaround dell'ambiente di sviluppo (Windows)

- **Antivirus AVG** intercetta l'HTTPS (SSL/TLS scanning) con un certificato proprio → build Gradle falliscono con `PKIX path building failed`. Fix: certificato AVG importato in un truststore Java personalizzato, usato impostando prima di ogni build:
  ```
  JAVA_TOOL_OPTIONS=-Djavax.net.ssl.trustStore=C:\temp_certs\cacerts_custom -Djavax.net.ssl.trustStorePassword=changeit
  ```
- **Spazio su disco**: servono diversi GB liberi per le build Gradle/Android SDK; sotto ~5GB falliscono in modo poco chiaro (es. NDK corrotto a metà — cancellare la cartella parziale in `Android/Sdk/ndk/` e rilanciare).
- **Modalità sviluppatore Windows** necessaria per i symlink creati da Flutter durante la build dei plugin.
- **Repository GitHub pubblico** deliberatamente (nessun segreto reale, solo config Firebase client-side già protetta dalle security rules) per permettere il download diretto degli APK dal telefono.

## Prossimi passi possibili (non ancora fatti)

- Riconoscimento automatico di titolo/anteprima dai link condivisi (oEmbed)
- App per iOS (stesso codice Flutter, richiede Apple Developer Account e configurazione separata)
- Eventuale tagging/categorizzazione automatica via AI
- Rendere il README più curato con screenshot
