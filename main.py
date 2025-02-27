from fastapi import FastAPI
from kafka import KafkaProducer
import json

app = FastAPI()

producer = KafkaProducer(
    bootstrap_servers="localhost:9092",
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
)

@app.post("/transactions/{channel}")
async def send_transaction(channel: str, transaction: dict):
    """Receives a transaction and sends it to Kafka with its channel."""
    if channel not in ["A", "B", "C", "D"]:
        return {"error": "Invalid channel"}
    
    transaction["channel"] = channel
    producer.send("transactions_topic", transaction)
    return {"message": f"Transaction from {channel} sent to Kafka", "data": transaction}
