import unittest
from fastapi.testclient import TestClient
import sys
import os

# Add src to python path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from src.app import app

class TestIntentAI(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)

    def test_root(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["service"], "SentryPay Intent Verification AI Engine")

    def test_generate_questions_banking(self):
        payload = {
            "url": "https://sbi-secure-login.verify-login.info/verify",
            "ml_score": 60,
            "rule_score": 15,
            "risk_score": 75,
            "risk_level": "MODERATE",
            "reasons": ["Verification keyword detected", "Suspicious URL pattern detected"]
        }
        response = self.client.post("/generate-intent-questions", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("questions", data)
        self.assertEqual(len(data["questions"]), 3)
        self.assertTrue(any("bank" in q.lower() or "sbi" in q.lower() for q in data["questions"]))

    def test_generate_questions_marketplace(self):
        payload = {
            "url": "upi://pay?pa=seller@paytm&pn=Amazon%20Seller&mc=5411&tn=Purchase%20Order%20123",
            "ml_score": 10,
            "rule_score": 35,
            "risk_score": 45,
            "risk_level": "MODERATE",
            "reasons": ["Non-HTTPS insecure URL detected"]
        }
        response = self.client.post("/generate-intent-questions", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(len(data["questions"]), 3)
        self.assertTrue(any("seller" in q.lower() or "amazon" in q.lower() for q in data["questions"]))

    def test_verify_intent_safe(self):
        payload = {
            "risk_result": {
                "url": "upi://pay?pa=merchant@upi&pn=Grocery%20Store&mc=5411&tn=Vegetables",
                "ml_score": 5,
                "rule_score": 40,
                "risk_score": 45,
                "risk_level": "MODERATE",
                "reasons": ["URL shortener detected"]
            },
            "questions": [
                "Do you personally know the merchant 'Grocery Store' or have you bought from them before?",
                "Have you already received the product or service related to 'Vegetables'?",
                "Does the recipient merchant name 'Grocery Store' exactly match the seller you are dealing with?"
            ],
            "answers": [
                "Yes, I know this store and shop there daily.",
                "Yes, I have already received the vegetables.",
                "Yes, it matches perfectly."
            ]
        }
        response = self.client.post("/verify-intent", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["decision"], "SAFE")
        self.assertGreaterEqual(data["intent_score"], 70)

    def test_verify_intent_block(self):
        payload = {
            "risk_result": {
                "url": "https://sbi-secure-login.verify-login.info/verify",
                "ml_score": 60,
                "rule_score": 15,
                "risk_score": 75,
                "risk_level": "MODERATE",
                "reasons": ["Verification keyword detected"]
            },
            "questions": [
                "Who asked you to make this payment to 'Sbi-Secure-Login'?",
                "Did someone claim to be a representative of SBI or ask you to verify your account?",
                "Are you paying to verify your account or prevent it from being suspended?"
            ],
            "answers": [
                "A support agent named John called me.",
                "Yes, they said they are from SBI support.",
                "Yes, they said my account will be suspended if I don't pay."
            ]
        }
        response = self.client.post("/verify-intent", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["decision"], "BLOCK")
        self.assertLess(data["intent_score"], 40)
        self.assertTrue(any("bank representative" in r for r in data["reason"]))

if __name__ == "__main__":
    unittest.main()
