# CashQuest — App iOS play-to-earn

Minijeux → points (1 pt = 0,01 $) → retraits réels via **PayPal Payouts** ou **Tango Card Reward Link** (l'utilisateur choisit sa carte cadeau via un lien reçu par e-mail).

## Arborescence

```
CashQuest/
├── project.yml                  ← définition du projet Xcode (XcodeGen)
├── CashQuest/                   ← code SwiftUI (app iOS 17+)
│   ├── App/                     ← point d'entrée, thème, navigation personnalisable
│   ├── Core/                    ← Auth, Firestore temps réel, AdMob (pub tous les 2 clics)
│   ├── Views/                   ← Dashboard, 3 minijeux, Parrainage, Retrait, Réglages
│   ├── Localizable.xcstrings    ← traductions (FR + EN livrés, extensible)
│   └── GoogleService-Info.plist ← PLACEHOLDER à remplacer
└── firebase/
    ├── firestore.rules          ← le client ne peut JAMAIS modifier son solde
    └── functions/index.js       ← quêtes, parrainage, retraits, payouts
```

## Prérequis

- Un **Mac** avec Xcode 16+ (la compilation iOS est impossible sur Windows)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) : `brew install xcodegen`
- Node 20 + [Firebase CLI](https://firebase.google.com/docs/cli) : `npm i -g firebase-tools`
- Compte Apple Developer actif (99 $/an)

## Étape 1 — Firebase

1. Créer un projet sur [console.firebase.google.com](https://console.firebase.google.com), passer au plan **Blaze** (requis pour les Cloud Functions et les appels sortants vers PayPal/Tango).
2. Activer **Authentication → E-mail/mot de passe** et **Cloud Firestore**.
3. Ajouter une app iOS (bundle `com.antoine.cashquest`), télécharger `GoogleService-Info.plist` et **remplacer** le placeholder dans `CashQuest/`.

## Étape 2 — Secrets et déploiement du backend

```bash
cd firebase
firebase login && firebase use <ton-projet>
firebase functions:secrets:set TANGO_PLATFORM_NAME
firebase functions:secrets:set TANGO_PLATFORM_KEY
firebase functions:secrets:set TANGO_ACCOUNT_IDENTIFIER
firebase functions:secrets:set TANGO_CUSTOMER_IDENTIFIER
firebase functions:secrets:set PAYPAL_CLIENT_ID
firebase functions:secrets:set PAYPAL_CLIENT_SECRET
cd functions && npm install && cd ..
firebase deploy
```

- **Tango Card** : compte sandbox gratuit sur [developers.tangocard.com](https://developers.tangocard.com). Récupérer l'**UTID du produit "Reward Link"** dans ton catalogue (`GET /catalogs`) et le mettre dans `config/app.tangoUtid` (Firestore). En production il faudra un compte RaaS approuvé **et provisionné en fonds**.
- **PayPal** : app REST sur [developer.paypal.com](https://developer.paypal.com), activer **Payouts** (nécessite une validation business en production, et un solde suffisant).

## Étape 3 — Configuration ajustable sans redéployer

Créer le document Firestore `config/app` (tout est optionnel, valeurs par défaut sinon) :

| Champ | Défaut | Rôle |
|---|---|---|
| `pointValueUSD` | 0.01 | valeur d'un point |
| `maxQuestRewardPoints` | 100 | **plafond 1 $ par quête** |
| `minWithdrawalPoints` | 500 | retrait minimum (5 $) |
| `withdrawalCooldownHours` | 3 | un retrait max toutes les 3 h |
| `referralReferrerPoints` / `referralInviteePoints` | 1000 / 500 | parrainage |
| `interstitialTapInterval` | 2 | pub interstitielle tous les N clics |
| `rewardedAdPoints` | 10 | bonus par rewarded video |
| `gameCooldownMinutes` | 15 | pause entre deux parties d'un même jeu |
| `tangoUtid` | — | UTID Reward Link de ton catalogue |
| `tangoSandbox` / `paypalSandbox` | true | passer à `false` en production |

## Étape 4 — Générer et compiler l'app (sur Mac)

```bash
cd CashQuest        # dossier racine du projet
xcodegen generate
open CashQuest.xcodeproj
```

Sélectionner ta team de signing, puis ⌘R. Les publicités utilisent les **IDs de test Google** — remplacer dans `Core/AdManager.swift` et `project.yml` (`GADApplicationIdentifier`) par tes vrais IDs AdMob avant publication.

## ⚠️ Avertissements importants

1. **Économie à surveiller de près.** Un interstitiel rapporte ~0,005–0,02 $. Le parrainage paie actuellement **15 $ de valeur réelle** par couple parrain/filleul (1000 + 500 pts) : c'est très supérieur à ce que la pub rapportera au début. Ces montants sont ajustables dans `config/app` sans mise à jour de l'app — commence bas, augmente si les revenus suivent.
2. **Risque App Store.** Apple est stricte avec les apps qui rémunèrent l'utilisateur et avec les pubs très fréquentes (un interstitiel tous les 2 clics peut motiver un rejet). Prévois un plan B : espacer les pubs (`interstitialTapInterval`) et mettre en avant les rewarded videos, mieux tolérées et 5-10× plus rentables.
3. **Anti-triche minimal.** Le serveur plafonne chaque quête à 1 $, impose des cooldowns et contrôle tout le solde, mais le **score est envoyé par le client** (falsifiable). Perte max ≈ 4-5 $/h/utilisateur. Avant l'échelle : App Check, Server-Side Verification AdMob, validation manuelle des premiers retraits d'un compte.
4. **Légal.** Verser de l'argent réel implique : mentions légales, politique de confidentialité (exigée par Apple + AdMob), RGPD/consentement pubs (UMP SDK à ajouter), et selon les volumes des obligations fiscales. À vérifier avant le lancement public.
5. **Langues.** FR et EN sont traduits. « Toutes les langues » = ajouter des traductions dans `Localizable.xcstrings` (Xcode peut assister) ; l'app bascule déjà automatiquement selon la langue du téléphone, et un sélecteur manuel existe dans Réglages.
6. **Icône d'app** : aucune incluse — à ajouter dans Xcode avant soumission.
