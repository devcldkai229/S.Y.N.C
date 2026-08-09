# PRIVACY POLICY — SYNC

**Version:** 1.0
**Effective date:** {{EFFECTIVE_DATE}}
**Applies to:** the SYNC mobile app (Android — package `{{PLAY_PACKAGE_NAME}}`), the website `{{WEBSITE}}`, and all related services.
**Governing language:** Vietnamese. This English version is provided for convenience; in case of any discrepancy, the Vietnamese version at `/privacy` prevails.

---

## 1. Who we are

| Item | Details |
|---|---|
| Data controller | **{{LEGAL_ENTITY_NAME_EN}}** ({{LEGAL_ENTITY_NAME}}) |
| Business registration no. | {{BUSINESS_REG_NO}}, issued on {{BUSINESS_REG_DATE}} by {{BUSINESS_REG_AUTHORITY}} |
| Registered office | {{REGISTERED_ADDRESS}} |
| Legal representative | {{REPRESENTATIVE_NAME}} |
| Data protection contact | {{DPO_NAME}} — {{PRIVACY_EMAIL}} |
| User support | {{SUPPORT_EMAIL}} |

In this policy, "SYNC", "we", "us" means {{LEGAL_ENTITY_NAME_EN}}; "you" means the user of the service.

**What SYNC is:** an AI-assisted lifestyle platform providing an AI coach (CYN AI), personalised training roadmaps, nutrition tracking, a community layer (posts, stories, challenges), and in-app food ordering from partner merchants.

---

## 2. Our core commitments

1. **We do NOT sell your personal data** to anyone, in any form.
2. **We do NOT use your data to train AI models** — ours or any third party's. See §6.
3. **The app contains NO advertising SDKs, no ad networks, no cross-app tracking, and no advertising identifiers.**
4. **Data minimisation:** we collect only what a feature you actually use requires. Most of the app works without granting location, camera, or microphone access.
5. **You are in control:** every piece of data can be viewed, corrected, exported, or deleted — see §9.

> If we ever change any commitment above, this policy will be updated and you will be notified **before** the change takes effect (§13).

---

## 3. Data we collect (detailed inventory)

The tables below list exactly what the system stores, matching the product's actual data structures. "Required" indicates whether the app is usable without providing it.

### 3.1. Identity & account data

| Field | Purpose | Required | Legal basis | Storage |
|---|---|---|---|---|
| Email | Login identifier, verification, password recovery | ✅ Yes | Contract performance | PostgreSQL (AWS Singapore) |
| Password | Stored as a **one-way hash** — we never see your plaintext password | ✅ (unless using Google) | Contract performance | PostgreSQL |
| Full name | Display in-app and in the community | ✅ Yes | Contract performance | PostgreSQL |
| Phone number | Optional; used for order delivery | ❌ No | Contract performance | PostgreSQL |
| Avatar / cover image | Optional | ❌ No | Consent | S3 (Singapore) |
| Google account ID / ID token | Only if you choose "Sign in with Google" | ❌ No | Consent | Token not stored; only email + name returned by Google |
| Language, time zone | Localised content and correctly timed reminders | ✅ (automatic) | Legitimate interest | PostgreSQL |
| Account status, subscription tier (Free/Premium/Ultra), role | Feature entitlement | ✅ Yes | Contract performance | PostgreSQL |
| Last login / last active timestamps | Security, anomalous access detection | ✅ Yes | Legitimate interest | PostgreSQL |

### 3.2. Health & fitness data — **SENSITIVE PERSONAL DATA**

Vietnamese law classifies health data as **sensitive personal data**. We process this category **only when you actively provide it**, on the basis of your **separate, explicit consent** given during profile setup.

