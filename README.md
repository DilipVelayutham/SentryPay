# 🛡️ SentryPay
### Cognitive Multi-Layer Fraud Prevention Payment App

SentryPay is a secure digital payment application designed to **prevent fraud in digital transactions** using a multi-layer intelligent security system.

This project was developed as a prototype for the **Cybersecurity Hackathon – Strengthening Fraud Prevention in Digital Payment Systems.**

---

## 🚀 Features

- Secure QR Payment System
- Scam QR Detection
- AI-Inspired Intent Verification
- Live Liveness Authentication
- Scam Language Detection
- Multi-Layer Fraud Prevention

---

<details>
<summary>📌 Problem Statement</summary>

Digital payment platforms are increasingly targeted by fraudsters through **QR scams, phishing messages, and social engineering attacks**.  
Users often unknowingly authorize fraudulent transactions.

This project addresses the challenge of:

**"Strengthening Fraud Prevention in Digital Payment Systems."**

SentryPay introduces a **multi-layer defense architecture** to detect and prevent fraudulent payment attempts before the transaction is completed.

</details>

---

<details>
<summary>💡 Proposed Solution</summary>

SentryPay implements a **Cognitive Multi-Layer Fraud Prevention System** that protects users during digital payments.

The system integrates four intelligent security layers:

1. **Scam Language Detection**  
   Detects suspicious or manipulative language in payment requests.

2. **QR Code Intelligence**  
   Analyzes QR code data and flags potentially malicious payment receivers.

3. **Intent Verification AI**  
   Confirms the user's payment intent before allowing transactions.

4. **Live Liveness Authentication**  
   Uses facial liveness detection (blink detection) to verify a real user.

These layers work together to **prevent fraudulent payments before completion**.

</details>

---

<details>
<summary>⚙️ System Workflow</summary>

1. User opens **SentryPay**
2. User scans a **QR code**
3. System analyzes the QR data
4. Fraud detection engine checks risk
5. If **safe → payment page opens**
6. If **fraud → scam alert is shown**
7. User authentication verifies identity
8. Transaction proceeds securely

</details>

---

<details>
<summary>🧠 Security Layers</summary>

### 1️⃣ Scam Language Detection
Detects suspicious messages such as:
- "Urgent payment required"
- "Limited time offer"
- "Immediate transfer needed"

### 2️⃣ QR Code Intelligence
Evaluates the receiver identity and risk score.

### 3️⃣ Intent Verification AI
Confirms whether the user truly intends to make the payment.

### 4️⃣ Liveness Authentication
Ensures the transaction is authorized by a real human.

</details>

---

<details>
<summary>🛠️ Tech Stack</summary>

**Frontend**
- Flutter
- Dart

**Backend (Conceptual)**
- Firebase
- REST APIs

**Security & AI Modules**
- NLP for scam language detection
- QR intelligence analysis
- Fraud risk scoring

</details>

---

<details>
<summary>📱 Application Screens</summary>

- Home Dashboard
- People Payment Interface
- QR Scanner
- Fraud Detection System
- Secure Payment Page
- Scam Alert Popup

</details>

---

<details>
<summary>🔐 Example Fraud Detection</summary>

### Legit QR