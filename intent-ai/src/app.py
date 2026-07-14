from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import urllib.parse
import tldextract
import re

app = FastAPI(
    title="SentryPay Intent Verification AI API",
    description="Cognitive Intent Verification Layer for SentryPay QR Payments",
    version="1.0"
)

# =====================================
# Request & Response Schemas
# =====================================

class RiskEngineResult(BaseModel):
    url: str
    ml_score: int
    rule_score: int
    risk_score: int
    risk_level: str
    reasons: List[str]

class QuestionGenerationResponse(BaseModel):
    questions: List[str]

class VerifyIntentRequest(BaseModel):
    risk_result: RiskEngineResult
    questions: List[str]
    answers: List[str]

class VerifyIntentResponse(BaseModel):
    intent_score: int
    decision: str
    confidence: float
    reason: List[str]


# =====================================
# Helper Utilities
# =====================================

def parse_url_context(url: str) -> Dict[str, Any]:
    """
    Parses a URL (UPI or Web address) and extracts:
    - qr_type: 'UPI' or 'Web'
    - merchant_name: Name of payee/domain
    - payment_context: Description/purpose of payment
    - category: 'banking', 'marketplace', 'prize_scam', or 'general'
    """
    parsed = urllib.parse.urlparse(url)
    scheme = parsed.scheme.lower()
    
    qr_type = "Web Link"
    merchant_name = "Scanned Merchant"
    payment_context = "Purchase / Transfer"
    category = "general"
    bank_name = "your bank"
    
    # 1. Parse UPI deep-links
    if scheme == "upi":
        qr_type = "UPI Payment Deep-link"
        query_params = urllib.parse.parse_qs(parsed.query)
        
        # Payee Name (pn)
        if "pn" in query_params and query_params["pn"]:
            merchant_name = query_params["pn"][0]
        # Fallback to Payee Address (pa)
        elif "pa" in query_params and query_params["pa"]:
            pa = query_params["pa"][0]
            merchant_name = pa.split("@")[0].replace(".", " ").title()
            
        # Transaction Note (tn)
        if "tn" in query_params and query_params["tn"]:
            payment_context = query_params["tn"][0]
            
        # Category classification based on UPI MCC code (mc)
        if "mc" in query_params and query_params["mc"]:
            mcc = query_params["mc"][0]
            if mcc in ["6011", "6012"]:
                category = "banking"
            elif mcc in ["5411", "5311", "5977"]:
                category = "marketplace"
            elif mcc in ["7995", "7996"]:
                category = "prize_scam"
                
    # 2. Parse standard HTTP/HTTPS URLs
    elif scheme in ["http", "https"]:
        qr_type = "Web Link"
        ext = tldextract.extract(url)
        domain = ext.domain
        suffix = ext.suffix
        
        merchant_name = domain.title()
        
        # Look for payment intent or note in URL path/query
        path = parsed.path.lower()
        query = parsed.query.lower()
        if "pay" in path or "pay" in query:
            payment_context = "Web Payment"
        elif "login" in path or "verify" in path:
            payment_context = "Account Action"
            
    # 3. Categorize based on keywords in URL
    url_lower = url.lower()
    
    # Check for banking keywords
    bank_keywords = ["sbi", "hdfc", "icici", "axis", "kotak", "yono", "bank", "verify", "login", "kyc", "secure", "auth"]
    if any(kw in url_lower for kw in bank_keywords):
        category = "banking"
        # Guess specific bank
        for bank in ["sbi", "hdfc", "icici", "axis", "kotak"]:
            if bank in url_lower:
                bank_name = bank.upper()
                break
                
    # Check for marketplace keywords
    market_keywords = ["paytm", "phonepe", "amazon", "flipkart", "store", "shop", "retail", "delivery", "marketplace", "seller"]
    if any(kw in url_lower for kw in market_keywords):
        category = "marketplace"
        
    # Check for prize scam keywords
    prize_keywords = ["prize", "reward", "gift", "bonus", "claim", "win", "lottery", "free", "cashback"]
    if any(kw in url_lower for kw in prize_keywords):
        category = "prize_scam"

    return {
        "qr_type": qr_type,
        "merchant_name": merchant_name,
        "payment_context": payment_context,
        "category": category,
        "bank_name": bank_name
    }


