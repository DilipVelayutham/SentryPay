from fastapi import FastAPI
from pydantic import BaseModel

from transformers import (
    DistilBertTokenizerFast,
    DistilBertForSequenceClassification
)

import torch
import re
import tldextract

# =========================
# FASTAPI
# =========================

app = FastAPI()

# =========================
# LOAD MODEL
# =========================

MODEL_NAME = "Diva41/sentrypay-model"

print("\nLOADING MODEL...")

tokenizer = DistilBertTokenizerFast.from_pretrained(
    MODEL_NAME
)

model = DistilBertForSequenceClassification.from_pretrained(
    MODEL_NAME
)

model.eval()

print("MODEL LOADED SUCCESSFULLY")

# =========================
# TRUSTED DOMAINS
# =========================

trusted_domains = {

    # GOVERNMENT
    "gov.in",
    "nic.in",

    # EDUCATION
    "edu",
    "ac.in",
    "rmkec.ac.in",

    # TECH
    "google.com",
    "microsoft.com",
    "amazon.com",
    "github.com",
    "openai.com",
    "firebase.google.com",

    # BANKS
    "sbi.co.in",
    "onlinesbi.sbi",
    "yono.sbi",
    "hdfcbank.com",
    "icicibank.com",
    "axisbank.com",
    "kotak.com",
    "yesbank.in",

    # PAYMENTS
    "paytm.com",
    "phonepe.com",
    "bharatpe.com"
}

# =========================
# SAFE TLDs
# =========================

trusted_tlds = {

    "gov",
    "edu",
    "bank",
    "bank.in"
}

# =========================
# SUSPICIOUS DOMAINS
# =========================

suspicious_domains = [

    "bit.ly",
    "tinyurl",
    "grabify",
    "ngrok",
    "rebrand.ly",
    "verify-login",
    "secure-wallet",
    "freegift",
    "claim-reward",
    "update-bank",
    "wallet-verification",
    "upi-verify",
    "secure-auth",
    "bonus-reward"
]

# =========================
# SUSPICIOUS TLDs
# =========================

suspicious_tlds = {

    "xyz",
    "top",
    "ru",
    "tk",
    "ml",
    "cf",
    "gq"
}

# =========================
# PHISHING CONTEXT
# =========================

phishing_keywords = [

    "otp",
    "one time password",
    "verification code",
    "security code",
    "share code",
    "authentication code",
    "verify account",
    "urgent action",
    "login immediately",
    "confirm password",
    "click immediately",
    "account suspended",
    "kyc update",
    "wallet blocked",
    "share otp",
    "bank verification",

    # NEW
    "free reward",
    "claim reward",
    "bonus reward",
    "free money",
    "click here",
    "limited offer",
    "win cash",
    "exclusive offer",
    "gift reward"
]

# =========================
# SAFE CONTEXT
# =========================

safe_business_words = [

    "delivery",
    "shipment",
    "package",
    "interview",
    "application",
    "invoice",
    "booking",
    "meeting",
    "salary",
    "payment successful",
    "transaction completed",
    "parcel",
    "exam",
    "college",
    "project",
    "class",
    "assignment",
    "thank you",
    "hello",
    "good morning",
    "family",
    "lunch",
    "movie",
    "notes"
]

# =========================
# REQUEST MODEL
# =========================

class MessageRequest(BaseModel):

    message: str

# =========================
# URL EXTRACTOR
# =========================

def extract_urls(text):

    pattern = r'(https?://\S+|www\.\S+)'

    return re.findall(pattern, text)

# =========================
# URL SUSPICION
# =========================

def is_suspicious_url(url):

    lower_url = url.lower()

    for item in suspicious_domains:

        if item in lower_url:
            return True

    return False

# =========================
# HOME ROUTE
# =========================

@app.get("/")

def home():

    return {
        "status": "SentryPay AI Running"
    }

# =========================
# MAIN PREDICTION
# =========================

@app.post("/predict")