| Field | Specific purpose | Required |
|---|---|---|
| Sex, date of birth | Compute BMR/TDEE (Mifflin-St Jeor); verify minimum age | ✅ Yes (for coaching features) |
| Height, current weight, target weight | Energy requirements, roadmap design | ✅ Yes |
| Body fat %, muscle mass (current & goal) | Goal refinement, progress assessment | ❌ No |
| Fitness goal, activity level, experience level, preferred training location | Roadmap generation | ✅ Yes |
| **Injuries** (past/current) | Exclude risky exercises from your plan | ❌ No — strongly recommended for safety |
| **Medications** | Flag interactions with diet/training; **never** used for diagnosis | ❌ No |
| **Food allergies** | Absolute block on suggesting allergen-containing items | ❌ No — strongly recommended for safety |
| Biometric history over time (weight, body fat, muscle, notes) | Progress charts; automatic calorie/macro target adjustment | Automatic when you log |
| Daily calorie & macro targets, BMR, TDEE | Basis for nutrition guidance | Computed automatically |
| Recovery profile, workout execution logs, per-set logs (reps, load) | Training load measurement, overtraining detection | Automatic when you log |
| Meal logs, daily nutrition summaries | Diet tracking | Automatic when you log |

> **We do NOT collect:** data from OS health platforms or wearables (Google Fit / Health Connect / Apple Health), medical records, lab results, genetic data, or identifying biometrics (fingerprint, face).

### 3.3. AI-derived data

The system computes **inferred** signals from your behaviour. We disclose them transparently because they are also personal data:

| Signal | Meaning | Effect on you |
|---|---|---|
| Adherence score | How closely you follow the plan | Adjusts plan difficulty |
| Burnout risk score | Overtraining signals | Suggests deload/rest |
| Churn risk score | Likelihood of disengaging | Adjusts reminder frequency and tone |
| Motivation, recovery, nutrition/workout compliance scores | Personalisation | Content of suggestions |
| Peak energy window, current mood, preferred intervention style | Timing and style of nudges | When notifications are sent |
| AI reasoning snapshot for AI-initiated spending/orders | Traceability & accountability | You may request to see it |

**Right to object:** you may ask us to stop using this derived data for personalisation (turn off SmartPush / withdraw the data-sharing consent in Settings). The app keeps working, but guidance becomes generic.

### 3.4. Content you create

| Type | Note |
|---|---|
| Posts, comments, blogs, attached images/videos | **Public** to other users if you set them public |
| Stories (image/video/text) | Auto-expire after 24 hours; other users' views/likes are recorded |
| Follows, likes, community challenge participation | Partly public |
| Merchant/product reviews | Public with your display name |
| Content reports | Visible only to the moderation team; the reporter's identity is **never** disclosed to the reported party |
| Conversations with CYN AI | Private — see §6 |

### 3.5. Location

| Form | When collected | Required |
|---|---|---|
| Precise location (GPS) | **Only with your permission and only while you use the feature**: finding nearby merchants, delivery fee calculation, confirming a delivery address | ❌ No — you may enter an address manually |
| Order delivery coordinates | Stored with the order so couriers reach the right place | Only when you place an order |
| Courier location during delivery | Provided by the delivery partner, shown to you for tracking | Only while an order is in transit |

**We do NOT collect background location.** The app does not declare `ACCESS_BACKGROUND_LOCATION`.

### 3.6. Camera, photo library, microphone

| Permission | Used for | Required |
|---|---|---|
| Camera | Capture photos for posts/stories/avatar | ❌ No |
| Photo library | Pick existing images via the OS photo picker | ❌ No |
| Microphone | Voice conversation with CYN AI | ❌ No |

We never access the camera or microphone silently. Images and audio are uploaded only when you deliberately post or send them.

### 3.7. Transactions & payments

| Data | Note |
|---|---|
| Food orders: items, quantity, notes, total, discount code | PostgreSQL |
| Delivery address, coordinates, recipient name and phone | PostgreSQL |
| Transactions: amount, method (Wallet/COD/VietQR/MoMo/Google Play), status, provider reference | PostgreSQL |
| Internal wallet and wallet ledger | PostgreSQL |
| Subscription: tier, status, start/expiry, auto-renew, purchase source | PostgreSQL |
| "AI-initiated transaction" flag + spending limits you set | Protects you from unintended spend |

