import os
import re
from typing import Dict, Any, List, Optional
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="SentryPay Chatbot API",
    description="Conversational Cybersecurity and Payment Security Companion 'Sentry'",
    version="1.0"
)

# Enable CORS for Flutter web / emulator access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Optional Gemini API Key
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

SYSTEM_PROMPT = (
    "Identity: You are Sentry, the intelligent security companion inside the SentryPay application. "
    "Your purpose is to educate, guide, and explain. You never approve payments, never override security modules, "
    "and never fabricate information. When available, base your answers on the outputs of the Risk Engine, "
    "Scam Language Detection, Intent Verification AI, and Liveness Authentication. "
    "If context is unavailable, clearly state that you're providing general guidance."
)

# Simple in-memory session store
conversation_history: Dict[str, List[Dict[str, str]]] = {}

class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = "default"
    context: Optional[Dict[str, Any]] = None

class RiskExplainRequest(BaseModel):
    risk_score: int
    risk_level: str
    reasons: Optional[List[str]] = []
    url: Optional[str] = ""

class IntentExplainRequest(BaseModel):
    intent_score: int
    decision: str
    reasons: Optional[List[str]] = []

class ScamExplainRequest(BaseModel):
    status: str
    risk: float
    confidence: float
    reasons: Optional[List[str]] = []

class TipsRequest(BaseModel):
    topic: Optional[str] = None

# ==========================================
# Local Expert Knowledge Base
# ==========================================

KNOWLEDGE_BASE = {
    "qr_intelligence": (
        "SentryPay QR Intelligence is a security system that scans QR code links "
        "and checks for hidden threats. It analyzes the target link (UPI ID or website domain) "
        "for security risks, such as URL shorteners, fake domain extensions, or suspicious "
        "payment note formats before you authorize any transfer."
    ),
    "risk_score": (
        "The SentryPay Risk Score is a combined rating from 0 to 100 calculated "
        "by our Machine Learning and Rule Engines. A higher score means greater risk:\n"
        "- Low Risk (0-40): Payment details look verified and safe.\n"
        "- Moderate Risk (41-75): Some details resemble common scam patterns. The app requires Intent Verification.\n"
        "- High Risk (76-100): High match with known fraud techniques. Liveness checks or warnings will be triggered."
    ),
    "scam_language": (
        "SentryPay Scam Language Detection uses an AI classifier to check the notes, messages, "
        "or descriptions attached to a transaction. Scammers often use pressure tactics (e.g. 'urgent', "
        "'lottery fee', 'verify account now', 'grand prize reward') to trick you. Our model spots "
        "these social engineering keywords to keep you safe."
    ),
    "intent_verification": (
        "SentryPay Intent Verification AI is a cognitive safeguard that asks you multiple-choice questions "
        "if a payment seems suspicious. Its goal is to make sure you are not being manipulated by third parties "
        "(e.g. under the instructions of a fake bank agent, lottery representative, or customer care caller). "
        "It protects you from scanning codes against your own best interests."
    ),
    "liveness_authentication": (
        "Liveness Authentication is a facial verification check that ensures a real, live human is "
        "performing the transaction. It prevents fraud caused by screen sharing, remote desktop utilities "
        "(like AnyDesk or TeamViewer), or photo replay attacks by prompting for live blinks and head movements."
    ),
    "blocked_transactions": (
        "Transactions are blocked or heavily warned when SentryPay detects a high risk score. This happens if "
        "the payment domain is flagged as unsafe, if the Note contains threat-oriented scam language, "
        "or if the Intent Verification AI detects that you are scanning the QR code under high-pressure coercion."
    ),
    "phishing": (
        "Phishing is a cyber attack where scammers create fake websites or links (mimicking banks, Netflix, "
        "Amazon, etc.) to steal your credentials or money. SentryPay automatically blocks these link extensions."
    ),
    "quishing": (
        "Quishing, or QR Phishing, is when a scammer replaces a legitimate QR code with a fraudulent one. "
        "When scanned, it redirects you to a malicious phishing site or prompts a suspicious payment request."
    ),
    "otp_fraud": (
        "OTP Fraud occurs when a scammer calls or messages you pretending to be a bank agent and requests the "
        "One-Time Password sent to your phone. Never share OTPs or PINs. Legitimate institutions will never ask for them."
    ),
}

