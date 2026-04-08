# LawLink: Admin Portal and Lawyer Verification Workflow

## 1) Registration and Initial State

### Lawyer Sign-up
- Lawyer registers account with:
  - Full name
  - Specialization
  - Consultation fee
  - CNIC document
  - Bar Council ID document

### Database Entry
- On registration, lawyer profile is created with:
  - isVerified: false
  - verification_status: pending

### Access Restriction
- Until admin approval:
  - Lawyer does not appear in client discovery/search results
  - Lawyer is blocked from full dashboard access (pending verification flow)

## 2) Admin Portal Workflow (Step-by-Step)

Admin portal is desktop/laptop optimized and supports the following flow:

### Step 1: Dashboard Monitoring
- Admin monitors:
  - Pending verification requests
  - Platform activity metrics
  - Recent registrations

### Step 2: Document Review
- Admin reviews uploaded documents:
  - CNIC
  - Bar Council ID
- Goal:
  - Prevent fake/invalid lawyer accounts

### Step 3: Approval or Rejection
- Approve:
  - Set isVerified = true
  - Set verification_status = approved
  - Optionally set verified_by and verified_at
- Reject:
  - Keep isVerified = false
  - Set verification_status = rejected
  - Optionally set rejection_reason

### Step 4: Complaint Handling
- Admin manages complaints submitted by clients:
  - Track open/resolved status
  - Review linked client and lawyer accounts
  - Resolve and close complaint records

## 3) Lawyer Pending Screen Logic (Flutter)

### Login Guard
- On lawyer login:
  - Read lawyers/{uid}.isVerified

### Conditional Navigation
- If isVerified == false:
  - Redirect to PendingVerificationScreen
  - Show message that account is under admin review
- If isVerified == true:
  - Open lawyer dashboard

## 4) Search Filtering Rule (Client Side)

### Verified Lawyers Only
- Client-side lawyer search must query only:
  - lawyers where isVerified == true
- Unverified lawyers must never appear in search results

## 5) Security Model (Firestore)

### Admin-only Verification Updates
- Only users with role = admin can update:
  - isVerified
  - verification_status
  - verified_by
  - verified_at

### Lawyer Self-access
- Lawyer can update own non-verification profile fields
- Lawyer cannot self-approve verification fields

## 6) Data Model Snapshot

### users
- uid
- role (admin/lawyer/client)
- name, email, phone
- created_at, updated_at

### lawyers
- user_id
- specialization
- consultation_fee
- cnic_url
- bar_id_url
- isVerified
- verification_status
- verified_by
- verified_at
- created_at, updated_at

### clients
- user_id
- profile fields
- created_at, updated_at

### complaints
- client_id
- lawyer_id
- status (open/resolved)
- title, description
- resolution_note
- created_at, updated_at

## 7) AI Generation Prompt (Reusable)

Task:
Build a Lawyer Verification System for LawLink using React (Admin Dashboard) and Flutter (Mobile App) with Firebase.

Requirements:
- Database Schema:
  - lawyers collection with cnic_url, bar_id_url, isVerified (boolean)
- Mobile Logic (Flutter):
  - Auth Guard redirects unverified lawyers to PendingVerificationScreen
- Admin UI (React):
  - Desktop-optimized verification table with Approve and Reject actions
- Security:
  - Firestore rules where only role == admin can change isVerified and verification metadata
- Search:
  - Client search returns only lawyers where isVerified == true

## 8) Current Project Integration Notes

This workflow aligns with the current LawLink codebase where:
- Flutter auth guard and pending verification flow are implemented
- React admin verification action service is implemented
- Verified-only lawyer search behavior is implemented
- Firestore rules include admin-only verification updates
