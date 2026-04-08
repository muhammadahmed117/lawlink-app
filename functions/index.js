const admin = require('firebase-admin');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { logger } = require('firebase-functions');

admin.initializeApp();

exports.adminDeleteUserAccount = onCall({ region: 'us-central1' }, async (request) => {
  const callerUid = request.auth?.uid;
  const targetUid = (request.data?.uid || '').toString().trim();
  const requestedCollections = Array.isArray(request.data?.collections)
    ? request.data.collections
    : [];

  if (!callerUid) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }

  if (!targetUid) {
    throw new HttpsError('invalid-argument', 'Missing target user id.');
  }

  const callerProfile = await admin.firestore().collection('users').doc(callerUid).get();
  const callerRole = (callerProfile.data()?.role || '').toString().toLowerCase();
  if (callerRole !== 'admin') {
    throw new HttpsError('permission-denied', 'Only admins can delete accounts.');
  }

  const collections = [...new Set(['users', ...requestedCollections])].filter(
    (name) => typeof name === 'string' && name.trim().length > 0,
  );

  const deletedDocs = [];
  for (const collectionName of collections) {
    const docPath = `${collectionName}/${targetUid}`;
    try {
      await admin.firestore().doc(docPath).delete();
      deletedDocs.push(docPath);
    } catch (err) {
      logger.warn('Failed deleting profile doc', { docPath, err: err?.message || String(err) });
    }
  }

  let authDeleted = false;
  try {
    await admin.auth().deleteUser(targetUid);
    authDeleted = true;
  } catch (err) {
    if (err?.code !== 'auth/user-not-found') {
      logger.error('Failed deleting auth user', { targetUid, err: err?.message || String(err) });
      throw new HttpsError('internal', 'Failed to delete authentication account.');
    }
  }

  return {
    success: true,
    uid: targetUid,
    authDeleted,
    deletedDocs,
  };
});
