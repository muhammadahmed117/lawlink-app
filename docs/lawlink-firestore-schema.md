# LawLink Firestore Schema (Admin Portal)

## 1) Collections Overview

### users
Single identity profile for all authenticated users.

Document ID:
- uid from Firebase Auth

Fields:
- uid: string
- role: string (one of: admin, lawyer, client)
- isActive: boolean
- created_at: timestamp
- updatedAt: timestamp

Example:
{
  "uid": "u_123",
  "role": "admin",
  "isActive": true,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}

---

### lawyers
Lawyer business profile and verification state.

Document ID:
- uid of the lawyer user (recommended)

Fields:
- role: string (lawyer)
- lawyer: map
  - name: string
  - email: string
  - phone: string
  - city: string
  - category: string
  - experienceYears: string
  - consultationFee: string
  - bio: string
  - paymentMethods: array<string>
- cnic_url: string
- bar_id_url: string
- isVerified: boolean
- verification_status: string (pending, approved, rejected)
- verified_by: string (admin uid, optional)
- verified_at: timestamp (optional)
- rejection_reason: string (optional)
- createdAt: timestamp
- updatedAt: timestamp

Example:
{
  "role": "lawyer",
  "lawyer": {
    "name": "Ahsaan Khan",
    "email": "ahsaan@example.com",
    "phone": "03123456789",
    "city": "Lahore",
    "category": "Criminal",
    "experienceYears": "5",
    "consultationFee": "5000",
    "bio": "High-court practitioner",
    "paymentMethods": ["Easypaisa", "JazzCash"]
  },
  "cnic_url": "https://...",
  "bar_id_url": "https://...",
  "isVerified": false,
  "verification_status": "pending",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}

---

### clients
Client profile data.

Document ID:
- uid of the client user (recommended)

Fields:
- user_id: string
- preferred_contact: string (optional)
- created_at: timestamp
- updated_at: timestamp

---

### complaints
Client complaint records linked to lawyer and client.

Document ID:
- auto-id

Fields:
- client_id: string (uid)
- lawyer_id: string (uid)
- title: string
- description: string
- status: string (open, resolved)
- resolution_note: string (optional)
- created_at: timestamp
- updated_at: timestamp
- resolved_at: timestamp (optional)
- resolved_by: string (admin uid, optional)

Example:
{
  "client_id": "u_client_11",
  "lawyer_id": "u_lawyer_01",
  "title": "Delayed response",
  "description": "No response for 3 days.",
  "status": "open",
  "created_at": "serverTimestamp",
  "updated_at": "serverTimestamp"
}

## 2) Role Strategy

Recommended role source:
- users/{uid}.role

Optional faster checks:
- add custom claim role in Firebase Auth token
- keep users doc as source-of-truth for admin tooling and audits

## 3) Verification Workflow

1. Lawyer uploads CNIC and Bar Council ID URLs.
2. lawyers/{uid} created with:
   - is_verified = false
   - verification_status = pending
3. Admin reviews docs and updates:
   - is_verified = true
   - verification_status = approved
   - verified_by, verified_at
4. If rejected:
   - is_verified = false
   - verification_status = rejected
   - rejection_reason

## 4) Index Recommendations

- complaints: composite index on (status ASC, created_at DESC)
- complaints: composite index on (lawyer_id ASC, created_at DESC)
- complaints: composite index on (client_id ASC, created_at DESC)
- lawyers: index on (verification_status ASC, created_at DESC)