def generate_local_response(message: str, context: Optional[Dict[str, Any]] = None) -> str:
    msg = message.lower()
    
    # 1. Handle Context-Aware queries first
    if context:
        if "risk" in msg or "safe" in msg or "block" in msg:
            risk_score = context.get("risk_score")
            risk_level = context.get("risk_level")
            reasons = context.get("reasons", [])
            
            if risk_score is not None:
                explanation = f"Based on the active transaction, the merchant risk score is {risk_score} ({risk_level}). "
                if reasons:
                    explanation += f"We flagged this because of: {', '.join(reasons)}. "
                else:
                    explanation += "No suspicious patterns were directly flagged, but we advise verifying the recipient name. "
                
                if risk_level == "HIGH":
                    explanation += "Since this is High Risk, SentryPay recommends cancelling this transaction."
                elif risk_level == "MODERATE":
                    explanation += "We are running additional Intent Verification checks to verify your safety."
                return explanation
                
        if "intent" in msg or "questions" in msg:
            intent_result = context.get("intent_result")
            if intent_result:
                return f"Intent Verification flagged this transaction with a decision of: '{intent_result}'. SentryPay asks these questions to ensure you aren't acting under instructions of a scammer."
                
        if "liveness" in msg or "face" in msg or "camera" in msg:
            liveness_active = context.get("liveness_active", False)
            if liveness_active:
                return "SentryPay has requested Liveness Authentication because the transaction was flagged with a elevated risk level. This ensures you are present and protects against remote screen sharing controls."

    # 2. General Knowledge Matching
    if "hello" in msg or "hi" in msg or "hey" in msg:
        return "Hi, I'm Sentry. How can I help you today?"
        
    if "qr intelligence" in msg or "qr scan" in msg or "quishing" in msg:
        return KNOWLEDGE_BASE["qr_intelligence"]
        
    if "risk score" in msg or "risky" in msg:
        return KNOWLEDGE_BASE["risk_score"]
        
    if "scam language" in msg or "scam words" in msg or "note" in msg:
        return KNOWLEDGE_BASE["scam_language"]
        
    if "intent verification" in msg or "intent ai" in msg or "questions" in msg:
        return KNOWLEDGE_BASE["intent_verification"]
        
    if "liveness" in msg or "face verification" in msg or "facial" in msg:
        return KNOWLEDGE_BASE["liveness_authentication"]
        
    if "block" in msg or "denied" in msg:
        return KNOWLEDGE_BASE["blocked_transactions"]
        
    if "phishing" in msg or "fake site" in msg:
        return KNOWLEDGE_BASE["phishing"]
        
    if "otp" in msg or "pin" in msg:
        return KNOWLEDGE_BASE["otp_fraud"]
        
    if "tips" in msg or "safety" in msg or "safe payment" in msg:
        return (
            "Here are some safe payment tips:\n"
            "1. Double-check payee name before typing your PIN.\n"
            "2. Never make scans under instruction of phone callers claiming you won a lottery or need a refund.\n"
            "3. Be wary of URL shorteners (like bit.ly) or IP addresses in scanned links.\n"
            "4. Secure your device from screen sharing applications while carrying out banking actions."
        )
        
    # 3. Default fallback
    return (
        "I am Sentry, your SentryPay security companion. I can help explain "
        "Risk Scores, Scam Language notes, Intent Verification questions, and "
        "provide general digital payment safety tips. What security aspect can I clarify for you?"
    )

async def call_gemini_api(message: str, history: List[Dict[str, str]], context: Optional[Dict[str, Any]] = None) -> str:
    try:
        contents = []
        for h in history[-6:]:
            role = "user" if h["role"] == "user" else "model"
            contents.append({
                "role": role,
                "parts": [{"text": h["content"]}]
            })
            
        context_str = ""
        if context:
            context_str = f"Current SentryPay System Context: {context}\n"
            
        contents.append({
            "role": "user",
            "parts": [{"text": f"{context_str}User message: {message}"}]
        })
        
        import asyncio
        model = genai.GenerativeModel(
            model_name="gemini-2.0-flash",
            system_instruction=SYSTEM_PROMPT
        )
        
        loop = asyncio.get_event_loop()
        response = await loop.run_in_executor(
            None,
            lambda: model.generate_content(contents)
        )
        
        if response and response.text:
            return response.text
    except Exception as ex:
        print(f"Error calling official Gemini SDK: {ex}")
        
    return generate_local_response(message, context)

# ==========================================
# REST API Endpoints
# ==========================================