> **We do NOT store card numbers, CVV, or banking credentials.** All payment steps happen on the payment provider's infrastructure (Google Play, PayOS, MoMo). We receive only a transaction reference and status.

### 3.8. Device & technical data

| Data | Purpose |
|---|---|
| App-generated device identifier, platform (Android/iOS/Web), app version | Session management, technical support |
| Push notification token | Sending reminders (only if you enable them) |
| Refresh token (stored hashed) and expiry | Secure persistent login |
| Error and operational logs, server-side IP addresses | Security, abuse prevention, troubleshooting |

**We do NOT use:** advertising IDs, device fingerprinting, or commercial third-party analytics SDKs.

---

## 4. Why we process data (purposes & legal bases)

| Purpose | Data used | Basis |
|---|---|---|
| Creating and operating your account | §3.1 | Contract performance |
| Personalised training and nutrition targets | §3.2, §3.3 | **Separate consent for sensitive data** |
| AI assistant answering and performing requested tasks | §3.1–3.4 (minimised, see §6) | Contract performance + consent |
| Smart reminders (SmartPush) | §3.2, §3.3 | Consent (toggle in Settings) 🔧 |
| Community features and content moderation | §3.4 | Contract performance + legitimate interest (community safety) |
| Food ordering and delivery | §3.5, §3.7 | Contract performance |
| Payments, invoicing, fraud prevention | §3.7, §3.8 | Contract performance + legal obligation |
| System security, abuse investigation | §3.8 | Legitimate interest |
| Aggregate product analytics | **Aggregated / de-identified** data | Legitimate interest |
| Marketing communications | Email, name | **Consent** (`MarketingConsent`, OFF by default) |

---

## 5. Who we share data with

We share only in the cases below, under contracts containing confidentiality and purpose-limitation terms.

### 5.1. Service providers (data processors)

| Recipient | Data shared | Purpose | Processing location |
|---|---|---|---|
| **Amazon Web Services (AWS)** | All application data (stored, not read) | Servers, databases, file storage, CDN | **Singapore (ap-southeast-1)**; CDN has global edge locations |
| **OpenAI, L.L.C.** | Your message content + minimal, PII-redacted context (see §6) | Generating AI assistant responses | United States |
| **Google LLC** — Play Billing & Play Developer API | Transaction token, product ID, subscription status | Verifying and syncing subscriptions purchased via Google Play | United States / global |
| **Google LLC** — Google Sign-In | Email, name, avatar you authorise | Google login | United States / global |
| **PayOS / MoMo** (Vietnamese payment intermediaries) | Amount, order code, data needed to collect payment | Payment processing | Vietnam |
| **Ahamove** (delivery partner) | Delivery address, coordinates, recipient name and phone, order contents | Delivery and tracking | Vietnam |
| **Partner merchants** in the app | Order contents, recipient name and phone, notes | Preparing and handing over the order | Vietnam |
| **Brevo (Sendinblue)** | Email, name, transactional message content | Verification / password-reset emails | European Union |
| **Tavily** | **Only the search query string** generated by the AI — never your identity | Looking up public information when you ask external-knowledge questions | United States |
| **OpenStreetMap Foundation** | Map tile requests (including technical IP) | Rendering maps | Global |

### 5.2. Public sharing

Content you post publicly (posts, stories, comments, reviews, challenge leaderboards) is visible to other users together with your name and avatar. **This is your choice** and can be changed in privacy settings.

### 5.3. Legal requests

We may disclose data upon a lawful, written request from a competent authority, or where necessary to protect life or user safety. We review the validity of every request and disclose only the minimum required.

### 5.4. Business transfers

In a merger or transfer of the business, data may transfer with the service. You will be notified in advance and may delete your account before the transfer takes effect.

### 5.5. International transfers

Some data is processed outside Vietnam (AWS Singapore; OpenAI and Google in the United States; Brevo in the EU). We apply: data processing agreements with confidentiality terms, encryption in transit, and minimisation plus PII redaction before sending anything to AI providers.
🔧 *Before publication: complete and retain the **cross-border personal data transfer impact assessment dossier** required by Vietnamese personal data protection law, and file it with the competent authority where required.*

