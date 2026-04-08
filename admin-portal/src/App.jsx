import {
  Bell,
  Ban,
  CheckCircle2,
  Eye,
  EyeOff,
  FileText,
  RotateCcw,
  LayoutDashboard,
  LogOut,
  MessageSquareWarning,
  Settings,
  Trash2,
  Users,
  XCircle,
} from 'lucide-react';
import { useEffect, useMemo, useState } from 'react';
import {
  collection,
  doc,
  getDoc,
  onSnapshot,
  setDoc,
  serverTimestamp,
  updateDoc,
} from 'firebase/firestore';
import {
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from 'firebase/auth';
import {
  approveLawyerVerification,
  deleteAccountByAdmin,
  deleteLawyer,
  rejectLawyerVerification,
} from './services/lawyerVerification';
import { auth, db, firebaseInitError } from './firebase';

const sidebarItems = [
  { key: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { key: 'user-management', label: 'User Management (Clients/Lawyers)', icon: Users },
  { key: 'transaction-history', label: 'Transaction History', icon: FileText },
  { key: 'complaints', label: 'Complaints', icon: MessageSquareWarning },
  { key: 'settings', label: 'Settings', icon: Settings },
];

const kpis = [
  { key: 'totalLawyers', label: 'Total Registered Lawyers', tone: 'text-blue-700' },
  { key: 'totalClients', label: 'Total Clients', tone: 'text-indigo-700' },
  { key: 'pendingVerifications', label: 'Pending Verifications', tone: 'text-amber-600' },
  { key: 'activeComplaints', label: 'Active Complaints', tone: 'text-rose-600' },
];

function mapAuthErrorMessage(err) {
  const code = err?.code || '';
  if (code === 'auth/invalid-credential') {
    return 'Invalid email or password. Also confirm Email/Password sign-in is enabled in Firebase Authentication.';
  }
  if (code === 'auth/invalid-email') {
    return 'Please enter a valid email address.';
  }
  if (code === 'auth/user-disabled') {
    return 'This account is disabled in Firebase Authentication.';
  }
  if (code === 'auth/too-many-requests') {
    return 'Too many failed attempts. Wait a moment, then try again or reset the password.';
  }
  return err?.message || 'Login failed.';
}

function openBase64Document({ base64, mimeType, fileName }) {
  const byteChars = atob(base64);
  const byteNumbers = new Array(byteChars.length);
  for (let i = 0; i < byteChars.length; i += 1) {
    byteNumbers[i] = byteChars.charCodeAt(i);
  }
  const blob = new Blob([new Uint8Array(byteNumbers)], {
    type: mimeType || 'application/octet-stream',
  });
  const blobUrl = URL.createObjectURL(blob);
  const opened = window.open(blobUrl, '_blank', 'noopener,noreferrer');
  if (!opened) {
    const a = document.createElement('a');
    a.href = blobUrl;
    a.download = fileName || 'document';
    a.click();
  }
  setTimeout(() => URL.revokeObjectURL(blobUrl), 60000);
}

function formatTs(value) {
  if (!value) return 'N/A';
  if (value?.seconds) return new Date(value.seconds * 1000).toLocaleString();
  if (typeof value === 'string') return value;
  return 'N/A';
}

function normalizeLawyerDoc(id, raw = {}) {
  const profile = raw?.lawyer && typeof raw.lawyer === 'object' ? raw.lawyer : {};
  return {
    id,
    ...raw,
    name: profile.name ?? raw.name ?? '',
    email: profile.email ?? raw.email ?? '',
    phone: profile.phone ?? raw.phone ?? '',
    city: profile.city ?? raw.city ?? '',
    category: profile.category ?? raw.category ?? raw.specialization ?? '',
    specialization: profile.category ?? raw.specialization ?? raw.category ?? '',
    experienceYears: profile.experienceYears ?? raw.experienceYears ?? '',
    consultationFee: profile.consultationFee ?? raw.consultationFee ?? '',
    bio: profile.bio ?? raw.bio ?? '',
    paymentMethods: profile.paymentMethods ?? raw.paymentMethods ?? [],
  };
}

function App() {
  const [activeSection, setActiveSection] = useState('dashboard');
  const [pendingVerifications, setPendingVerifications] = useState([]);
  const [lawyers, setLawyers] = useState([]);
  const [clients, setClients] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [complaints, setComplaints] = useState([]);
  const [actionBusyId, setActionBusyId] = useState('');
  const [loadError, setLoadError] = useState('');
  const [email, setEmail] = useState('lawlink@gmail.com');
  const [password, setPassword] = useState('abc@1122');
  const [showPassword, setShowPassword] = useState(false);
  const [authBusy, setAuthBusy] = useState(false);
  const [authError, setAuthError] = useState('');
  const [currentAdmin, setCurrentAdmin] = useState(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [authReady, setAuthReady] = useState(false);
  const [stats, setStats] = useState({
    totalLawyers: 0,
    totalClients: 0,
    pendingVerifications: 0,
    activeComplaints: 0,
  });
  const [userSearch, setUserSearch] = useState('');
  const [complaintSearch, setComplaintSearch] = useState('');
  const [transactionSearch, setTransactionSearch] = useState('');
  const [accountFilter, setAccountFilter] = useState('active');
  const [selectedProfile, setSelectedProfile] = useState(null);
  const [deleteStatus, setDeleteStatus] = useState(null);

  const firebaseUnavailable = !auth || !db || Boolean(firebaseInitError);

  const ensureAdminProfile = async (user) => {
    if (!db || !user?.uid) {
      return;
    }

    await setDoc(
      doc(db, 'users', user.uid),
      {
        uid: user.uid,
        role: 'admin',
        email: (user.email || '').toString().toLowerCase(),
        updatedAt: serverTimestamp(),
        createdAt: serverTimestamp(),
      },
      { merge: true },
    );
  };

  useEffect(() => {
    if (firebaseUnavailable) {
      setAuthError(firebaseInitError || 'Firebase is not configured.');
      setAuthReady(true);
      return () => {};
    }

    const unsub = onAuthStateChanged(auth, async (user) => {
      try {
        setCurrentAdmin(user ?? null);
        if (!user) {
          setIsAdmin(false);
          return;
        }

        const profile = await getDoc(doc(db, 'users', user.uid));
        const role = (profile.data()?.role || '').toString().toLowerCase();
        if (role !== 'admin') {
          setAuthError('This account is not an admin account.');
          setIsAdmin(false);
          await signOut(auth);
          return;
        }
        setAuthError('');
        setIsAdmin(true);
      } catch (err) {
        setIsAdmin(false);
        setAuthError(err?.message || 'Failed to load admin profile.');
      } finally {
        setAuthReady(true);
      }
    });

    return () => unsub();
  }, [firebaseUnavailable]);

  useEffect(() => {
    if (!isAdmin || !db) {
      setPendingVerifications([]);
      setLawyers([]);
      return () => {};
    }

    const unsub = onSnapshot(
      collection(db, 'lawyers'),
      (snapshot) => {
        const all = snapshot.docs.map((d) => normalizeLawyerDoc(d.id, d.data()));

        const pending = all.filter((item) => {
          const verified = item.isVerified === true;
          const status = (item.verification_status || item.approvalStatus || 'pending').toString().toLowerCase();
          return !verified && status === 'pending';
        });
        setPendingVerifications(pending);
        setLawyers(all);
        setLoadError('');
      },
      (err) => {
        setLoadError(err?.message || 'Could not load lawyer requests.');
      },
    );

    return () => unsub();
  }, [isAdmin, db]);

  useEffect(() => {
    if (!isAdmin || !db) {
      setStats({
        totalLawyers: 0,
        totalClients: 0,
        pendingVerifications: 0,
        activeComplaints: 0,
      });
      setClients([]);
      setTransactions([]);
      setComplaints([]);
      return () => {};
    }

    const unsubLawyers = onSnapshot(collection(db, 'lawyers'), (snapshot) => {
      const allLawyers = snapshot.docs.map((d) => normalizeLawyerDoc(d.id, d.data()));
      const pendingCount = allLawyers.filter((item) => {
        const verified = item.isVerified === true;
        const status = (item.verification_status || item.approvalStatus || 'pending')
          .toString()
          .toLowerCase();
        return !verified && status === 'pending';
      }).length;

      const acceptedCount = allLawyers.filter((item) => {
        const status = (item.verification_status || item.approvalStatus || 'pending')
          .toString()
          .toLowerCase();
        const isAccepted = item.isVerified === true || status === 'approved';
        return isAccepted && status !== 'rejected';
      }).length;

      setStats((prev) => ({
        ...prev,
        totalLawyers: acceptedCount,
        pendingVerifications: pendingCount,
      }));
    });

    const unsubClients = onSnapshot(collection(db, 'clients'), (snapshot) => {
      setClients(snapshot.docs.map((d) => ({ id: d.id, ...d.data() })));
      setStats((prev) => ({ ...prev, totalClients: snapshot.size }));
    });

    const unsubTransactions = onSnapshot(collection(db, 'transactions'), (snapshot) => {
      setTransactions(snapshot.docs.map((d) => ({ id: d.id, ...d.data() })));
    });

    const unsubComplaints = onSnapshot(collection(db, 'complaints'), (snapshot) => {
      setComplaints(snapshot.docs.map((d) => ({ id: d.id, ...d.data() })));
      const activeCount = snapshot.docs.filter((d) => {
        const status = (d.data()?.status || '').toString().toLowerCase();
        return status !== 'closed' && status !== 'resolved';
      }).length;

      setStats((prev) => ({ ...prev, activeComplaints: activeCount }));
    });

    return () => {
      unsubLawyers();
      unsubClients();
      unsubTransactions();
      unsubComplaints();
    };
  }, [isAdmin, db]);

  const handleAdminLogin = async (event) => {
    event.preventDefault();
    if (!auth) {
      setAuthError(firebaseInitError || 'Firebase auth is not available.');
      return;
    }
    try {
      setAuthBusy(true);
      setAuthError('');
      await signInWithEmailAndPassword(auth, email.trim(), password.trim());
    } catch (err) {
      const code = (err?.code || '').toString();
      const normalizedEmail = email.trim().toLowerCase();
      const normalizedPassword = password.trim();
      const shouldBootstrap =
        code === 'auth/invalid-credential' ||
        code === 'auth/user-not-found' ||
        code === 'auth/invalid-login-credentials';

      if (shouldBootstrap) {
        try {
          const credential = await createUserWithEmailAndPassword(
            auth,
            normalizedEmail,
            normalizedPassword,
          );
          await ensureAdminProfile(credential.user);
          return;
        } catch (createErr) {
          const createCode = (createErr?.code || '').toString();
          if (createCode === 'auth/email-already-in-use') {
            setAuthError('Email exists but password is incorrect. Please enter the correct password.');
            return;
          }
          setAuthError(mapAuthErrorMessage(createErr));
          return;
        }
      }

      setAuthError(mapAuthErrorMessage(err));
    } finally {
      setAuthBusy(false);
    }
  };

  const handleAdminLogout = async () => {
    if (!auth) {
      return;
    }
    await signOut(auth);
    setIsAdmin(false);
    setCurrentAdmin(null);
  };

  const kpiItems = useMemo(
    () =>
      kpis.map((item) => ({
        ...item,
        value: Number(stats[item.key] || 0).toLocaleString(),
      })),
    [stats],
  );

  const filteredLawyers = useMemo(() => {
    const q = userSearch.trim().toLowerCase();
    return lawyers.filter((item) => {
      const verification = (item.verification_status || item.approvalStatus || 'pending')
        .toString()
        .toLowerCase();
      const isAccepted = item.isVerified === true || verification === 'approved';

      // Show only accepted/verified registered lawyer accounts in user management.
      if (!isAccepted) {
        return false;
      }

      // Do not show rejected lawyers in user-management listing.
      if (verification === 'rejected') {
        return false;
      }

      const isSuspended = item.isSuspended === true;
      if (accountFilter === 'active' && isSuspended) {
        return false;
      }
      if (accountFilter === 'suspended' && !isSuspended) {
        return false;
      }

      const text = `${item.name || ''} ${item.email || ''} ${item.phone || ''} ${item.category || ''}`.toLowerCase();
      return !q || text.includes(q);
    });
  }, [lawyers, userSearch, accountFilter]);

  const filteredClients = useMemo(() => {
    const q = userSearch.trim().toLowerCase();
    return clients.filter((item) => {
      const isSuspended = item.isSuspended === true;
      if (accountFilter === 'active' && isSuspended) {
        return false;
      }
      if (accountFilter === 'suspended' && !isSuspended) {
        return false;
      }

      const text = `${item.name || ''} ${item.email || ''} ${item.phone || ''}`.toLowerCase();
      return !q || text.includes(q);
    });
  }, [clients, userSearch, accountFilter]);

  const filteredComplaints = useMemo(() => {
    const q = complaintSearch.trim().toLowerCase();
    if (!q) return complaints;
    return complaints.filter((item) => {
      const text = `${item.id || ''} ${item.title || ''} ${item.client_id || ''} ${item.lawyer_id || ''} ${item.appointment_id || ''} ${item.status || ''}`.toLowerCase();
      return text.includes(q);
    });
  }, [complaints, complaintSearch]);

  const filteredTransactions = useMemo(() => {
    const q = transactionSearch.trim().toLowerCase();
    const normalized = transactions
      .map((item) => {
        const clientName = (item.clientName || item.client_name || '').toString();
        const clientId = (item.clientId || item.client_id || '').toString();
        const lawyerName = (item.targetLawyerName || item.lawyerName || '').toString();
        const fee = (item.feeAmount || item.fee || item.totalFee || '').toString();
        const status = (item.status || 'pending_admin').toString().toLowerCase();
        const screenshotUrl = (item.paymentScreenshotUrl || item.screenshotUrl || item.paymentProofUrl || '').toString();
        const screenshotDocPath = (item.paymentProofDocPath || item.payment_proof_doc_path || item.screenshotDocPath || '').toString();
        const screenshotFileName = (item.paymentProofFileName || item.payment_proof_file_name || item.screenshotFileName || '').toString();
        return {
          ...item,
          clientName,
          clientId,
          lawyerName,
          fee,
          status,
          screenshotUrl,
          screenshotDocPath,
          screenshotFileName,
        };
      })
      .sort((a, b) => {
        const aMs = a?.createdAt?.seconds ? a.createdAt.seconds * 1000 : 0;
        const bMs = b?.createdAt?.seconds ? b.createdAt.seconds * 1000 : 0;
        return bMs - aMs;
      });

    if (!q) return normalized;
    return normalized.filter((item) => {
      const text = `${item.id} ${item.clientName} ${item.clientId} ${item.lawyerName} ${item.fee} ${item.status}`.toLowerCase();
      return text.includes(q);
    });
  }, [transactions, transactionSearch]);

  const complaintsWithClient = useMemo(
    () => filteredComplaints.filter((item) => Boolean(item.client_id)),
    [filteredComplaints],
  );

  const selectedProfileCases = useMemo(() => {
    if (!selectedProfile) return [];
    if (selectedProfile.type === 'client') {
      return complaints
        .filter((item) => item.client_id === selectedProfile.data.id)
        .sort((a, b) => {
          const aMs = a?.createdAt?.seconds ? a.createdAt.seconds * 1000 : 0;
          const bMs = b?.createdAt?.seconds ? b.createdAt.seconds * 1000 : 0;
          return bMs - aMs;
        });
    }
    return complaints
      .filter((item) => item.lawyer_id === selectedProfile.data.id)
      .sort((a, b) => {
        const aMs = a?.createdAt?.seconds ? a.createdAt.seconds * 1000 : 0;
        const bMs = b?.createdAt?.seconds ? b.createdAt.seconds * 1000 : 0;
        return bMs - aMs;
      });
  }, [selectedProfile, complaints]);

  const handleApprove = async (lawyerId) => {
    if (!currentAdmin || !db) {
      return;
    }
    try {
      setActionBusyId(lawyerId);
      await approveLawyerVerification({ lawyerId, adminId: currentAdmin.uid });
      setPendingVerifications((prev) => prev.filter((item) => item.id !== lawyerId));
    } finally {
      setActionBusyId('');
    }
  };

  const handleReject = async (lawyerId) => {
    if (!currentAdmin || !db) {
      return;
    }

    const confirmed = window.confirm(
      'Reject this request and remove this lawyer account from Firebase?',
    );
    if (!confirmed) {
      return;
    }

    try {
      setActionBusyId(lawyerId);
      await rejectLawyerVerification({
        lawyerId,
        adminId: currentAdmin.uid,
        reason: 'Document quality or mismatch issue.',
      });
      const result = await deleteLawyer(lawyerId);
      setPendingVerifications((prev) => prev.filter((item) => item.id !== lawyerId));
      const authDeleted = result?.authDeleted === true;
      setDeleteStatus({
        tone: authDeleted ? 'success' : 'warning',
        message: authDeleted
          ? `Rejected lawyer ${lawyerId} and deleted from Firebase Auth + Firestore.`
          : `Rejected lawyer ${lawyerId}; Firestore removed, Auth account was already missing.`,
      });
    } catch (err) {
      setDeleteStatus({
        tone: 'error',
        message: err?.message || 'Failed to reject and remove lawyer.',
      });
      window.alert(err?.message || 'Failed to reject and remove lawyer.');
    } finally {
      setActionBusyId('');
    }
  };

  const handleDelete = async (lawyerId) => {
    if (!currentAdmin || !db) {
      return;
    }

    const confirmed = window.confirm(
      'Delete this lawyer record from Firebase? This cannot be undone.',
    );
    if (!confirmed) {
      return;
    }

    try {
      setActionBusyId(lawyerId);
      const result = await deleteLawyer(lawyerId);
      setPendingVerifications((prev) => prev.filter((item) => item.id !== lawyerId));
      const authDeleted = result?.authDeleted === true;
      setDeleteStatus({
        tone: authDeleted ? 'success' : 'warning',
        message: authDeleted
          ? `Lawyer ${lawyerId} deleted from Firebase Auth and Firestore.`
          : `Lawyer ${lawyerId} removed from Firestore, but Auth account was already missing.`,
      });
    } catch (err) {
      setDeleteStatus({
        tone: 'error',
        message: err?.message || 'Failed to delete lawyer record.',
      });
      window.alert(err?.message || 'Failed to delete lawyer record.');
    } finally {
      setActionBusyId('');
    }
  };

  const handleSetSuspension = async ({ userType, userId, suspended }) => {
    if (!currentAdmin || !db || !userId) {
      return;
    }

    const collectionName = userType === 'client' ? 'clients' : 'lawyers';

    try {
      setActionBusyId(userId);
      await updateDoc(doc(db, collectionName, userId), {
        isSuspended: suspended,
        suspension_updated_at: serverTimestamp(),
        suspension_updated_by: currentAdmin.uid,
      });

      setSelectedProfile((prev) => {
        if (!prev || prev.data?.id !== userId || prev.type !== userType) {
          return prev;
        }
        return {
          ...prev,
          data: {
            ...prev.data,
            isSuspended: suspended,
          },
        };
      });
    } catch (err) {
      window.alert(err?.message || 'Failed to update account status.');
    } finally {
      setActionBusyId('');
    }
  };

  const handleDeleteProfile = async ({ userType, userId }) => {
    if (!currentAdmin || !db || !userId) {
      return;
    }

    const confirmed = window.confirm(
      `Delete this ${userType} account from Firebase? This cannot be undone.`,
    );

    if (!confirmed) {
      return;
    }

    try {
      setActionBusyId(userId);
      const result = await deleteAccountByAdmin({ userType, userId });
      setSelectedProfile(null);
      const authDeleted = result?.authDeleted === true;
      setDeleteStatus({
        tone: authDeleted ? 'success' : 'warning',
        message: authDeleted
          ? `${userType} ${userId} deleted from Firebase Auth and Firestore.`
          : `${userType} ${userId} removed from Firestore, but Auth account was already missing.`,
      });
    } catch (err) {
      setDeleteStatus({
        tone: 'error',
        message: err?.message || `Failed to delete ${userType} account.`,
      });
      window.alert(err?.message || `Failed to delete ${userType} account.`);
    } finally {
      setActionBusyId('');
    }
  };

  const handleUpdateTransactionStatus = async ({ transactionId, nextStatus }) => {
    if (!db || !transactionId || !nextStatus) {
      return;
    }

    try {
      setActionBusyId(transactionId);
      await updateDoc(doc(db, 'transactions', transactionId), {
        status: nextStatus,
        updatedAt: serverTimestamp(),
      });
    } catch (err) {
      window.alert(err?.message || 'Failed to update transaction status.');
    } finally {
      setActionBusyId('');
    }
  };

  const handleOpenDocument = async ({ docPath, fallbackName, label, url }) => {
    try {
      if (url) {
        window.open(url, '_blank', 'noopener,noreferrer');
        return;
      }

      if (docPath) {
        const snap = await getDoc(doc(db, docPath));
        if (!snap.exists()) {
          window.alert(`${label} not found in Firestore documents.`);
          return;
        }

        const data = snap.data() || {};
        if (!data.bytes_base64) {
          window.alert(`${label} has no inline data.`);
          return;
        }

        openBase64Document({
          base64: data.bytes_base64,
          mimeType: data.mime_type,
          fileName: data.file_name || fallbackName || label,
        });
        return;
      }

      if (fallbackName) {
        window.alert(`${label}: ${fallbackName}`);
        return;
      }

      window.alert(`${label} not uploaded yet.`);
    } catch (err) {
      window.alert(err?.message || `Could not open ${label}.`);
    }
  };

  if (!authReady) {
    return (
      <div className="grid min-h-screen place-items-center bg-page p-8 text-slate-700">
        <p className="text-sm font-semibold">Loading admin portal...</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-page text-slate-900">
      {!isAdmin ? (
        <div className="grid min-h-screen place-items-center p-8">
          <form
            onSubmit={handleAdminLogin}
            className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-6 shadow-soft"
          >
            <div className="mb-4 flex justify-center">
              <div className="h-24 w-24 rounded-full border border-slate-200 bg-slate-50 p-1">
                <div className="h-full w-full overflow-hidden rounded-full bg-white p-0.5">
                  <img
                    src="/lawlink_logo.png"
                    alt="LawLink"
                    className="h-full w-full scale-[1.45] rounded-full object-contain"
                  />
                </div>
              </div>
            </div>
            <h2 className="text-2xl font-bold text-brand">LawLink Admin Login</h2>
            <p className="mt-1 text-sm text-slate-500">
              Sign in with your admin Firebase account.
            </p>

            <div className="mt-4 space-y-3">
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-brand"
                placeholder="admin@lawlink.com"
                required
              />
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 px-3 py-2 pr-10 text-sm outline-none focus:border-brand"
                  placeholder="Password"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((prev) => !prev)}
                  className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-700"
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            {authError ? (
              <p className="mt-3 rounded-lg bg-rose-50 px-3 py-2 text-sm font-medium text-rose-700">
                {authError}
              </p>
            ) : null}

            <button
              type="submit"
              disabled={authBusy}
              className="mt-4 w-full rounded-lg bg-brand px-4 py-2.5 text-sm font-semibold text-white hover:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {authBusy ? 'Signing in...' : 'Sign In'}
            </button>
          </form>
        </div>
      ) : (
      <>
      <div className="mx-auto grid min-h-screen max-w-[1720px] grid-cols-1 lg:grid-cols-[260px_1fr]">
        <aside className="hidden border-r border-slate-200 bg-white px-5 py-6 shadow-soft lg:block">
          <div className="mb-8 flex items-center gap-3">
            <div className="h-12 w-12 rounded-full border border-slate-200 bg-slate-50 p-0.5">
              <div className="h-full w-full overflow-hidden rounded-full bg-white p-0">
                <img
                  src="/lawlink_logo.png"
                  alt="LawLink"
                  className="h-full w-full scale-[1.45] rounded-full object-contain"
                />
              </div>
            </div>
            <div>
              <h1 className="text-xl font-bold text-brand">LawLink Admin</h1>
            </div>
          </div>

          <nav className="space-y-2">
            {sidebarItems.map((item) => {
              const Icon = item.icon;
              const active = activeSection === item.key;
              return (
                <button
                  key={item.key}
                  className={`flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-sm font-semibold transition ${
                    active
                      ? 'bg-brand text-white shadow-soft'
                      : 'text-slate-600 hover:bg-slate-100'
                  }`}
                  type="button"
                  onClick={() => setActiveSection(item.key)}
                >
                  <Icon size={18} />
                  <span>{item.label}</span>
                </button>
              );
            })}
          </nav>
        </aside>

        <main className="p-6">
          <header className="mb-6 flex items-center justify-between rounded-2xl bg-white px-5 py-4 shadow-soft">
            <div>
              <h2 className="text-2xl font-bold text-slate-900">
                {sidebarItems.find((item) => item.key === activeSection)?.label || 'Dashboard'}
              </h2>
              <p className="text-sm text-slate-500">Manage verification, users, and complaints from one place.</p>
            </div>
            <div className="flex items-center gap-3">
              <button className="relative rounded-xl border border-slate-200 p-2.5 text-slate-600 hover:bg-slate-50" type="button">
                <Bell size={18} />
                <span className="absolute -right-0.5 -top-0.5 h-2.5 w-2.5 rounded-full bg-rose-500" />
              </button>
              <div className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm font-semibold text-slate-700">
                {currentAdmin?.email || 'Admin'}
              </div>
              <button
                className="inline-flex items-center gap-2 rounded-xl bg-slate-900 px-3 py-2 text-sm font-semibold text-white hover:bg-slate-800"
                type="button"
                onClick={handleAdminLogout}
              >
                <LogOut size={16} />
                Logout
              </button>
            </div>
          </header>

          {deleteStatus ? (
            <div
              className={`mb-6 rounded-xl border px-4 py-3 text-sm font-semibold ${
                deleteStatus.tone === 'success'
                  ? 'border-emerald-200 bg-emerald-50 text-emerald-800'
                  : deleteStatus.tone === 'warning'
                    ? 'border-amber-200 bg-amber-50 text-amber-800'
                    : 'border-rose-200 bg-rose-50 text-rose-800'
              }`}
            >
              <div className="flex items-center justify-between gap-3">
                <span>{deleteStatus.message}</span>
                <button
                  type="button"
                  onClick={() => setDeleteStatus(null)}
                  className="rounded-md border border-current px-2 py-0.5 text-xs font-bold"
                >
                  Dismiss
                </button>
              </div>
            </div>
          ) : null}

          <section className={`${activeSection === 'dashboard' ? 'mb-6 grid' : 'hidden'} grid-cols-4 gap-4`}>
            {kpiItems.map((kpi) => (
              <article key={kpi.label} className="rounded-2xl border border-slate-200 bg-white p-4 shadow-soft">
                <p className="text-xs font-semibold uppercase tracking-[0.14em] text-slate-400">{kpi.label}</p>
                <p className={`mt-3 text-3xl font-extrabold ${kpi.tone}`}>{kpi.value}</p>
              </article>
            ))}
          </section>

          <section className={`${activeSection === 'dashboard' ? '' : 'hidden'} rounded-2xl border border-slate-200 bg-white p-5 shadow-soft`}>
            <h3 className="mb-4 text-lg font-bold text-slate-900">Pending Verifications</h3>
            {loadError ? (
              <p className="mb-4 rounded-lg bg-rose-50 px-3 py-2 text-sm font-medium text-rose-700">{loadError}</p>
            ) : null}
            <div className="overflow-hidden rounded-xl border border-slate-200">
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-50 text-xs uppercase tracking-[0.14em] text-slate-500">
                  <tr>
                    <th className="px-4 py-3">Lawyer Name</th>
                    <th className="px-4 py-3">Specialization</th>
                    <th className="px-4 py-3">Documents</th>
                    <th className="px-4 py-3">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {pendingVerifications.length === 0 ? (
                    <tr>
                      <td className="px-4 py-4 text-slate-500" colSpan={4}>
                        No pending verification requests.
                      </td>
                    </tr>
                  ) : null}
                  {pendingVerifications.map((item) => (
                    <tr key={item.id} className="border-t border-slate-100">
                      <td className="px-4 py-3 font-semibold text-slate-800">{item.name}</td>
                      <td className="px-4 py-3 text-slate-600">{item.category || item.specialization || 'General Law'}</td>
                      <td className="px-4 py-3">
                        <div className="flex flex-wrap gap-2">
                          {[
                            {
                              label: 'CNIC Front',
                              url: item.cnic_url,
                              docPath: item.cnic_doc_path,
                              fallback: item.cnic_file_name,
                            },
                            {
                              label: 'CNIC Back',
                              url: item.cnic_back_url,
                              docPath: item.cnic_doc_path,
                              fallback: item.cnic_file_name,
                            },
                            {
                              label: 'Bar Council ID',
                              url: item.bar_id_url,
                              docPath: item.bar_id_doc_path,
                              fallback: item.bar_id_file_name,
                            },
                          ].map((docItem) => (
                            <button
                              key={`${item.id}-${docItem.label}`}
                              className="inline-flex items-center gap-1 rounded-md border border-slate-300 bg-white px-2 py-1 text-xs font-medium text-slate-700 hover:bg-slate-50"
                              type="button"
                              onClick={() => handleOpenDocument({
                                docPath: docItem.docPath,
                                fallbackName: docItem.fallback,
                                label: docItem.label,
                                url: docItem.url,
                              })}
                            >
                              <FileText size={14} />
                              {docItem.label}
                            </button>
                          ))}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex gap-2">
                          <button
                            className="inline-flex items-center gap-1 rounded-md bg-emerald-600 px-2.5 py-1.5 text-xs font-semibold text-white hover:bg-emerald-700"
                            type="button"
                            onClick={() => handleApprove(item.id)}
                            disabled={actionBusyId === item.id}
                          >
                            <CheckCircle2 size={14} />
                            {actionBusyId === item.id ? 'Working...' : 'Approve'}
                          </button>
                          <button
                            className="inline-flex items-center gap-1 rounded-md bg-rose-600 px-2.5 py-1.5 text-xs font-semibold text-white hover:bg-rose-700"
                            type="button"
                            onClick={() => handleReject(item.id)}
                            disabled={actionBusyId === item.id}
                          >
                            <XCircle size={14} />
                            Reject & Remove
                          </button>
                          <button
                            className="inline-flex items-center gap-1 rounded-md bg-slate-700 px-2.5 py-1.5 text-xs font-semibold text-white hover:bg-slate-800"
                            type="button"
                            onClick={() => handleDelete(item.id)}
                            disabled={actionBusyId === item.id}
                          >
                            <Trash2 size={14} />
                            Delete
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>

          <section className={`${activeSection === 'user-management' ? '' : 'hidden'} rounded-2xl border border-slate-200 bg-white p-5 shadow-soft`}>
            <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
              <h3 className="text-lg font-bold text-slate-900">User Management</h3>
              <div className="flex w-full max-w-xl flex-wrap items-center gap-2">
                <input
                  value={userSearch}
                  onChange={(e) => setUserSearch(e.target.value)}
                  placeholder="Search clients/lawyers..."
                  className="w-full flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-brand"
                />
                <select
                  value={accountFilter}
                  onChange={(e) => setAccountFilter(e.target.value)}
                  className="rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-brand"
                >
                  <option value="active">Active Accounts</option>
                  <option value="suspended">Suspended Accounts</option>
                </select>
              </div>
            </div>

            <h4 className="mb-2 text-sm font-bold uppercase tracking-[0.14em] text-slate-500">Clients (Separate)</h4>
            <div className="mb-5 overflow-hidden rounded-xl border border-slate-200">
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-50 text-xs uppercase tracking-[0.14em] text-slate-500">
                  <tr>
                    <th className="px-4 py-3">Name</th>
                    <th className="px-4 py-3">Email</th>
                    <th className="px-4 py-3">Phone</th>
                    <th className="px-4 py-3">Status</th>
                    <th className="px-4 py-3">Action</th>
                    <th className="px-4 py-3">Detail</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredClients.length === 0 ? (
                    <tr>
                      <td className="px-4 py-4 text-slate-500" colSpan={6}>No clients found.</td>
                    </tr>
                  ) : null}
                  {filteredClients.map((item) => (
                    <tr key={item.id} className="border-t border-slate-100">
                      <td className="px-4 py-3 font-semibold text-slate-800">{item.name || 'N/A'}</td>
                      <td className="px-4 py-3 text-slate-600">{item.email || 'N/A'}</td>
                      <td className="px-4 py-3 text-slate-600">{item.phone || 'N/A'}</td>
                      <td className="px-4 py-3 text-slate-600">{item.isSuspended ? 'Suspended' : 'Active'}</td>
                      <td className="px-4 py-3">
                        {item.isSuspended ? (
                          <button
                            type="button"
                            onClick={() =>
                              handleSetSuspension({
                                userType: 'client',
                                userId: item.id,
                                suspended: false,
                              })
                            }
                            disabled={actionBusyId === item.id}
                            className="inline-flex items-center gap-1 rounded-md bg-emerald-600 px-2.5 py-1.5 text-xs font-semibold text-white hover:bg-emerald-700 disabled:cursor-not-allowed disabled:opacity-60"
                          >
                            <RotateCcw size={14} />
                            {actionBusyId === item.id ? 'Working...' : 'Activate'}
                          </button>
                        ) : (
                          <button
                            type="button"
                            onClick={() =>
                              handleSetSuspension({
                                userType: 'client',
                                userId: item.id,
                                suspended: true,
                              })
                            }
                            disabled={actionBusyId === item.id}
                            className="inline-flex items-center gap-1 rounded-md bg-amber-600 px-2.5 py-1.5 text-xs font-semibold text-white hover:bg-amber-700 disabled:cursor-not-allowed disabled:opacity-60"
                          >
                            <Ban size={14} />
                            {actionBusyId === item.id ? 'Working...' : 'Suspend'}
                          </button>
                        )}
                      </td>
                      <td className="px-4 py-3">
                        <button
                          type="button"
                          onClick={() => setSelectedProfile({ type: 'client', data: item })}
                          className="inline-flex items-center gap-1 rounded-md border border-slate-300 px-2.5 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
                        >
                          <Eye size={14} />
                          View
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <h4 className="mb-2 text-sm font-bold uppercase tracking-[0.14em] text-slate-500">Lawyers (Accepted Only)</h4>
            <div className="overflow-hidden rounded-xl border border-slate-200">
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-50 text-xs uppercase tracking-[0.14em] text-slate-500">
                  <tr>
                    <th className="px-4 py-3">Name</th>
                    <th className="px-4 py-3">Email</th>
                    <th className="px-4 py-3">Specialization</th>
                    <th className="px-4 py-3">Verification</th>
                    <th className="px-4 py-3">Action</th>
                    <th className="px-4 py-3">Detail</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredLawyers.length === 0 ? (
                    <tr>
                      <td className="px-4 py-4 text-slate-500" colSpan={6}>No lawyers found.</td>
                    </tr>
                  ) : null}
                  {filteredLawyers.map((item) => (
                    <tr key={item.id} className="border-t border-slate-100">
                      <td className="px-4 py-3 font-semibold text-slate-800">{item.name || 'N/A'}</td>
                      <td className="px-4 py-3 text-slate-600">{item.email || 'N/A'}</td>
                      <td className="px-4 py-3 text-slate-600">{item.category || item.specialization || 'General Law'}</td>
                      <td className="px-4 py-3 text-slate-600">{item.isVerified ? 'Verified' : ((item.verification_status || item.approvalStatus || 'pending').toString())}</td>
                      <td className="px-4 py-3">
                        {item.isSuspended ? (
                          <button
                            type="button"
                            onClick={() =>
                              handleSetSuspension({
                                userType: 'lawyer',
                                userId: item.id,
                                suspended: false,
                              })
                            }
                            disabled={actionBusyId === item.id}
                            className="inline-flex items-center gap-1 rounded-md bg-emerald-600 px-2.5 py-1.5 text-xs font-semibold text-white hover:bg-emerald-700 disabled:cursor-not-allowed disabled:opacity-60"
                          >
                            <RotateCcw size={14} />
                            {actionBusyId === item.id ? 'Working...' : 'Activate'}
                          </button>
                        ) : (
                          <button
                            type="button"
                            onClick={() =>
                              handleSetSuspension({
                                userType: 'lawyer',
                                userId: item.id,
                                suspended: true,
                              })
                            }
                            disabled={actionBusyId === item.id}
                            className="inline-flex items-center gap-1 rounded-md bg-amber-600 px-2.5 py-1.5 text-xs font-semibold text-white hover:bg-amber-700 disabled:cursor-not-allowed disabled:opacity-60"
                          >
                            <Ban size={14} />
                            {actionBusyId === item.id ? 'Working...' : 'Suspend'}
                          </button>
                        )}
                      </td>
                      <td className="px-4 py-3">
                        <button
                          type="button"
                          onClick={() => setSelectedProfile({ type: 'lawyer', data: item })}
                          className="inline-flex items-center gap-1 rounded-md border border-slate-300 px-2.5 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
                        >
                          <Eye size={14} />
                          View
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>

          <section className={`${activeSection === 'transaction-history' ? '' : 'hidden'} rounded-2xl border border-slate-200 bg-white p-5 shadow-soft`}>
            <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
              <h3 className="text-lg font-bold text-slate-900">Transaction History</h3>
              <input
                value={transactionSearch}
                onChange={(e) => setTransactionSearch(e.target.value)}
                placeholder="Search transactions..."
                className="w-full max-w-xs rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-brand"
              />
            </div>

            <div className="overflow-hidden rounded-xl border border-slate-200">
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-50 text-xs uppercase tracking-[0.14em] text-slate-500">
                  <tr>
                    <th className="px-4 py-3">Transaction ID</th>
                    <th className="px-4 py-3">Client</th>
                    <th className="px-4 py-3">Target Lawyer</th>
                    <th className="px-4 py-3">Fee</th>
                    <th className="px-4 py-3">Proof</th>
                    <th className="px-4 py-3">Status</th>
                    <th className="px-4 py-3">Action</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredTransactions.length === 0 ? (
                    <tr>
                      <td className="px-4 py-4 text-slate-500" colSpan={7}>No transactions found.</td>
                    </tr>
                  ) : null}
                  {filteredTransactions.map((item) => (
                    <tr key={item.id} className="border-t border-slate-100">
                      <td className="px-4 py-3 font-semibold text-slate-800">{item.id}</td>
                      <td className="px-4 py-3 text-slate-600">
                        <div>{item.clientName || 'N/A'}</div>
                        <div className="text-xs text-slate-400">{item.clientId || 'N/A'}</div>
                      </td>
                      <td className="px-4 py-3 text-slate-600">{item.lawyerName || 'N/A'}</td>
                      <td className="px-4 py-3 text-slate-600">{item.fee ? `PKR ${item.fee}` : 'N/A'}</td>
                      <td className="px-4 py-3 text-slate-600">
                        {(item.screenshotUrl || item.screenshotDocPath || item.screenshotFileName) ? (
                          <button
                            type="button"
                            className="inline-flex items-center gap-1 rounded-md border border-slate-300 px-2.5 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
                            onClick={() =>
                              handleOpenDocument({
                                url: item.screenshotUrl,
                                docPath: item.screenshotDocPath,
                                fallbackName: item.screenshotFileName,
                                label: 'Payment Proof',
                              })
                            }
                          >
                            <Eye size={14} />
                            View
                          </button>
                        ) : (
                          'N/A'
                        )}
                      </td>
                      <td className="px-4 py-3 text-slate-600">{item.status}</td>
                      <td className="px-4 py-3">
                        <div className="flex flex-wrap gap-2">
                          {item.status === 'pending_admin' ? (
                            <>
                              <button
                                type="button"
                                onClick={() =>
                                  handleUpdateTransactionStatus({
                                    transactionId: item.id,
                                    nextStatus: 'pending_lawyer',
                                  })
                                }
                                disabled={actionBusyId === item.id}
                                className="inline-flex items-center gap-1 rounded-md bg-emerald-600 px-2.5 py-1.5 text-xs font-semibold text-white hover:bg-emerald-700 disabled:cursor-not-allowed disabled:opacity-60"
                              >
                                <CheckCircle2 size={14} />
                                {actionBusyId === item.id ? 'Working...' : 'Verify & Forward'}
                              </button>
                              <button
                                type="button"
                                onClick={() =>
                                  handleUpdateTransactionStatus({
                                    transactionId: item.id,
                                    nextStatus: 'rejected_admin',
                                  })
                                }
                                disabled={actionBusyId === item.id}
                                className="inline-flex items-center gap-1 rounded-md bg-rose-600 px-2.5 py-1.5 text-xs font-semibold text-white hover:bg-rose-700 disabled:cursor-not-allowed disabled:opacity-60"
                              >
                                <XCircle size={14} />
                                Reject
                              </button>
                            </>
                          ) : (
                            <span className="text-xs font-semibold text-slate-500">No action</span>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>

          <section className={`${activeSection === 'complaints' ? '' : 'hidden'} rounded-2xl border border-slate-200 bg-white p-5 shadow-soft`}>
            <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
              <h3 className="text-lg font-bold text-slate-900">Complaints</h3>
              <input
                value={complaintSearch}
                onChange={(e) => setComplaintSearch(e.target.value)}
                placeholder="Search complaints..."
                className="w-full max-w-xs rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-brand"
              />
            </div>

            <h4 className="mb-2 text-sm font-bold uppercase tracking-[0.14em] text-slate-500">Client Complaints (Separate)</h4>
            <div className="mb-5 overflow-hidden rounded-xl border border-slate-200">
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-50 text-xs uppercase tracking-[0.14em] text-slate-500">
                  <tr>
                    <th className="px-4 py-3">Complaint ID</th>
                    <th className="px-4 py-3">Client ID</th>
                    <th className="px-4 py-3">Appointment ID</th>
                    <th className="px-4 py-3">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {complaintsWithClient.length === 0 ? (
                    <tr>
                      <td className="px-4 py-4 text-slate-500" colSpan={4}>No client complaints found.</td>
                    </tr>
                  ) : null}
                  {complaintsWithClient.map((item) => (
                    <tr key={`c-${item.id}`} className="border-t border-slate-100">
                      <td className="px-4 py-3 font-semibold text-slate-800">{item.id}</td>
                      <td className="px-4 py-3 text-slate-600">{item.client_id || 'N/A'}</td>
                      <td className="px-4 py-3 text-slate-600">{item.appointment_id || 'N/A'}</td>
                      <td className="px-4 py-3 text-slate-600">{item.status || 'open'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

          </section>

          <section className={`${activeSection === 'settings' ? '' : 'hidden'} rounded-2xl border border-slate-200 bg-white p-5 shadow-soft`}>
            <h3 className="text-lg font-bold text-slate-900">Settings</h3>
            <p className="mt-2 text-sm text-slate-600">Settings panel is reserved for upcoming admin configuration options.</p>
          </section>

          {selectedProfile ? (
            <section className="mt-6 rounded-2xl border border-slate-200 bg-white p-5 shadow-soft">
              <div className="mb-4 flex items-start justify-between gap-4">
                <div>
                  <h3 className="text-lg font-bold text-slate-900">Profile Detail</h3>
                  <p className="text-sm text-slate-500">
                    {selectedProfile.type === 'client' ? 'Client information and hired cases.' : 'Lawyer information and accepted cases.'}
                  </p>
                </div>
                <div className="flex flex-wrap items-center justify-end gap-2">
                  {selectedProfile.data?.isSuspended ? (
                    <button
                      type="button"
                      onClick={() =>
                        handleSetSuspension({
                          userType: selectedProfile.type,
                          userId: selectedProfile.data.id,
                          suspended: false,
                        })
                      }
                      disabled={actionBusyId === selectedProfile.data.id}
                      className="inline-flex items-center gap-1 rounded-lg bg-emerald-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-emerald-700 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                      <RotateCcw size={14} />
                      {actionBusyId === selectedProfile.data.id ? 'Working...' : 'Activate'}
                    </button>
                  ) : (
                    <button
                      type="button"
                      onClick={() =>
                        handleSetSuspension({
                          userType: selectedProfile.type,
                          userId: selectedProfile.data.id,
                          suspended: true,
                        })
                      }
                      disabled={actionBusyId === selectedProfile.data.id}
                      className="inline-flex items-center gap-1 rounded-lg bg-amber-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-amber-700 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                      <Ban size={14} />
                      {actionBusyId === selectedProfile.data.id ? 'Working...' : 'Suspend'}
                    </button>
                  )}

                  {selectedProfile.data?.isSuspended ? (
                    <button
                      type="button"
                      onClick={() =>
                        handleDeleteProfile({
                          userType: selectedProfile.type,
                          userId: selectedProfile.data.id,
                        })
                      }
                      disabled={actionBusyId === selectedProfile.data.id}
                      className="inline-flex items-center gap-1 rounded-lg bg-rose-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-rose-700 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                      <Trash2 size={14} />
                      Delete
                    </button>
                  ) : null}

                  <button
                    type="button"
                    onClick={() => setSelectedProfile(null)}
                    className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm font-semibold text-slate-700 hover:bg-slate-50"
                  >
                    Close
                  </button>
                </div>
              </div>

              <div className="mb-5 grid grid-cols-1 gap-3 text-sm md:grid-cols-2">
                <p><span className="font-semibold">Role:</span> {selectedProfile.type}</p>
                <p><span className="font-semibold">Name:</span> {selectedProfile.data.name || 'N/A'}</p>
                <p><span className="font-semibold">Email:</span> {selectedProfile.data.email || 'N/A'}</p>
                <p><span className="font-semibold">Phone:</span> {selectedProfile.data.phone || 'N/A'}</p>
                <p><span className="font-semibold">Created At:</span> {formatTs(selectedProfile.data.createdAt || selectedProfile.data.created_at)}</p>
                <p>
                  <span className="font-semibold">Status:</span>{' '}
                  {selectedProfile.data.isSuspended
                    ? 'Suspended'
                    : (selectedProfile.type === 'lawyer'
                      ? (selectedProfile.data.isVerified ? 'Verified' : (selectedProfile.data.verification_status || selectedProfile.data.approvalStatus || 'pending'))
                      : 'Active')}
                </p>
              </div>

              <h4 className="mb-2 text-sm font-bold uppercase tracking-[0.14em] text-slate-500">
                {selectedProfile.type === 'client' ? 'Cases Hired By Client' : 'Cases Accepted By Lawyer'}
              </h4>
              <div className="overflow-hidden rounded-xl border border-slate-200">
                <table className="w-full text-left text-sm">
                  <thead className="bg-slate-50 text-xs uppercase tracking-[0.14em] text-slate-500">
                    <tr>
                      <th className="px-4 py-3">Case/Complaint ID</th>
                      <th className="px-4 py-3">Client ID</th>
                      <th className="px-4 py-3">Lawyer ID</th>
                      <th className="px-4 py-3">Appointment ID</th>
                      <th className="px-4 py-3">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {selectedProfileCases.length === 0 ? (
                      <tr>
                        <td className="px-4 py-4 text-slate-500" colSpan={5}>No related cases found.</td>
                      </tr>
                    ) : null}
                    {selectedProfileCases.map((item) => (
                      <tr key={item.id} className="border-t border-slate-100">
                        <td className="px-4 py-3 font-semibold text-slate-800">{item.id}</td>
                        <td className="px-4 py-3 text-slate-600">{item.client_id || 'N/A'}</td>
                        <td className="px-4 py-3 text-slate-600">{item.lawyer_id || 'N/A'}</td>
                        <td className="px-4 py-3 text-slate-600">{item.appointment_id || 'N/A'}</td>
                        <td className="px-4 py-3 text-slate-600">{item.status || 'open'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>
          ) : null}
        </main>
      </div>
      </>
      )}
    </div>
  );
}

export default App;