@app.get("/")
def root():
    return {
        "status": "running",
        "service": "SentryPay Security Chatbot API",
        "gemini_enabled": GEMINI_API_KEY is not None
    }

@app.post("/chat")
async def chat(request: ChatRequest):
    session_id = request.session_id or "default"
    
    if session_id not in conversation_history:
        conversation_history[session_id] = []
        
    history = conversation_history[session_id]
    
    if GEMINI_API_KEY:
        try:
            bot_response = await call_gemini_api(request.message, history, request.context)
        except Exception:
            bot_response = generate_local_response(request.message, request.context)
    else:
        bot_response = generate_local_response(request.message, request.context)
        
    # Append to memory
    history.append({"role": "user", "content": request.message})
    history.append({"role": "sentry", "content": bot_response})
    
    return {"response": bot_response}

@app.post("/explain-risk")
def explain_risk(request: RiskExplainRequest):
    reasons_str = f" due to: {', '.join(request.reasons)}" if request.reasons else ""
    
    if request.risk_level == "LOW":
        explanation = (
            f"This payment is rated Low Risk ({request.risk_score}/100). The merchant details "
            f"appear legitimate and secure, indicating a standard safe payment context."
        )
    elif request.risk_level == "MODERATE":
        explanation = (
            f"This payment appears Moderately Risky ({request.risk_score}/100){reasons_str}. "
            f"We advise verifying the merchant's identity and checking if you were pressured to scan this."
        )
    else:
        explanation = (
            f"Caution: This payment has a High Risk score of {request.risk_score}/100{reasons_str}. "
            f"This matches known fraudulent patterns or unsafe domains. We strongly recommend cancelling this."
        )
    return {"explanation": explanation}

@app.post("/explain-intent")
def explain_intent(request: IntentExplainRequest):
    reasons_str = f" ({', '.join(request.reasons)})" if request.reasons else ""
    
    if request.decision == "SAFE":
        explanation = (
            f"The Intent AI determined your payment intent is Safe. Your answers show no signs of "
            f"external manipulation or coercion."
        )
    elif request.decision == "SUSPICIOUS":
        explanation = (
            f"The Intent AI flagged this transaction as Suspicious{reasons_str}. Your responses suggest "
            f"that you might be acting under instructions or pressure from an unauthorized third party."
        )
    else:
        explanation = (
            f"Payment Blocked: The Intent AI has high confidence that this transaction is part of a scam{reasons_str}. "
            f"Please cancel the transaction immediately and verify the caller."
        )
    return {"explanation": explanation}

@app.post("/explain-scam")
def explain_scam(request: ScamExplainRequest):
    reasons_str = f" containing flagged keywords: {', '.join(request.reasons)}" if request.reasons else ""
    
    if request.risk <= 0.4:
        explanation = (
            f"The transaction note appears safe ({int(request.confidence)}% confidence). No scam language "
            f"tactics were detected."
        )
    else:
        explanation = (
            f"Warning: Scam Language detected in note{reasons_str} with {int(request.confidence)}% confidence. "
            f"Scammers commonly use note descriptions to bypass banking checks or validate false promises."
        )
    return {"explanation": explanation}

@app.post("/security-tips")
def security_tips(request: TipsRequest):
    topic = (request.topic or "general").lower()
    
    if "qr" in topic or "quishing" in topic:
        tips = (
            "QR Security Tips:\n"
            "- Always verify the recipient name displayed on your screen before typing your PIN.\n"
            "- Beware of QR codes pasted on top of other codes in public places.\n"
            "- SentryPay will automatically scan scanned links for redirect parameters or shorteners."
        )
    elif "phishing" in topic:
        tips = (
            "Phishing Security Tips:\n"
            "- Check the domain extension closely (e.g. '.xyz', '.cc' are often used by scammers).\n"
            "- Banks will never send you links asking to verify credentials or claim immediate rewards.\n"
            "- Avoid entering bank account details on untrusted sites."
        )
    else:
        tips = (
            "General Cyber Hygiene:\n"
            "- Never share OTPs, passwords, or transaction PINs with anyone.\n"
            "- Avoid scanning QR codes sent via WhatsApp to receive prizes or refunds.\n"
            "- Enable SentryPay's Intent Verification for all third-party transaction contexts."
        )
    return {"tips": tips}

@app.post("/clear")
def clear_chat(session_id: Optional[str] = "default"):
    session = session_id or "default"
    if session in conversation_history:
        conversation_history[session] = []
    return {"status": "cleared"}
