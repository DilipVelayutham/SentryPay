import pandas as pd
import random

# =========================
# LOAD PHISHING EMAIL DATASET
# =========================

phishing_df = pd.read_csv(
    "datasets/phishing_email.csv"
)

print("PHISHING DATASET COLUMNS:")
print(phishing_df.columns)

# CHANGE THIS COLUMN NAME IF NEEDED
TEXT_COLUMN = phishing_df.columns[0]

phishing_df = phishing_df[[TEXT_COLUMN]]

phishing_df.columns = ["text"]

# LABEL AS SCAM
phishing_df["label"] = 1

# =========================
# LOAD SOCIAL ENGINEERING DATASET
# =========================

social_df = pd.read_csv(
    "datasets/social_engineering.csv"
)

# =========================
# LOAD PHISHING URL DATASET
# =========================

url_df = pd.read_csv(
    "datasets/phishing_urls.csv"
)

# KEEP ONLY PHISHING URLS
if "type" in url_df.columns:

    url_df = url_df[
        url_df["type"].str.lower() == "phishing"
    ]

print("URL DATASET COLUMNS:")
print(url_df.columns)

# TAKE FIRST COLUMN AS URL
URL_COLUMN = url_df.columns[0]

url_df = url_df[[URL_COLUMN]]

url_df.columns = ["url"]

# =========================
# CREATE URL TRAINING TEXTS
# =========================

templates = [

    "Verify your bank account immediately: {}",

    "Security alert! Login here now: {}",

    "Your account is blocked. Verify here: {}",

    "Urgent banking verification required: {}",

    "Click here to secure your account: {}",

    "Suspicious login detected. Verify now: {}",

    "Your payment account needs confirmation: {}",

    "Immediate action required visit: {}",

    "Confirm your banking identity here: {}",

    "Your account access is temporarily disabled: {}"
]

# LIMIT URL SAMPLES
sampled_urls = url_df["url"].sample(
    n=min(5000, len(url_df)),
    random_state=42
)

url_training_texts = []

for url in sampled_urls:

    template = random.choice(templates)

    text = template.format(url)

    url_training_texts.append(text)

url_training_df = pd.DataFrame({

    "text": url_training_texts,

    "label": 1
})

# =========================
# SAFE NORMAL CHAT SAMPLES
# =========================

