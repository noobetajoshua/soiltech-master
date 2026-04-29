from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
from PIL import Image
import cv2
import io
import json
import os
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras import layers, models
from groq import Groq
import tensorflow as tf
from dotenv import load_dotenv
load_dotenv()

app = Flask(__name__)
CORS(app)

CLASS_NAMES = ['clay', 'loamy', 'peat', 'sandy', 'silt']

BASE = os.path.dirname(__file__)

# Load model
base_model = MobileNetV2(input_shape=(224, 224, 3), include_top=False, weights='imagenet')
base_model.trainable = False
x = base_model.output
x = layers.GlobalAveragePooling2D()(x)
x = layers.Dense(128, activation='relu')(x)
output = layers.Dense(5, activation='softmax')(x)
model = models.Model(inputs=base_model.input, outputs=output)
model.load_weights(os.path.join(BASE, 'soil_model_v2.weights.h5'))

# Load JSON files
with open(os.path.join(BASE, 'soil_profile.json')) as f:
    soil_profile = json.load(f)
with open(os.path.join(BASE, 'crop_requirements.json')) as f:
    crop_requirements = json.load(f)
with open(os.path.join(BASE, 'amendments.json')) as f:
    amendments = json.load(f)

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
groq_client = Groq(api_key=GROQ_API_KEY)

def normalize_crop_name(raw_name):
    raw_name = raw_name.strip()
    crop_list = list(crop_requirements.keys())
    crop_list_str = ', '.join(crop_list)

    try:
        response = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{
                "role": "user",
                "content": (
                    f"The farmer typed this crop name: '{raw_name}'.\n"
                    f"Match it to exactly one crop from this list: {crop_list_str}.\n"
                    f"Return only the single matching crop name from the list, nothing else. "
                    f"No explanation, no punctuation, just the word."
                )
            }]
        )
        normalized = response.choices[0].message.content.strip().lower()
        if normalized in crop_requirements:
            return normalized
        else:
            return raw_name.lower()
    except Exception:
        return raw_name.lower()

def estimate_om(image_bytes, wet_dry_score):
    np_arr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    h, w, _ = img.shape
    cx, cy = w // 2, h // 2
    size = min(h, w) // 4
    crop = img[cy-size:cy+size, cx-size:cx+size]
    hsv = cv2.cvtColor(crop, cv2.COLOR_BGR2HSV)
    v_mean = np.mean(hsv[:, :, 2])

    corrected_v = v_mean + (wet_dry_score * 15)

    if corrected_v < 76:
        om_level = 'high'
    elif corrected_v <= 127:
        om_level = 'moderate'
    else:
        om_level = 'low'

    return om_level, round(float(corrected_v), 2)

@app.route('/')
def index():
    return jsonify({"message": "Soiltech API is running"})

@app.route('/predict', methods=['POST'])
def predict():
    if 'image' not in request.files:
        return jsonify({"error": "No image provided"}), 400

    wet_dry_score = int(request.form.get('wet_dry_score', 0))

    file = request.files['image']
    image_bytes = file.read()

    img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    img = img.resize((224, 224))
    img_array = np.array(img) / 255.0
    img_array = np.expand_dims(img_array, axis=0)

    predictions = model.predict(img_array)
    class_index = np.argmax(predictions[0])
    confidence = float(np.max(predictions[0])) * 100
    soil_type = CLASS_NAMES[class_index]

    om_level, brightness_value = estimate_om(image_bytes, wet_dry_score)

    return jsonify({
        "soil_type": soil_type,
        "confidence": f"{confidence:.2f}%",
        "om_level": om_level,
        "om_brightness_value": brightness_value
    })

@app.route('/recommend', methods=['POST'])
def recommend():
    data = request.get_json()
    soil_type = data.get('soil_type', '').lower()
    om_level = data.get('om_level', '').lower()
    drainage_score = data.get('drainage_score', 0)
    crop_name = normalize_crop_name(data.get('crop_name', ''))

    if crop_name not in crop_requirements:
        return jsonify({'error': f'Crop "{crop_name}" not found'}), 400

    crop = crop_requirements[crop_name]
    issues = []
    amendment_list = []

    if soil_type in crop['unsuitable_soil_types']:
        compatibility = 'not_suitable'
        issues.append(f'{soil_type} soil is not suitable for {crop_name}')
        amendment_list += amendments['unsuitable_soil_type']['amendments']
    else:
        compatibility = 'suitable'

    if om_level not in crop['required_om']:
        issues.append(f'Organic matter is {om_level} — {crop_name} needs {" or ".join(crop["required_om"])}')
        amendment_list += amendments['low_om']['amendments']
        if compatibility == 'suitable':
            compatibility = 'fair'

    soil_drainage = soil_profile[soil_type]['drainage_default']
    if drainage_score == -1:
        actual_drainage = 'poor'
    elif drainage_score == 1:
        actual_drainage = 'excessive'
    else:
        actual_drainage = soil_drainage

    if actual_drainage not in crop['required_drainage']:
        issues.append(f'Drainage is {actual_drainage} — {crop_name} needs {" or ".join(crop["required_drainage"])}')
        if actual_drainage == 'poor':
            amendment_list += amendments['poor_drainage']['amendments']
        elif actual_drainage == 'excessive':
            amendment_list += amendments['excessive_drainage']['amendments']
        if compatibility == 'suitable':
            compatibility = 'fair'

    amendment_list = list(dict.fromkeys(amendment_list))

    return jsonify({
        'soil_type': soil_type,
        'crop': crop_name,
        'compatibility': compatibility,
        'issues': issues,
        'amendments': amendment_list
    })

@app.route('/explain', methods=['POST'])
def explain():
    data = request.get_json()
    soil_type = data.get('soil_type', '')
    om_level = data.get('om_level', '')
    crop_name = data.get('crop_name', '')
    issues = data.get('issues', [])

    if not soil_type or not crop_name:
        return jsonify({'error': 'Missing soil_type or crop_name'}), 400

    issues_text = ', '.join(issues) if issues else 'none identified'

    prompt = f"""You are an agricultural advisor speaking to a Filipino farmer.
Soil type: {soil_type}
Organic matter level: {om_level}
Crop chosen: {crop_name}
Issues identified: {issues_text}

In 3 to 4 plain sentences, explain what will likely happen if the farmer 
plants {crop_name} in this soil without fixing the issues. 
Be specific, practical, and avoid technical jargon. 
Speak directly to the farmer."""

    try:
        response = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "user", "content": prompt}]
        )
        explanation = response.choices[0].message.content
        return jsonify({'explanation': explanation})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)