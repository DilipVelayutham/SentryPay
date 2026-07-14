from fastapi import FastAPI
from pydantic import BaseModel
from pathlib import Path
import joblib
import re

from src.feature_extractor import extract_features

# =====================================
# FastAPI Setup
# =====================================

app = FastAPI(
    title="SentryPay QR Intelligence API",
    description="Risk Score Engine for QR URLs",
    version="1.0"
)

# =====================================
# Load Model
# =====================================

BASE_DIR = Path(__file__).resolve().parent

MODEL_PATH = BASE_DIR.parent / "models" / "model.pkl"

model = joblib.load(MODEL_PATH)

# =====================================
# Request Schema
# =====================================

class URLRequest(BaseModel):
    url: str


# =====================================
# Health Check
# =====================================

@app.get("/")
def root():
    return {
        "status": "running",
        "service": "SentryPay QR Intelligence Engine"
    }


# =====================================
# Main Analysis Endpoint
# =====================================

@app.post("/analyze")
def analyze(request: URLRequest):

    url = request.url
    url_lower = url.lower()

    # -------------------------
    # ML Prediction
    # -------------------------

    features = extract_features(url)

    probability = model.predict_proba([features])[0][1]

    ml_score = int(probability * 100)

    # -------------------------
    # Rule Engine
    # -------------------------

    rule_score = 0
    reasons = []

    # IP Address Detection

    if re.search(r'(\d{1,3}\.){3}\d{1,3}', url):

        rule_score += 40

        reasons.append(
            "IP address detected"
        )

    # URL Shorteners

    if "bit.ly" in url_lower:

        rule_score += 40

        reasons.append(
            "URL shortener detected"
        )

    if "tinyurl" in url_lower:

        rule_score += 40

        reasons.append(
            "URL shortener detected"
        )

    # Suspicious Keywords

    if "verify" in url_lower:

        rule_score += 25

        reasons.append(
            "Verification keyword detected"
        )

    if "login" in url_lower:

        rule_score += 25

        reasons.append(
            "Login keyword detected"
        )

    if "secure" in url_lower:

        rule_score += 15

        reasons.append(
            "Secure keyword detected"
        )

    if "reward" in url_lower:

        rule_score += 15

        reasons.append(
            "Reward keyword detected"
        )

    if "claim" in url_lower:

        rule_score += 15

        reasons.append(
            "Claim keyword detected"
        )

    if "free" in url_lower:

        rule_score += 10

        reasons.append(
            "Free keyword detected"
        )

    if "upi" in url_lower:

        rule_score += 15

        reasons.append(
            "UPI keyword detected"
        )

    if "payment" in url_lower:

        rule_score += 20

        reasons.append(
            "Payment keyword detected"
        )

    if "wallet" in url_lower:

        rule_score += 10

        reasons.append(
            "Wallet keyword detected"
        )

    # Other Risk Indicators

    if "@" in url:

        rule_score += 15

        reasons.append(
            "@ symbol detected"
        )

    if len(url) > 75:

        rule_score += 10

        reasons.append(
            "Long URL detected"
        )

    # -------------------------
    # Final Hybrid Score
    # -------------------------

    final_score = ml_score + rule_score

    final_score = min(final_score, 100)

    # -------------------------
    # Risk Category
    # -------------------------

    if final_score <= 40:

        risk_level = "LOW"

    elif final_score <= 75:

        risk_level = "MODERATE"

    else:

        risk_level = "HIGH"

    # -------------------------
    # Response
    # -------------------------

    return {
        "url": url,
        "ml_score": ml_score,
        "rule_score": rule_score,
        "risk_score": final_score,
        "risk_level": risk_level,
        "reasons": reasons
    }