const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const functionsV1 = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const { FieldValue } = admin.firestore;

setGlobalOptions({ region: "us-central1", maxInstances: 10 });

// Secrets : firebase functions:secrets:set NOM_DU_SECRET
const TANGO_PLATFORM_NAME = defineSecret("TANGO_PLATFORM_NAME");
const TANGO_PLATFORM_KEY = defineSecret("TANGO_PLATFORM_KEY");
const TANGO_ACCOUNT_IDENTIFIER = defineSecret("TANGO_ACCOUNT_IDENTIFIER");
const TANGO_CUSTOMER_IDENTIFIER = defineSecret("TANGO_CUSTOMER_IDENTIFIER");
const PAYPAL_CLIENT_ID = defineSecret("PAYPAL_CLIENT_ID");
const PAYPAL_CLIENT_SECRET = defineSecret("PAYPAL_CLIENT_SECRET");

// Valeurs par défaut — surchargées par le document Firestore config/app
const DEFAULTS = {
  pointValueUSD: 0.01,
  minWithdrawalPoints: 500,
  withdrawalCooldownHours: 3,
  maxQuestRewardPoints: 100, // plafond 1 $ par quête
  rewardedAdPoints: 10,
  interstitialTapInterval: 2,
  referralInviteePoints: 500,
  referralReferrerPoints: 1000,
  gameCooldownMinutes: 15,
  rewardedAdCooldownSeconds: 60,
  // UTID du produit "Reward Link" dans TON catalogue Tango (voir README)
  tangoUtid: "REPLACE_WITH_REWARD_LINK_UTID",
  tangoSandbox: true,
  paypalSandbox: true,
};

const GAMES = ["quiz", "memory", "reflex", "2048"];

async function getConfig() {
  const snap = await db.doc("config/app").get();
  return { ...DEFAULTS, ...(snap.exists ? snap.data() : {}) };
}

function requireAuth(req) {
  if (!req.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
  return req.auth.uid;
}

function addTx(tx, uid, type, points, label) {
  const ref = db.doc(`users/${uid}`).collection("transactions").doc();
  tx.set(ref, { type, points, label, createdAt: FieldValue.serverTimestamp() });
}

// ---------------------------------------------------------------------------
// Cycle de vie du compte
// ---------------------------------------------------------------------------

exports.onUserCreated = functionsV1.auth.user().onCreate(async (user) => {
  const cleaned = user.uid.replace(/[^a-zA-Z0-9]/g, "");
  const code = (cleaned.slice(0, 6) || "CQ" + user.uid.length).toUpperCase();
  await db.doc(`users/${user.uid}`).set({
    email: user.email || "",
    displayName: user.displayName || "Player",
    points: 0,
    totalEarnedPoints: 0,
    questCount: 0,
    referralCode: code,
    referredBy: null,
    referralAwarded: false,
    lastWithdrawalAt: null,
    createdAt: FieldValue.serverTimestamp(),
  });
});

exports.onUserDeleted = functionsV1.auth.user().onDelete(async (user) => {
  await db.recursiveDelete(db.doc(`users/${user.uid}`));
});

// ---------------------------------------------------------------------------
// Quêtes — le serveur décide de la récompense, jamais le client
// ---------------------------------------------------------------------------

exports.completeQuest = onCall(async (req) => {
  const uid = requireAuth(req);
  const gameId = String(req.data?.gameId || "");
  const score = Number(req.data?.score);
  if (!GAMES.includes(gameId) || !Number.isFinite(score) || score < 0 || score > 10000) {
    throw new HttpsError("invalid-argument", "Paramètres invalides.");
  }

  const cfg = await getConfig();
  const points = Math.min(Math.round(score), cfg.maxQuestRewardPoints);
  const userRef = db.doc(`users/${uid}`);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) throw new HttpsError("not-found", "Profil introuvable.");
    const user = snap.data();

    const lastKey = `lastPlayed_${gameId}`;
    const last = user[lastKey] ? user[lastKey].toMillis() : 0;
    if (Date.now() - last < cfg.gameCooldownMinutes * 60000) {
      throw new HttpsError("failed-precondition", "Ce jeu est en pause, reviens un peu plus tard !");
    }

    tx.update(userRef, {
      points: FieldValue.increment(points),
      totalEarnedPoints: FieldValue.increment(points),
      questCount: FieldValue.increment(1),
      [lastKey]: FieldValue.serverTimestamp(),
    });
    addTx(tx, uid, "quest", points, gameId);
  });

  await maybeAwardReferrer(uid, cfg);
  return { points };
});