async def predict(data: MessageRequest):

    text = data.message

    lower_text = text.lower()

    reasons = []
    matched_keywords = []
    matched_safe_words = []

    # =========================
    # AI MODEL
    # =========================

    inputs = tokenizer(

        text,

        return_tensors="pt",

        truncation=True,

        padding=True,

        max_length=64
    )

    with torch.no_grad():

        outputs = model(**inputs)

        probs = torch.nn.functional.softmax(
            outputs.logits,
            dim=-1
        )

    safe_prob = probs[0][0].item()

    scam_prob = probs[0][1].item()

    risk_score = scam_prob * 100

    # =========================
    # CONTEXT ANALYSIS
    # =========================

    suspicious_context = False

    suspicious_context = False

    for keyword in phishing_keywords:

        if keyword in lower_text:

            suspicious_context = True

            matched_keywords.append(keyword)

    if matched_keywords:

        risk_score += min(
        len(matched_keywords) * 8,
        25
        )

        reasons.append(
        "Sensitive verification/banking language detected"
        )

        reasons.append(
        "Detected Suspicious Keywords: " +
        ", ".join(matched_keywords)
    )

    # =========================
    # SAFE CONTEXT
    # =========================

    safe_context = False

    for word in safe_business_words:

        if word in lower_text:

         safe_context = True

         matched_safe_words.append(word)

    if matched_safe_words:

        risk_score -= 15

        reasons.append(
        "Legitimate conversational/business context detected"
    )

        reasons.append(
        "Safe Context Words: " +
        ", ".join(matched_safe_words)
    )

    # =========================
    # URL ANALYSIS
    # =========================

    urls = extract_urls(text)

    trusted_found = False

    suspicious_found = False

    for url in urls:

        lower_url = url.lower()

        extracted = tldextract.extract(lower_url)

        root_domain = f"{extracted.domain}.{extracted.suffix}"

        # =========================
        # HTTP LINK DETECTION
        # =========================

        if lower_url.startswith("http://"):

            suspicious_found = True

            risk_score += 35

            reasons.append(
                "Non-HTTPS insecure URL detected"
            )

        # =========================
        # TRUSTED DOMAIN
        # =========================

        if (

            root_domain in trusted_domains

            or extracted.suffix in trusted_tlds

            or root_domain.endswith(".gov.in")

            or root_domain.endswith(".ac.in")

            or root_domain.endswith(".edu")

            or root_domain.endswith(".bank")

            or root_domain.endswith(".bank.in")
        ):

            trusted_found = True

            risk_score -= 40

            reasons.append(
                "Trusted official/banking domain detected"
            )

        # =========================
        # SUSPICIOUS DOMAIN
        # =========================

        if is_suspicious_url(lower_url):

            suspicious_found = True

            risk_score += 25

            reasons.append(
                "Suspicious URL pattern detected"
            )

        # =========================
        # SUSPICIOUS TLD
        # =========================

        if extracted.suffix in suspicious_tlds:

            suspicious_found = True

            risk_score += 20

            reasons.append(
                "Suspicious domain extension detected"
            )

        # =========================
        # FAKE BANKING IMPERSONATION
        # =========================

        banking_words = [

            "bank",
            "verify",
            "wallet",
            "login",
            "kyc",
            "secure",
            "otp",
            "payment"
        ]

        for word in banking_words:

            if word in extracted.domain:

                if root_domain not in trusted_domains:

                    suspicious_found = True

                    risk_score += 20

                    reasons.append(
                        "Potential banking impersonation detected"
                    )

    # =========================
    # FINAL CALIBRATION
    # =========================

    if trusted_found and safe_context and not suspicious_found:

        risk_score -= 25

    if trusted_found and not suspicious_context and not suspicious_found:

        risk_score -= 15

    if safe_context and not suspicious_context and not suspicious_found:

        risk_score -= 20

    if suspicious_context and suspicious_found:

        risk_score += 15

    # NEVER ALLOW VERY SUSPICIOUS
    # URLS TO BECOME SAFE

    if suspicious_found and risk_score < 45:

        risk_score = 45

    # =========================
    # NORMALIZE
    # =========================

    risk_score = max(1, min(risk_score, 99))

    # =========================
    # FINAL STATUS
    # =========================

    if risk_score >= 75:

        status = "SUSPICIOUS"

        reasons.append(
            "Strong phishing/scam indicators detected"
        )

    elif risk_score >= 40:

        status = "MODERATE"

        reasons.append(
            "Potentially sensitive or suspicious message"
        )

    else:

        status = "SAFE"

        reasons.append(
            "Message appears contextually safe"
        )

    # REMOVE DUPLICATES
    reasons = list(set(reasons))

    return {

    "status": status,

    "risk": round(risk_score, 2),

    "confidence": round(
        scam_prob * 100,
        2
    ),

    "reason": reasons,

    "suspicious_keywords": matched_keywords,

    "safe_keywords": matched_safe_words
}