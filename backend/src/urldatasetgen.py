import random
import pandas as pd

SAFE = ["google.com", "amazon.in", "flipkart.com"]
SCAM = ["login", "verify", "reward", "claim"]

def safe_url():
    return f"https://{random.choice(SAFE)}/pay/{random.randint(100,999)}"

def scam_url():
    return f"http://192.168.{random.randint(1,255)}.{random.randint(1,255)}/{random.choice(SCAM)}"

data = []

for _ in range(5000):
    data.append((safe_url(), 0))

for _ in range(5000):
    data.append((scam_url(), 1))

df = pd.DataFrame(data, columns=["url", "label"])
df.to_csv("dataset.csv", index=False)