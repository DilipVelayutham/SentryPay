import pandas as pd
import torch
import numpy as np

from transformers import (
    DistilBertTokenizerFast,
    DistilBertForSequenceClassification,
    Trainer,
    TrainingArguments,
    EarlyStoppingCallback
)

from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score,
    precision_recall_fscore_support
)

# =========================
# DEVICE
# =========================

device = torch.device(
    "cuda" if torch.cuda.is_available() else "cpu"
)

print(f"\nUSING DEVICE: {device}")

# =========================
# LOAD DATASET
# =========================

df = pd.read_csv(
    "datasets/final_dataset.csv"
)

# REMOVE EMPTY VALUES
df.dropna(inplace=True)

# CONVERT TO STRING
df["text"] = df["text"].astype(str)

print("\nDATASET LOADED")
print(df.head())

print("\nLABEL COUNTS:")
print(df["label"].value_counts())

# =========================
# SPLIT DATA
# =========================

train_texts, val_texts, train_labels, val_labels = train_test_split(

    df["text"].tolist(),

    df["label"].tolist(),

    test_size=0.2,

    random_state=42,

    stratify=df["label"]
)

print(f"\nTRAIN SIZE: {len(train_texts)}")
print(f"VALIDATION SIZE: {len(val_texts)}")

# =========================
# TOKENIZER
# =========================

tokenizer = DistilBertTokenizerFast.from_pretrained(
    "distilbert-base-uncased"
)

# =========================
# TOKENIZATION
# =========================

train_encodings = tokenizer(

    train_texts,

    truncation=True,

    padding="max_length",

    max_length=64
)

val_encodings = tokenizer(

    val_texts,

    truncation=True,

    padding="max_length",

    max_length=64
)

# =========================
# DATASET CLASS
# =========================

class ScamDataset(torch.utils.data.Dataset):

    def __init__(self, encodings, labels):

        self.encodings = encodings
        self.labels = labels

    def __getitem__(self, idx):

        item = {

            key: torch.tensor(val[idx])

            for key, val in self.encodings.items()
        }

        item["labels"] = torch.tensor(
            self.labels[idx],
            dtype=torch.long
        )

        return item

    def __len__(self):

        return len(self.labels)

# =========================
# CREATE DATASETS
# =========================

train_dataset = ScamDataset(
    train_encodings,
    train_labels
)

val_dataset = ScamDataset(
    val_encodings,
    val_labels
)

# =========================
# LOAD MODEL
# =========================

model = DistilBertForSequenceClassification.from_pretrained(

    "distilbert-base-uncased",

    num_labels=2
)

model.to(device)

# =========================
# METRICS
# =========================

def compute_metrics(pred):

    labels = pred.label_ids

    preds = np.argmax(
        pred.predictions,
        axis=1
    )

    precision, recall, f1, _ = precision_recall_fscore_support(

        labels,

        preds,

        average="weighted"
    )

    acc = accuracy_score(
        labels,
        preds
    )

    return {

        "accuracy": acc,

        "f1": f1,

        "precision": precision,

        "recall": recall
    }

# =========================
# TRAINING SETTINGS
# =========================

training_args = TrainingArguments(

    output_dir="./results",

    eval_strategy="epoch",

    save_strategy="epoch",

    learning_rate=2e-5,

    per_device_train_batch_size=16,

    per_device_eval_batch_size=16,

    num_train_epochs=3,

    weight_decay=0.01,

    warmup_ratio=0.1,

    logging_dir="./logs",

    logging_steps=25,

    load_best_model_at_end=True,

    metric_for_best_model="f1",

    greater_is_better=True,

    report_to="none",

    fp16=torch.cuda.is_available(),

    save_total_limit=1
)

# =========================
# TRAINER
# =========================

trainer = Trainer(

    model=model,

    args=training_args,

    train_dataset=train_dataset,

    eval_dataset=val_dataset,

    compute_metrics=compute_metrics,

    callbacks=[
        EarlyStoppingCallback(
            early_stopping_patience=1
        )
    ]
)

# =========================
# TRAIN MODEL
# =========================

print("\nSTARTING TRAINING...\n")

trainer.train()

# =========================
# FINAL EVALUATION
# =========================

print("\nEVALUATING MODEL...\n")

results = trainer.evaluate()

print("\nFINAL RESULTS:")
print(results)

# =========================
# SAVE MODEL
# =========================

model.save_pretrained("./model")

tokenizer.save_pretrained("./model")

print("\nMODEL SAVED SUCCESSFULLY")
print("\nPATH: ./model")