// Le parrain est payé quand le filleul termine sa première quête (anti-abus)
async function maybeAwardReferrer(uid, cfg) {
  const userRef = db.doc(`users/${uid}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    const user = snap.data() || {};
    if (!user.referredBy || user.referralAwarded) return;

    const referrerRef = db.doc(`users/${user.referredBy}`);
    const referrerSnap = await tx.get(referrerRef);
    tx.update(userRef, { referralAwarded: true });
    if (!referrerSnap.exists) return;

    tx.update(referrerRef, {
      points: FieldValue.increment(cfg.referralReferrerPoints),
      totalEarnedPoints: FieldValue.increment(cfg.referralReferrerPoints),
    });
    addTx(tx, user.referredBy, "referral", cfg.referralReferrerPoints, "referral_bonus");
  });
}

// ---------------------------------------------------------------------------
// Parrainage
// ---------------------------------------------------------------------------

exports.redeemReferral = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code || "").trim().toUpperCase();
  if (code.length < 4) throw new HttpsError("invalid-argument", "Code invalide.");

  const cfg = await getConfig();
  const q = await db.collection("users").where("referralCode", "==", code).limit(1).get();
  if (q.empty) throw new HttpsError("not-found", "Code invalide.");
  const referrerUid = q.docs[0].id;
  if (referrerUid === uid) {
    throw new HttpsError("invalid-argument", "Tu ne peux pas utiliser ton propre code.");
  }

  const userRef = db.doc(`users/${uid}`);
  await db.runTransaction(async (tx) => {
    const user = (await tx.get(userRef)).data();
    if (!user) throw new HttpsError("not-found", "Profil introuvable.");
    if (user.referredBy) throw new HttpsError("already-exists", "Un code a déjà été utilisé.");
    tx.update(userRef, {
      referredBy: referrerUid,
      points: FieldValue.increment(cfg.referralInviteePoints),
      totalEarnedPoints: FieldValue.increment(cfg.referralInviteePoints),
    });
    addTx(tx, uid, "referral", cfg.referralInviteePoints, "referral_welcome");
  });
  return { points: cfg.referralInviteePoints };
});

// ---------------------------------------------------------------------------
// Rewarded ads — en production, préférer la Server-Side Verification AdMob
// ---------------------------------------------------------------------------

exports.claimRewardedAd = onCall(async (req) => {
  const uid = requireAuth(req);
  const cfg = await getConfig();
  const userRef = db.doc(`users/${uid}`);

  await db.runTransaction(async (tx) => {
    const user = (await tx.get(userRef)).data();
    if (!user) throw new HttpsError("not-found", "Profil introuvable.");
    const last = user.lastRewardedAdAt ? user.lastRewardedAdAt.toMillis() : 0;
    if (Date.now() - last < cfg.rewardedAdCooldownSeconds * 1000) {
      throw new HttpsError("failed-precondition", "Attends un peu avant la prochaine pub bonus.");
    }
    tx.update(userRef, {
      points: FieldValue.increment(cfg.rewardedAdPoints),
      totalEarnedPoints: FieldValue.increment(cfg.rewardedAdPoints),
      lastRewardedAdAt: FieldValue.serverTimestamp(),
    });
    addTx(tx, uid, "rewarded_ad", cfg.rewardedAdPoints, "rewarded_ad");
  });
  return { points: cfg.rewardedAdPoints };
});

// ---------------------------------------------------------------------------
// Retraits — automatiques, cooldown 3 h, PayPal Payouts ou Tango Reward Link
// ---------------------------------------------------------------------------

exports.requestWithdrawal = onCall(
  {
    secrets: [
      TANGO_PLATFORM_NAME, TANGO_PLATFORM_KEY,
      TANGO_ACCOUNT_IDENTIFIER, TANGO_CUSTOMER_IDENTIFIER,
      PAYPAL_CLIENT_ID, PAYPAL_CLIENT_SECRET,
    ],
    timeoutSeconds: 120,
  },
  async (req) => {
    const uid = requireAuth(req);
    const method = String(req.data?.method || "");
    const points = Number(req.data?.points);
    const recipient = String(req.data?.recipient || "").trim();

    if (!["paypal", "tangocard"].includes(method)) {
      throw new HttpsError("invalid-argument", "Méthode inconnue.");
    }
    if (!Number.isInteger(points) || points <= 0) {
      throw new HttpsError("invalid-argument", "Montant invalide.");
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(recipient)) {
      throw new HttpsError("invalid-argument", "E-mail invalide.");
    }

    const cfg = await getConfig();
    if (points < cfg.minWithdrawalPoints) {
      throw new HttpsError("failed-precondition", `Minimum : ${cfg.minWithdrawalPoints} points.`);
    }

    const amountUSD = Math.round(points * cfg.pointValueUSD * 100) / 100;
    const userRef = db.doc(`users/${uid}`);
    const wRef = userRef.collection("withdrawals").doc();

    // Débit + cooldown vérifiés atomiquement
    await db.runTransaction(async (tx) => {
      const user = (await tx.get(userRef)).data();
      if (!user) throw new HttpsError("not-found", "Profil introuvable.");
      const last = user.lastWithdrawalAt ? user.lastWithdrawalAt.toMillis() : 0;
      if (Date.now() - last < cfg.withdrawalCooldownHours * 3600000) {
        throw new HttpsError("failed-precondition", "Un seul retrait toutes les 3 heures.");
      }
      if ((user.points || 0) < points) {
        throw new HttpsError("failed-precondition", "Solde insuffisant.");
      }
      tx.update(userRef, {
        points: FieldValue.increment(-points),
        lastWithdrawalAt: FieldValue.serverTimestamp(),
      });
      tx.set(wRef, {
        method, points, amountUSD, recipient,
        status: "processing",
        createdAt: FieldValue.serverTimestamp(),
      });
      addTx(tx, uid, "withdrawal", -points, method);
    });

    try {
      const providerRef = method === "paypal"
        ? await payoutPayPal(wRef.id, amountUSD, recipient, cfg)
        : await payoutTangoRewardLink(wRef.id, amountUSD, recipient, cfg);
      await wRef.update({ status: "paid", providerRef });
      return { status: "paid", amountUSD };
    } catch (err) {
      console.error("Payout failed", err);
      // Remboursement automatique en cas d'échec du prestataire
      await db.runTransaction(async (tx) => {
        tx.update(userRef, { points: FieldValue.increment(points) });
        tx.update(wRef, { status: "failed", error: String(err.message || err) });
        addTx(tx, uid, "refund", points, method);
      });
      throw new HttpsError("internal", "Le paiement a échoué, tes points ont été remboursés.");
    }
  }
);

async function payoutPayPal(batchId, amountUSD, email, cfg) {
  const base = cfg.paypalSandbox
    ? "https://api-m.sandbox.paypal.com"
    : "https://api-m.paypal.com";
  const creds = Buffer.from(
    `${PAYPAL_CLIENT_ID.value()}:${PAYPAL_CLIENT_SECRET.value()}`
  ).toString("base64");

  const tokenRes = await fetch(`${base}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${creds}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });
  if (!tokenRes.ok) throw new Error(`PayPal auth: ${tokenRes.status}`);
  const { access_token } = await tokenRes.json();

  const res = await fetch(`${base}/v1/payments/payouts`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${access_token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      sender_batch_header: {
        sender_batch_id: batchId,
        email_subject: "Votre gain CashQuest 🎉",
      },
      items: [{
        recipient_type: "EMAIL",
        receiver: email,
        note: "Merci d'avoir joué à CashQuest !",
        amount: { value: amountUSD.toFixed(2), currency: "USD" },
      }],
    }),
  });
  if (!res.ok) throw new Error(`PayPal payout: ${res.status} ${await res.text()}`);
  const json = await res.json();
  return (json.batch_header && json.batch_header.payout_batch_id) || "paypal";
}

// Reward Link : l'utilisateur reçoit par e-mail un lien où il choisit
// lui-même sa carte cadeau. C'est un produit du catalogue Tango (UTID dédié).
async function payoutTangoRewardLink(orderId, amountUSD, email, cfg) {
  const base = cfg.tangoSandbox
    ? "https://integration-api.tangocard.com/raas/v2"
    : "https://api.tangocard.com/raas/v2";
  const creds = Buffer.from(
    `${TANGO_PLATFORM_NAME.value()}:${TANGO_PLATFORM_KEY.value()}`
  ).toString("base64");

  const res = await fetch(`${base}/orders`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${creds}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      externalRefID: orderId,
      accountIdentifier: TANGO_ACCOUNT_IDENTIFIER.value(),
      customerIdentifier: TANGO_CUSTOMER_IDENTIFIER.value(),
      utid: cfg.tangoUtid,
      amount: amountUSD,
      sendEmail: true,
      recipient: {
        email,
        firstName: "CashQuest",
        lastName: "Player",
      },
    }),
  });
  if (!res.ok) throw new Error(`Tango order: ${res.status} ${await res.text()}`);
  const json = await res.json();
  return json.referenceOrderID || "tango";
}