safe_samples = [

    # =========================
    # CASUAL CHATS
    # =========================

    "hello how are you",
    "lets meet tomorrow",
    "good morning",
    "happy birthday bro",
    "did you eat food",
    "lets go for lunch",
    "call me when free",
    "can you send notes",
    "i reached college",
    "good night take care",
    "where are you now",
    "lets play cricket",
    "see you soon",
    "thank you so much",
    "how was your day",
    "what are you doing",
    "lets watch movie tonight",
    "come to class tomorrow",
    "i will text later",
    "can you help me",

    # =========================
    # BANKING NORMAL
    # =========================

    "your account balance is updated",
    "transaction completed successfully",
    "your payment was successful",
    "monthly statement generated",
    "salary credited successfully",
    "your bank account was credited",
    "debit card payment successful",
    "upi transaction completed",
    "bank transfer successful",
    "payment received successfully",
    "your recharge is successful",
    "electricity bill paid successfully",
    "water bill payment successful",
    "account summary available",
    "emi payment completed",
    "cashback credited to your account",
    "refund processed successfully",
    "bank service request completed",
    "net banking activated successfully",
    "account details updated successfully",

    # =========================
    # ORDER / SHOPPING
    # =========================

    "give me your order number",
    "please share order id",
    "your order has been shipped",
    "track your package here",
    "delivery arriving today",
    "your package is out for delivery",
    "amazon order confirmed",
    "flipkart order dispatched",
    "myntra order delivered",
    "refund initiated successfully",
    "invoice attached below",
    "delivery partner will contact you",
    "product exchange request accepted",
    "shopping cart updated",
    "payment confirmation received",
    "your booking is confirmed",
    "food order delivered",
    "order cancellation successful",
    "ticket booking confirmed",
    "parcel delivered successfully",

    # =========================
    # CUSTOMER SUPPORT
    # =========================

    "customer support will contact you",
    "support ticket updated",
    "your complaint has been registered",
    "service request completed",
    "technical support assigned",
    "appointment confirmed successfully",
    "helpdesk ticket resolved",
    "customer care executive will call you",
    "support request accepted",
    "maintenance request completed",
    "service engineer assigned",
    "your query has been answered",
    "thank you for contacting support",
    "your issue is being reviewed",
    "booking support confirmed",

    # =========================
    # WORK / OFFICE
    # =========================

    "meeting starts at 10am",
    "project discussion tomorrow",
    "submit assignment today",
    "class has been cancelled",
    "exam timetable released",
    "team meeting postponed",
    "office will remain closed tomorrow",
    "presentation scheduled for monday",
    "client meeting confirmed",
    "work report submitted",
    "salary slip uploaded",
    "training session tomorrow",
    "zoom meeting link shared",
    "attendance updated successfully",
    "deadline extended till friday",

    # =========================
    # SAFE URL SHARING
    # =========================

    "visit https://google.com",
    "check this video https://youtube.com",
    "github repo https://github.com",
    "college website https://rmkec.ac.in",
    "firebase docs https://firebase.google.com",
    "flutter documentation https://flutter.dev",
    "microsoft official site https://microsoft.com",
    "amazon homepage https://amazon.com",
    "openai website https://openai.com",
    "stackoverflow solutions https://stackoverflow.com",

    # =========================
    # NORMAL SECURITY CONTEXT
    # =========================

    "your password was updated successfully",
    "two factor authentication enabled",
    "security settings updated",
    "login successful from chrome browser",
    "new device login detected",
    "verification completed successfully",
    "identity confirmed successfully",
    "authentication successful",
    "security notification received",
    "login activity updated",

    # =========================
    # GENERIC SAFE
    # =========================

    "see you tomorrow",
    "message me later",
    "how is your family",
    "did you complete homework",
    "lets study together",
    "movie starts at 7pm",
    "train arriving at platform 2",
    "bus reached station",
    "weather is good today",
    "have a safe journey"
]
safe_df = pd.DataFrame({

    "text": safe_samples,

    "label": 0
})

# =========================
# MERGE ALL DATASETS
# =========================

final_df = pd.concat([

    phishing_df,

    social_df,

    url_training_df,

    safe_df
])

# =========================
# CLEAN DATA
# =========================

final_df.dropna(inplace=True)

final_df.drop_duplicates(inplace=True)

final_df["text"] = final_df["text"].astype(str)

final_df = final_df[
    final_df["text"].str.len() > 5
]

# =========================
# BALANCE DATASET
# =========================

scam_df = final_df[
    final_df["label"] == 1
]

safe_df = final_df[
    final_df["label"] == 0
]

# LIMIT SCAM SAMPLES
scam_df = scam_df.sample(
    n=min(10000, len(scam_df)),
    random_state=42
)

# UPSAMPLE SAFE SAMPLES
safe_df = safe_df.sample(
    n=min(len(scam_df), 5000),
    replace=True,
    random_state=42
)

# FINAL BALANCED DATASET
final_df = pd.concat([

    scam_df,

    safe_df
])

# =========================
# SHUFFLE
# =========================

final_df = final_df.sample(
    frac=1,
    random_state=42
)

# =========================
# SAVE DATASET
# =========================

final_df.to_csv(
    "datasets/final_dataset.csv",
    index=False
)

# =========================
# OUTPUT
# =========================

print("\nFINAL DATASET CREATED SUCCESSFULLY")

print("\nDATASET SIZE:")
print(final_df.shape)

print("\nLABEL COUNTS:")
print(final_df["label"].value_counts())

print("\nSAMPLE DATA:")
print(final_df.head(10))