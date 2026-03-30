from fastapi import FastAPI
from pydantic import BaseModel
import joblib

app = FastAPI()
model = joblib.load("model.pkl")

class QRRequest(BaseModel):
    qr_data: str

@app.post("/predict")
def predict_qr(req: QRRequest):
    result = predict(req.qr_data)
    return resultpip