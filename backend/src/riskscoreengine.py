import joblib

model = joblib.load("model.pkl")

def predict(url):
    features = [extract(url)]
    
    prob = model.predict_proba(features)[0][1]
    score = int(prob * 100)

    if score > 75:
        level = "HIGH RISK"
    elif score > 40:
        level = "MEDIUM RISK"
    else:
        level = "LOW RISK"

    return {
        "risk_score": score,
        "risk_level": level
    }