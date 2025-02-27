import requests
import random
import json
import time

# URL of the FastAPI (adjust the URL if it's different)
API_URL = "http://localhost:8000/transactions"

# Channels
channels = ["A", "B", "C", "D"]

# Sample transaction data
def generate_transaction(channel):
    return {
        "channel": channel,
        "transaction_id": f"txn_{random.randint(1000, 9999)}",
        "amount": random.uniform(1.0, 1000.0),
        "timestamp": time.time(),  # UNIX timestamp
    }

# Simulate transactions for each channel
def simulate_transactions():
    while True:
        for channel in channels:
            transaction = generate_transaction(channel)
            response = requests.post(API_URL, json=transaction)
            if response.status_code == 200:
                print(f"Transaction from Channel {channel} sent successfully!")
            else:
                print(f"Error sending transaction from Channel {channel}")
        time.sleep(2)  # Adjust the interval as needed

if __name__ == "__main__":
    simulate_transactions()
