import { addDoc, collection, doc, serverTimestamp, updateDoc } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { db, functions } from '../firebase';

export async function approveLawyerVerification({ lawyerId, adminId }) {
  await updateDoc(doc(db, 'lawyers', lawyerId), {
    isVerified: true,
    verification_status: 'approved',
    verified_by: adminId,
    verified_at: serverTimestamp(),
    updated_at: serverTimestamp(),
  });

  // Push trigger event: backend (Cloud Function) should watch notifications and send FCM.
  await addDoc(collection(db, 'notifications'), {
    user_id: lawyerId,
    type: 'lawyer_verification_approved',
    title: 'Lawyer Verification Approved',
    body: 'Your account is verified. You can now access all lawyer features.',
    channel: 'push',
    read: false,
    created_at: serverTimestamp(),
  });
}

export async function rejectLawyerVerification({ lawyerId, adminId, reason }) {
  await updateDoc(doc(db, 'lawyers', lawyerId), {
    isVerified: false,
    verification_status: 'rejected',
    rejection_reason: reason || 'Verification rejected by admin.',
    verified_by: adminId,
    verified_at: serverTimestamp(),
    updated_at: serverTimestamp(),
  });
}

export async function deleteLawyer(lawyerId) {
  if (!lawyerId) {
    throw new Error('Missing lawyer id');
  }

  return deleteAccountByAdmin({
    userId: lawyerId,
    userType: 'lawyer',
  });
}

export async function deleteAccountByAdmin({ userId, userType }) {
  if (!userId) {
    throw new Error('Missing user id');
  }

  const normalizedType = (userType || '').toString().toLowerCase();
  const profileCollections = normalizedType === 'client'
    ? ['clients']
    : ['lawyers'];

  if (!functions) {
    throw new Error('Firebase Functions is not configured in admin portal.');
  }

  try {
    const callable = httpsCallable(functions, 'adminDeleteUserAccount');
    const response = await callable({
      uid: userId,
      collections: profileCollections,
    });
    return response?.data || { success: true, uid: userId, authDeleted: false, deletedDocs: [] };
  } catch (err) {
    const code = (err?.code || '').toString();
    if (code.includes('not-found')) {
      throw new Error(
        'Cloud Function adminDeleteUserAccount is not deployed yet. Deploy functions and try again.',
      );
    }
    throw new Error(err?.message || 'Failed to delete account from Firebase Authentication.');
  }
}
