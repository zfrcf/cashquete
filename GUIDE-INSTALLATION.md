# CashQuest — Guide d'installation pas à pas (Mac)

Ordre conseillé : **0. Mac → 1. Firebase → 2. Tango Card → 3. PayPal → 4. Secrets + déploiement → 5. Config Firestore → 6. Compiler l'app → 7. Test de bout en bout → 8. Passage en production**

---

## 0. Préparer le Mac

1. Installer **Xcode 16+** depuis le Mac App Store (long : ~10 Go). L'ouvrir une fois pour accepter la licence et installer les composants iOS.
2. Installer Homebrew (dans Terminal) :
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
3. Installer les outils :
   ```bash
   brew install xcodegen node
   npm install -g firebase-tools
   ```
4. Transférer le dossier `CashQuest` du PC Windows vers le Mac (clé USB, AirDrop depuis un zip, ou dépôt Git privé). Le poser par ex. dans `~/Dev/CashQuest`.

---

## 1. Firebase

### 1.1 Créer le projet
1. Va sur [console.firebase.google.com](https://console.firebase.google.com) (connecté avec ton compte Google).
2. **Ajouter un projet** → nom : `cashquest` → Google Analytics : facultatif (tu peux dire non) → Créer.

### 1.2 Passer au plan Blaze (obligatoire)
1. Dans la console, en bas à gauche : **Forfait Spark → Passer à la version supérieure → Blaze**.
2. Associe une carte bancaire. Blaze est **payant à l'usage mais quasi gratuit à petit volume** (les functions et Firestore ont un palier gratuit généreux). Il est requis pour : Cloud Functions + appels réseau sortants vers PayPal/Tango.
3. Conseil : configure une **alerte de budget** (ex. 25 €/mois) dans les paramètres de facturation.

### 1.3 Activer l'authentification
1. Menu **Création → Authentication → Commencer**.
2. Onglet **Sign-in method** → **Adresse e-mail/Mot de passe** → Activer → Enregistrer.

### 1.4 Créer Firestore
1. Menu **Création → Firestore Database → Créer une base de données**.
2. Emplacement : **nam5 (États-Unis)** — pour rester proche des functions (`us-central1`). Valide.
3. Mode : **production** (les règles seront déployées à l'étape 4).

### 1.5 Déclarer l'app iOS
1. Page d'accueil du projet → icône **iOS+**.
2. Bundle ID : `com.antoine.cashquest` (exactement).
3. Télécharge **GoogleService-Info.plist** et **remplace** le fichier placeholder dans `CashQuest/CashQuest/GoogleService-Info.plist`.
4. Ignore les étapes "Ajouter le SDK" proposées par l'assistant (déjà fait dans le projet) — clique juste "Suivant" jusqu'à la fin.

### 1.6 Lier le CLI au projet
```bash
cd ~/Dev/CashQuest/firebase
firebase login                 # ouvre le navigateur
firebase use --add             # choisis le projet cashquest, alias "default"
cd functions && npm install && cd ..
```

---

## 2. Tango Card (Reward Link)

### 2.1 Compte sandbox (gratuit, immédiat pour tester)
1. Va sur [developers.tangocard.com](https://developers.tangocard.com) → inscription développeur / demande d'accès sandbox.
2. Tu obtiens un **platformName** et une **platformKey** de test (environnement `integration-api.tangocard.com`). Note-les.

### 2.2 Créer customer + account (une seule fois, via curl)
Remplace `NAME:KEY` par tes identifiants sandbox :
```bash
# Créer un "customer" (ton entreprise)
curl -u NAME:KEY -H "Content-Type: application/json" \
  -d '{"customerIdentifier":"cashquest","displayName":"CashQuest"}' \
  https://integration-api.tangocard.com/raas/v2/customers

# Créer un "account" (le portefeuille qui paie les récompenses)
curl -u NAME:KEY -H "Content-Type: application/json" \
  -d '{"accountIdentifier":"cashquest-main","displayName":"CashQuest Main","contactEmail":"antoine.fleau@gmail.com"}' \
  https://integration-api.tangocard.com/raas/v2/customers/cashquest/accounts
```
→ `TANGO_CUSTOMER_IDENTIFIER` = `cashquest`, `TANGO_ACCOUNT_IDENTIFIER` = `cashquest-main`.
En sandbox, le solde est fictif ; si une commande échoue pour solde insuffisant, utilise l'endpoint de dépôt test (`/creditCardDeposits` avec la carte de test fournie par la doc Tango).

### 2.3 Trouver l'UTID du Reward Link
```bash
curl -u NAME:KEY https://integration-api.tangocard.com/raas/v2/catalogs?verbose=true > catalog.json
grep -B4 -A4 -i "reward link" catalog.json
```
Note le champ **`utid`** de l'item « Reward Link » (commence par `U`). Tu le mettras dans `config/app → tangoUtid` (étape 5).

### 2.4 Production (plus tard)
- Demander un compte **RaaS production** (validation entreprise + contrat).
- **Provisionner de vrais fonds** (virement/ACH) : chaque Reward Link envoyé débite ce solde.
- Basculer `tangoSandbox: false` dans `config/app`.

---

## 3. PayPal (Payouts)

### 3.1 Créer l'app sandbox
1. Va sur [developer.paypal.com](https://developer.paypal.com) → connexion avec ton compte PayPal → **Dashboard**.
2. **Apps & Credentials** → environnement **Sandbox** → **Create App** → nom `cashquest`.
3. Dans les fonctionnalités de l'app, coche **Payouts** si demandé.
4. Note le **Client ID** et le **Secret**.

### 3.2 Comptes de test
1. Menu **Testing Tools → Sandbox Accounts** : PayPal a créé un compte **Business** (l'émetteur, avec un solde fictif) et un **Personal** (le destinataire).
2. Note l'e-mail du compte **Personal** : c'est lui que tu saisiras comme destinataire dans l'app pour tester un retrait.
3. Tu peux vérifier la réception sur [sandbox.paypal.com](https://www.sandbox.paypal.com) avec les identifiants du compte Personal (mot de passe visible dans Sandbox Accounts → ⋯ → View/Edit).

### 3.3 Production (plus tard)
- Créer une app **Live** (mêmes écrans, onglet Live) → nouveaux Client ID/Secret à remettre dans les secrets Firebase.
- **Payouts en live doit être activé par PayPal** : compte Business vérifié + formulaire d'activation Payouts (délai de quelques jours). Les paiements partent de **ton solde PayPal** — il doit être approvisionné.
- Basculer `paypalSandbox: false` dans `config/app`.

---

## 4. Secrets + déploiement du backend

```bash
cd ~/Dev/CashQuest/firebase

firebase functions:secrets:set TANGO_PLATFORM_NAME        # colle le platformName sandbox
firebase functions:secrets:set TANGO_PLATFORM_KEY         # colle la platformKey
firebase functions:secrets:set TANGO_ACCOUNT_IDENTIFIER   # cashquest-main
firebase functions:secrets:set TANGO_CUSTOMER_IDENTIFIER  # cashquest
firebase functions:secrets:set PAYPAL_CLIENT_ID           # Client ID sandbox
firebase functions:secrets:set PAYPAL_CLIENT_SECRET       # Secret sandbox

firebase deploy        # déploie règles Firestore + les 6 functions
```
Au premier déploiement, le CLI peut demander d'activer des APIs Google Cloud (Artifact Registry, Cloud Build…) : réponds oui. Compte 2-5 min.

---

## 5. Document de configuration Firestore

Console Firebase → **Firestore Database** → **Démarrer une collection** :
- Collection : `config` → Document : `app`
- Champs (au minimum) :

| Champ | Type | Valeur |
|---|---|---|
| `tangoUtid` | string | l'UTID Reward Link trouvé en 2.3 |
| `tangoSandbox` | boolean | `true` |
| `paypalSandbox` | boolean | `true` |

Tous les autres réglages (valeur du point, plafond 1 $/quête, cooldown 3 h, parrainage, fréquence des pubs…) ont des valeurs par défaut dans le code et peuvent être ajoutés ici plus tard pour les modifier **sans redéployer**.

---

## 6. Compiler l'app

```bash
cd ~/Dev/CashQuest
xcodegen generate
open CashQuest.xcodeproj
```
Dans Xcode :
1. Cible **CashQuest → Signing & Capabilities** → coche *Automatically manage signing* → sélectionne ta **Team** (ton compte Apple Developer).
2. Choisis un simulateur (iPhone 16) ou ton iPhone branché → **⌘R**.

Premier lancement : crée un compte e-mail/mot de passe → le document utilisateur apparaît dans Firestore (`users/…`) avec ton code de parrainage.

---

## 7. Test de bout en bout (sandbox)

1. **Quête** : joue au Quiz → l'écran de fin affiche les points → le solde du Dashboard se met à jour en direct.
2. **Pub** : les interstitiels de test Google apparaissent tous les 2 clics ; la rewarded video crédite le bonus.
3. **Parrainage** : crée un 2ᵉ compte (déconnexion → inscription), entre le code du 1ᵉʳ → +500 pts immédiats ; joue une quête avec le 2ᵉ compte → le 1ᵉʳ reçoit +1000 pts.
4. **Retrait PayPal** : accumule ≥ 500 pts → onglet Retrait → PayPal → e-mail du compte sandbox **Personal** → le statut passe à `paid` → vérifie le solde sur sandbox.paypal.com.
5. **Retrait Reward Link** : même chose avec « Reward Link » → statut `paid` + `providerRef` dans Firestore ; en sandbox l'e-mail n'est pas toujours réellement envoyé, vérifie la commande : `curl -u NAME:KEY https://integration-api.tangocard.com/raas/v2/orders`.
6. **Cooldown** : tente un 2ᵉ retrait tout de suite → refus « Un seul retrait toutes les 3 heures » + compte à rebours affiché.

---

## 8. Checklist passage en production

- [ ] Compte **AdMob** : créer l'app iOS, remplacer les IDs de test dans `Core/AdManager.swift` + `GADApplicationIdentifier` dans `project.yml` (puis `xcodegen generate` à nouveau)
- [ ] Consentement pubs UE (SDK **UMP**) + écran ATT — requis par Apple/AdMob
- [ ] **App Check** (protège les Cloud Functions contre les scripts)
- [ ] Comptes Tango **production** (financé) et PayPal **Live** (Payouts activé) → mettre à jour les 6 secrets → `firebase deploy`
- [ ] `config/app` : `tangoSandbox: false`, `paypalSandbox: false`, et **réduire les montants de parrainage** tant que les revenus pubs ne suivent pas
- [ ] Icône d'app + politique de confidentialité (URL exigée par l'App Store)
- [ ] Soumission App Store — risque de rejet sur les pubs trop fréquentes : si rejet, augmente `interstitialTapInterval` à distance et re-soumets