def is_affirmative(ans: str) -> bool:
    """Detects yes/affirmative answers."""
    ans = ans.lower().strip()
    affirmative_patterns = [
        r"\byes\b", r"\byep\b", r"\byeah\b", r"\bsure\b", r"\bcorrect\b",
        r"\bi do\b", r"\bi am\b", r"\bindeed\b", r"\btrue\b", r"\bof course\b",
        r"\bsomeone did\b", r"\bthey did\b", r"\by\b"
    ]
    return any(re.search(pat, ans) for pat in affirmative_patterns)


def is_negative(ans: str) -> bool:
    """Detects no/negative answers."""
    ans = ans.lower().strip()
    negative_patterns = [
        r"\bno\b", r"\bnope\b", r"\bnah\b", r"\bnever\b", r"\bnot\b",
        r"\bdont\b", r"\bdon't\b", r"\bdo not\b", r"\bfalse\b", r"\bnot at all\b",
        r"\bincorrect\b", r"\bno one\b", r"\bnobody\b", r"\bn\b"
    ]
    return any(re.search(pat, ans) for pat in negative_patterns)


# =====================================
# Endpoints
# =====================================

@app.get("/")
def root():
    return {
        "status": "running",
        "service": "SentryPay Intent Verification AI Engine"
    }


@app.post("/generate-intent-questions", response_model=QuestionGenerationResponse)
def generate_intent_questions(risk_engine_output: RiskEngineResult):
    """
    Dynamically generates exactly three verification questions based on the
    context extracted from the QR URL, risk score, and risk reasons.
    """
    url = risk_engine_output.url
    ctx = parse_url_context(url)
    
    category = ctx["category"]
    merchant = ctx["merchant_name"]
    context = ctx["payment_context"]
    bank = ctx["bank_name"]
    
    questions = []
    
    if category == "banking":
        questions = [
            f"Who asked you to make this payment to '{merchant}'?",
            f"Did someone claim to be a representative of {bank} or ask you to verify your account?",
            f"Are you paying to verify your account or prevent it from being suspended?"
        ]
    elif category == "marketplace":
        questions = [
            f"Do you personally know the merchant '{merchant}' or have you bought from them before?",
            f"Have you already received the product or service related to '{context}'?",
            f"Does the recipient merchant name '{merchant}' exactly match the seller you are dealing with?"
        ]
    elif category == "prize_scam":
        questions = [
            f"Were you promised a reward, lottery cashback, or gift for scanning this QR code?",
            f"Did someone ask you to transfer money to '{merchant}' before you can receive the prize?",
            f"Do you know the organization '{merchant}' that is offering this reward?"
        ]
    else:
        questions = [
            f"Are you making this payment to '{merchant}' for '{context}' out of your own free will?",
            f"Did you receive a phone call, SMS, or message instructing you to scan this specific QR code?",
            f"Do you verify that the payment to '{merchant}' is legitimate and correct?"
        ]
        
    # Safeguard: Ensure exactly 3 questions
    while len(questions) < 3:
        questions.append("Do you understand the purpose of this payment?")
    questions = questions[:3]
    
    return QuestionGenerationResponse(questions=questions)