---

## 6. How the AI works with your data

This is the most important section, since the AI assistant is the core feature.

### 6.1. What is sent to the AI model provider

When you chat with CYN AI, the system sends OpenAI:

- the message content you typed;
- a **minimal context summary** needed for the answer (e.g. fitness goal, today's calorie target, today's workout, allergy list);
- recent conversation history within the session.

**Before data leaves our infrastructure, it passes through an automated PII redaction layer** (removes/replaces phone numbers, emails, national ID numbers, and card numbers in Vietnamese formats).

### 6.2. What is NOT sent

- Passwords, tokens, or wallet details beyond the scope of your question.
- Your photos or videos — **AI image analysis is currently DISABLED**.
- Other users' data. The AI can only access data within your own account.

### 6.3. Model-training commitment

We use OpenAI through its **business API**. Under OpenAI's API terms, **data submitted via the API is not used to train its models**. OpenAI may retain data for up to 30 days for abuse monitoring, after which it is deleted.
We also **do not** use your conversations to train any SYNC-owned model.

### 6.4. The AI's long-term memory

So the assistant can "remember" you across sessions, the system stores:

| Type | Content | Location | Deleted when |
|---|---|---|---|
| Long-term memory | Condensed facts/preferences (e.g. "prefers morning workouts", "no seafood") + semantic vectors | PostgreSQL (AWS Singapore) | You delete your account, or request AI-memory deletion |
| Conversation state | Session chat history | Redis (AWS Singapore) | On session timeout |
| Semantic cache | Answers already generated for similar questions | Redis | Auto-expires after **24 hours** |
| Pending confirmations | Orders/spend awaiting your confirmation | Redis | Auto-expires after **30 minutes** |
| Per-turn audit log | **Metadata only**: trace ID, intent, model tier, locale, timing, cost — **no raw content** | PostgreSQL | Per the retention schedule in §7 |

### 6.5. AI safety boundaries

- The AI does **not** diagnose conditions, prescribe, or give drug dosages — see the [Health Disclaimer](/health-disclaimer).
- The AI **never** spends your money automatically: every action with a cost requires your explicit confirmation, even if you instruct it to "just order without asking". Automatic spending limits are set by you.
- The AI is configured to **never fabricate personal figures** — all numbers about calories, weight, balance, or schedule come from your real data.
- The AI will never suggest food containing an allergen you have declared.

### 6.6. Your AI-related rights

- Turn off AI-generated notifications and SmartPush at any time.
- Request **deletion of all AI long-term memory** without deleting your account — email {{PRIVACY_EMAIL}}.
- Request an explanation of why the AI made a specific spending recommendation (we store a reasoning snapshot for AI-initiated transactions).
- **You are not subject to solely automated decisions with legal effect.** All AI output is advisory and requires your confirmation.

---

## 7. Retention periods

| Data category | Retention | Status |
|---|---|---|
| Account & profile (while active) | Until you delete your account | ✅ In effect |
| After you request account deletion | **Immediate anonymisation** + **30-day recovery grace period**, then permanent deletion | ✅ In effect (see [Account Deletion](/account-deletion)) |
| Stories | Auto-expire after **24 hours** | ✅ In effect |
| Pending AI confirmations | 30 minutes | ✅ In effect |
| AI semantic cache | 24 hours | ✅ In effect |
| Transaction records, invoices, payment vouchers | **10 years** from creation, as required by Vietnamese accounting law — retained even after account deletion, **separated from identity to the greatest extent possible** | ✅ Commitment |
| Server security & operational logs | 🔧 **90 days** | Log lifecycle configuration pending |
| AI trace logs (metadata) | 🔧 **180 days** | Cleanup job pending |
| Content reports and outcomes | 🔧 **24 months** after case closure (repeat-offence handling and appeals) | Cleanup job pending |
| De-identified aggregate statistics | Indefinite (no longer personal data) | ✅ |

