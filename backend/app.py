from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import joblib

app = Flask(__name__)
CORS(app)

print("Starting Flask API...")
print("Loading ML model...")

# LOAD MODEL ONCE (NO LAZY LOADING)
model = joblib.load("model.pkl")

print("Model loaded successfully!")

@app.route("/", methods=["GET"])
def home():
    return "Cost-of-Treatment Prediction API is running"

@app.route("/predict", methods=["POST"])
def predict():
    data = request.get_json()

    input_df = pd.DataFrame([{
        "DRG Definition": data["drg_definition"],
        "Provider State": data["provider_state"],
        "Hospital Referral Region Description": data["hospital_region"],
        "Total Discharges": int(data["total_discharges"]),
        "Average Covered Charges": float(data["avg_covered_charges"]),
        "Average Medicare Payments": float(data["avg_medicare_payments"])
    }])

    prediction = model.predict(input_df)[0]

    return jsonify({
        "predicted_cost": round(float(prediction), 2)
    })

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=False, use_reloader=False)