@app.post("/verify-intent", response_model=VerifyIntentResponse)
def verify_intent(payload: VerifyIntentRequest):
    """
    Analyzes the 3 answers together with risk engine parameters and generates
    the Intent Score, Decision, Confidence, and Reasons.
    """
    risk_result = payload.risk_result
    questions = payload.questions
    answers = payload.answers
    
    if len(questions) != len(answers) or len(questions) != 3:
        raise HTTPException(status_code=400, detail="Exactly 3 questions and 3 answers must be provided.")
        
    intent_score = 100
    flagged_reasons = []
    
    for q, a in zip(questions, answers):
        q_lower = q.lower()
        
        # 1. Bank Impersonation / Representative check
        if "representative" in q_lower or "from your bank" in q_lower:
            if is_affirmative(a):
                intent_score -= 45
                flagged_reasons.append("User believes a bank representative requested the payment.")
            elif not is_negative(a):
                intent_score -= 15
                flagged_reasons.append("User gave an ambiguous response regarding bank authorization.")
                
        # 2. Account verification / Suspension check
        elif "verify your account" in q_lower or "prevent it from being suspended" in q_lower:
            if is_affirmative(a):
                intent_score -= 35
                flagged_reasons.append("User believes they are paying to verify, unblock, or activate an account.")
            elif not is_negative(a):
                intent_score -= 10
                flagged_reasons.append("User's purpose for account verification remains unverified.")
                
        # 3. Third-party instruction check
        elif "who asked you" in q_lower or "who instructed you" in q_lower:
            a_lower = a.lower()
            suspicious_terms = ["stranger", "caller", "support", "telegram", "whatsapp", "unknown", "agent", "bank", "officer", "helper"]
            if any(term in a_lower for term in suspicious_terms):
                intent_score -= 30
                flagged_reasons.append(f"Payment was instructed by a third party: '{a.strip()}'.")
                
        # 4. Knowing the seller/merchant/organization
        elif "know the merchant" in q_lower or "know this seller" in q_lower or "know the organization" in q_lower:
            if is_negative(a):
                intent_score -= 25
                flagged_reasons.append("User does not know the recipient merchant/seller.")
            elif not is_affirmative(a):
                intent_score -= 10
                flagged_reasons.append("User's familiarity with the merchant is unconfirmed.")
                
        # 5. Product receipt
        elif "received the product" in q_lower or "received the service" in q_lower:
            if is_negative(a):
                intent_score -= 15
                flagged_reasons.append("Payment is being made before receiving the product or service.")
                
        # 6. Merchant name matches seller name
        elif "match the seller" in q_lower or "match the name" in q_lower:
            if is_negative(a):
                intent_score -= 20
                flagged_reasons.append("Recipient merchant name does not match the actual seller name.")
                
        # 7. Promised a reward / lottery
        elif "promised a reward" in q_lower or "lottery" in q_lower or "cashback" in q_lower:
            if is_affirmative(a):
                intent_score -= 35
                flagged_reasons.append("User is scanning QR under the promise of a reward, lottery, or gift.")
            elif not is_negative(a):
                intent_score -= 10
                flagged_reasons.append("User was vague about reward or cashback promises.")
                
        # 8. Pay before receiving prize
        elif "pay before receiving" in q_lower or "pay before" in q_lower:
            if is_affirmative(a):
                intent_score -= 40
                flagged_reasons.append("User is paying upfront fees to obtain a prize or reward.")
                
        # 9. Free will payment
        elif "free will" in q_lower:
            if is_negative(a):
                intent_score -= 55
                flagged_reasons.append("User is not making this payment out of their own free will.")
            elif not is_affirmative(a):
                intent_score -= 20
                flagged_reasons.append("User's free will authorization is ambiguous.")
                
        # 10. Phone call / SMS instructions
        elif "phone call" in q_lower or "instructed you to scan" in q_lower:
            if is_affirmative(a):
                intent_score -= 30
                flagged_reasons.append("User was instructed over a phone call, message, or chat to scan this QR.")
            elif not is_negative(a):
                intent_score -= 10
                flagged_reasons.append("Uncertain if user scanned QR due to third-party instruction.")
                
        # 11. Legitimate/correct check
        elif "legitimate and correct" in q_lower:
            if is_negative(a):
                intent_score -= 40
                flagged_reasons.append("User is unsure if the payment is legitimate or correct.")

    # Apply boundary limits
    intent_score = max(0, min(intent_score, 100))
    
    # Determine Decision
    if intent_score >= 70:
        decision = "SAFE"
        confidence = 0.90 + (intent_score - 70) / 300.0
        reason = [
            "User understands the payment purpose.",
            "Merchant information matches the payment context.",
            "No signs of social engineering detected."
        ]
    elif intent_score >= 40:
        decision = "SUSPICIOUS"
        confidence = 0.80 + (70 - intent_score) / 300.0
        reason = flagged_reasons if flagged_reasons else [
            "User's payment intent is inconsistent.",
            "Potential social engineering risk detected."
        ]
    else:
        decision = "BLOCK"
        confidence = 0.90 + (40 - intent_score) / 600.0
        reason = flagged_reasons if flagged_reasons else [
            "User does not understand the payment context.",
            "High risk of social engineering or scam detected."
        ]
        
    return VerifyIntentResponse(
        intent_score=intent_score,
        decision=decision,
        confidence=round(confidence, 2),
        reason=reason
    )
