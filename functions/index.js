const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ region: "us-central1" });

exports.sosPush = onDocumentUpdated("groups/{groupId}", async (event) => {
  const before = event.data.before.data() || {};
  const after = event.data.after.data() || {};
  const beforeSos = before.sos || null;
  const afterSos = after.sos || null;

  const groupId = event.params.groupId;
  const groupName = after.name || "your group";
  const memberIds = Array.isArray(after.memberIds) ? after.memberIds : [];

  if (afterSos && (!beforeSos || beforeSos.createdAt !== afterSos.createdAt)) {
    const senderUid = afterSos.uid;
    const senderName = afterSos.name || "A member";
    await sendToMembers(memberIds, senderUid, {
      title: `SOS from ${senderName}`,
      body: `${senderName} needs help in ${groupName}.`,
      data: {
        type: "sos",
        groupId,
        uid: senderUid,
        name: senderName,
        latitude: String(afterSos.latitude ?? ""),
        longitude: String(afterSos.longitude ?? ""),
      },
    });
    return null;
  }

  if (!afterSos && beforeSos) {
    const senderName = beforeSos.name || "A member";
    await sendToMembers(memberIds, beforeSos.uid, {
      title: "SOS resolved",
      body: `${senderName} marked the SOS in ${groupName} as resolved.`,
      data: { type: "sos_resolved", groupId, uid: beforeSos.uid },
    });
    return null;
  }

  return null;
});

async function sendToMembers(memberIds, excludeUid, payload) {
  const tokens = [];
  const tokenUid = new Map();

  for (const uid of memberIds) {
    if (uid === excludeUid) continue;
    const snap = await admin.firestore().doc(`users/${uid}`).get();
    const token = snap.get("fcmToken");
    if (typeof token === "string" && token.length > 0) {
      tokens.push(token);
      tokenUid.set(token, uid);
    }
  }

  if (tokens.length === 0) return;

  const res = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title: payload.title, body: payload.body },
    data: payload.data,
    android: {
      priority: "high",
      notification: { channelId: "sos_alerts" },
    },
  });

  const staleTokens = [];
  res.responses.forEach((r, i) => {
    if (!r.success) {
      const code = r.error && r.error.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        staleTokens.push(tokens[i]);
      }
    }
  });

  for (const token of staleTokens) {
    const uid = tokenUid.get(token);
    if (!uid) continue;
    await admin
      .firestore()
      .doc(`users/${uid}`)
      .update({ fcmToken: admin.firestore.FieldValue.delete() })
      .catch(() => {});
  }
}