> 🔧 = requires an automated mechanism before this policy is published. **Do not publish while any 🔧 item is unimplemented and the wording is unchanged.**

---

## 8. Security

- **In transit:** all connections use HTTPS/TLS. The Android app fully **disables cleartext traffic** (`usesCleartextTraffic="false"`).
- **Passwords:** one-way hashed, never stored in plaintext, not recoverable.
- **Sessions:** refresh tokens stored hashed; you can revoke them by signing out; account deletion revokes every session on every device.
- **Access control:** microservice architecture where each service accesses only its own data; internal APIs require a separate key.
- **Private files** (personal images, stories) live in a **non-public** storage bucket, accessible only through time-limited signed links.
- **AI abuse controls:** prompt-injection detection, harmful-content filtering, rate limiting.
- **Servers located in Singapore**, with encryption at rest at the cloud service layer.

No system is perfectly secure. In the event of a personal data breach we will **notify you and the competent authority within the statutory deadline**, describing the incident and remediation steps.

---

## 9. Your rights

Under Vietnamese personal data protection law you have the following rights:

| Right | How to exercise |
|---|---|
| **To be informed** about processing | This document + the Profile section in the app |
| **To consent / withdraw consent** | Settings → Privacy (data sharing, marketing, SmartPush) |
| **To access** your data | In-app (Profile, workout/meal/order history) |
| **To correct** inaccurate data | Directly in the app |
| **To data portability** | Email {{PRIVACY_EMAIL}} — we return a machine-readable file within **30 days** 🔧 *export endpoint pending* |
| **To erasure / account deletion** | In-app: Profile → Account → Delete account; or at `{{WEBSITE}}/account-deletion` |
| **To restrict / object to processing** | Email {{PRIVACY_EMAIL}} |
| **To complain** | Email {{PRIVACY_EMAIL}}; if unsatisfied, you may complain to the competent state authority for personal data protection |

**Response times:** we handle simple requests within **72 hours** and complex requests within **30 days** (with notice if an extension is needed). Requests are free of charge; we may refuse excessively repetitive or manifestly unfounded requests, stating our reasons.

**Identity verification:** for your protection, requests must be sent from the email address registered to the account.

---

## 10. Children

SYNC is **for users aged 16 and over**. Users under 18 may use it only with the consent and supervision of a parent or guardian, particularly for payment features.

We do **not knowingly collect** data from children under 16. If we discover such an account we will suspend it and delete the data. Parents or guardians who discover their child has registered should contact {{PRIVACY_EMAIL}} — we will act within **72 hours**.

Because the app contains health data, social networking, and commerce, it is **not** part of any app store's families/kids programme.

---

## 11. Cookies and similar technologies

The mobile app uses **no advertising cookies**. It stores data locally on your device (login tokens in the OS secure storage, display settings).

The website `{{WEBSITE}}` uses only **strictly necessary** cookies/local storage for login and theme preference. No advertising or tracking cookies.

---

## 12. Users outside Vietnam

The service targets users in Vietnam. If you access it from another region (EU/EEA, UK), you still receive rights equivalent to those in §9. Your data will be processed in Singapore and the countries listed in §5.

---

## 13. Changes to this policy

When we update it, we publish the new version at `{{WEBSITE}}/privacy` with its effective date. For **material changes** (broader processing purposes, new data recipients, or changes to the commitments in §2) we will:

1. notify you in-app and by email **at least 15 days before** the effective date; and
2. re-obtain consent where the change concerns sensitive data.

Version history is published so you can compare.

---

## 14. Contact

| Purpose | Channel |
|---|---|
| Personal data, privacy, consent withdrawal | **{{PRIVACY_EMAIL}}** |
| General support, service complaints | **{{SUPPORT_EMAIL}}** |
| Reporting violating content | **{{ABUSE_EMAIL}}** |
| Postal address | {{REGISTERED_ADDRESS}} |

---

*This document reflects the product's actual functionality at the time of issue. Vietnamese original: `/privacy`.*
