# Brief de cadrage — CashQuest (app iOS play-to-earn)
Date : 2026-08-01

## Contexte (C)
Application iOS type Mistplay : l'utilisateur joue à des minijeux, relève des quêtes, gagne des points (1 pt = 0,01 $) et les convertit en récompenses réelles. Monétisation par publicités AdMob. Porteur : Antoine, en solo.

## Rôle (R)
Exécutant technique : livrer un projet complet, prêt à compiler sur Mac, sans guidage pas à pas.

## Instruction (I)
Générer l'application complète (SwiftUI + Firebase Auth/Firestore + Cloud Functions) avec les vrais paiements branchés — Tango Card **Reward Link** et PayPal Payouts — en mode sandbox d'abord.

## Spécifications (S)
SwiftUI natif iOS 17+ ; 1 point = 1 centime ; plafond **100 pts (1 $) par quête** ; retrait **automatique** avec cooldown **3 h** et minimum 500 pts ; parrainage **1000 pts parrain / 500 pts filleul** ; interstitiel **tous les 2 clics** + rewarded videos bonus ; mode sombre automatique (+ clair) ; barre d'onglets personnalisable ; multilingue (FR/EN livrés, architecture extensible à toutes les langues) ; paramètres avancés.

## Pièces & exemples (P)
Référence produit : Mistplay. APIs : Tango Card RaaS v2 (Reward Link), PayPal Payouts, Firebase, AdMob. Compte Apple Developer en cours de paiement.

## Évaluation (E)
Succès = projet compilable sur Mac, flux complet fonctionnel en sandbox (jouer → gagner → retirer), puis publication App Store. Itérations au fil de l'eau, pas de nombre de cycles fixé.

## Mode de travail
- Guidage pas à pas : non (livraison directe)
- Découpage en étapes : v1 complète livrée d'un bloc, puis itérations (sandbox → production → App Store)
