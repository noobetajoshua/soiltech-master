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

# ── Load model ─────────────────────────────────────────────────
base_model = MobileNetV2(input_shape=(224, 224, 3), include_top=False, weights='imagenet')
base_model.trainable = False
x = base_model.output
x = layers.GlobalAveragePooling2D()(x)
x = layers.Dense(128, activation='relu')(x)
output = layers.Dense(5, activation='softmax')(x)
model = models.Model(inputs=base_model.input, outputs=output)
model.load_weights(os.path.join(BASE, 'soil_model_v2.weights.h5'))

# ── Load JSON files ────────────────────────────────────────────
with open(os.path.join(BASE, 'soil_profile.json')) as f:
    soil_profile = json.load(f)
with open(os.path.join(BASE, 'crop_requirements.json')) as f:
    crop_requirements = json.load(f)
with open(os.path.join(BASE, 'amendments.json')) as f:
    amendments = json.load(f)

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
groq_client = Groq(api_key=GROQ_API_KEY)

# ══════════════════════════════════════════════════════════════
# CROP ALIASES
# Covers: Tagalog, Bisaya/Cebuano, Ilocano, English variants,
# and common misspellings the AI consistently gets wrong.
# Rule: if a word fails the AI twice, add it here.
# ══════════════════════════════════════════════════════════════

CROP_ALIASES = {
    # ── Rice ──────────────────────────────────────────────────
    "humay":           "rice",   # Bisaya
    "palay":           "rice",   # Tagalog
    "bigas":           "rice",   # Tagalog (cooked)
    "kanin":           "rice",   # cooked rice, still maps
    "bugas":           "rice",   # Bisaya variant

    # ── Corn ──────────────────────────────────────────────────
    "mais":            "corn",   # Filipino universal
    "maize":           "corn",
    "corn":            "corn",

    # ── Tomato ────────────────────────────────────────────────
    "kamatis":         "tomato", # Tagalog/Bisaya
    "kamatis2":        "tomato",
    "tomatis":         "tomato", # common misspelling
    "kamates":         "tomato", # common misspelling

    # ── Eggplant ──────────────────────────────────────────────
    "talong":          "eggplant", # Tagalog
    "talong-talong":   "eggplant",
    "tarong":          "eggplant", # Bisaya
    "talond":          "eggplant", # misspelling

    # ── Kangkong ──────────────────────────────────────────────
    "water spinach":   "kangkong",
    "river spinach":   "kangkong",
    "tangkong":        "kangkong", # Bisaya
    "tinangkong":      "kangkong", # Bisaya variant
    "kangkon":         "kangkong", # misspelling
    "kangkung":        "kangkong", # Indonesian/Malay variant
    "kang kong":       "kangkong",

    # ── Camote ────────────────────────────────────────────────
    "sweet potato":    "camote",
    "kamote":          "camote",  # Tagalog
    "camoting kahoy":  "camote",
    "tamus":           "camote",  # Bisaya
    "kamoti":          "camote",  # Bisaya misspelling

    # ── Cassava ───────────────────────────────────────────────
    "balinghoy":       "cassava", # Bisaya
    "kamoteng kahoy":  "cassava", # Tagalog
    "manioc":          "cassava",
    "yuca":            "cassava",
    "kasaba":          "cassava", # Bisaya variant
    "cassaba":         "cassava", # misspelling

    # ── Onion ─────────────────────────────────────────────────
    "sibuyas":         "onion",   # Tagalog
    "bumbay":          "onion",   # Bisaya
    "bombay":          "onion",   # Bisaya variant
    "lasona":          "onion",   # Ilocano
    "sibyas":          "onion",   # misspelling
    "sibuas":          "onion",   # misspelling

    # ── Garlic ────────────────────────────────────────────────
    "bawang":          "garlic",  # Tagalog
    "ahos":            "garlic",  # Bisaya/Cebuano
    "ajos":            "garlic",  # Bisaya variant / Spanish
    "aho":             "garlic",  # short Bisaya
    "bawang putih":    "garlic",
    "dawang":          "garlic",  # misspelling

    # ── Mustasa ───────────────────────────────────────────────
    "mustard":         "mustasa",
    "mustard greens":  "mustasa",
    "mustasa":         "mustasa",
    "mustasa greens":  "mustasa",

    # ── Ampalaya ──────────────────────────────────────────────
    "bitter gourd":    "ampalaya",
    "bitter melon":    "ampalaya",
    "parya":           "ampalaya", # Bisaya
    "paria":           "ampalaya", # Bisaya variant
    "amplaya":         "ampalaya", # misspelling
    "ampalaia":        "ampalaya", # misspelling

    # ── Alugbati ──────────────────────────────────────────────
    "malabar spinach": "alugbati",
    "libato":          "alugbati", # Bisaya
    "dundula":         "alugbati", # Bisaya variant
    "alugbate":        "alugbati", # misspelling

    # ── Sitaw ─────────────────────────────────────────────────
    "batong":          "sitaw",   # Bisaya
    "batongan":        "sitaw",   # Bisaya variant
    "string beans":    "sitaw",
    "string bean":     "sitaw",
    "yardlong beans":  "sitaw",
    "yard long beans": "sitaw",
    "long beans":      "sitaw",
    "sitao":           "sitaw",   # variant spelling
    "hantak":          "sitaw",   # Bisaya

    # ── Sili ──────────────────────────────────────────────────
    "chili":           "sili",
    "chilli":          "sili",
    "pepper":          "sili",
    "hot pepper":      "sili",
    "lada":            "sili",    # Bisaya
    "siling labuyo":   "sili",
    "siling haba":     "sili",

    # ── Kalamansi ─────────────────────────────────────────────
    "calamansi":       "kalamansi",
    "calamondin":      "kalamansi",
    "kalamunding":     "kalamansi",
    "kalamansi lime":  "kalamansi",
    "lemonsito":       "kalamansi", # Bisaya/common
    "limon":           "kalamansi", # Bisaya

    # ── Malunggay ─────────────────────────────────────────────
    "moringa":         "malunggay",
    "drumstick tree":  "malunggay",
    "kamunggay":       "malunggay", # Bisaya
    "malungay":        "malunggay", # misspelling
    "malungai":        "malunggay", # misspelling

    # ── Tanglad ───────────────────────────────────────────────
    "lemongrass":      "tanglad",
    "salai":           "tanglad",  # Bisaya
    "saly":            "tanglad",  # Bisaya variant
    "tanglad":         "tanglad",

    # ── Sayote ────────────────────────────────────────────────
    "chayote":         "sayote",
    "choko":           "sayote",
    "pepino de agua":  "sayote",
    "sayote":          "sayote",
    "sayor":           "sayote",   # misspelling

    # ── Singkamas ─────────────────────────────────────────────
    "jicama":          "singkamas",
    "turnip":          "singkamas",
    "singkamas":       "singkamas",
    "singkamas tuber": "singkamas",

    # ── Sigarilyas ────────────────────────────────────────────
    "winged beans":    "sigarilyas",
    "winged bean":     "sigarilyas",
    "four angled bean":"sigarilyas",
    "sigarillas":      "sigarilyas", # misspelling
    "sigarilya":       "sigarilyas", # misspelling

    # ── Mani ──────────────────────────────────────────────────
    "peanut":          "mani",
    "peanuts":         "mani",
    "groundnut":       "mani",
    "mani":            "mani",
    "manies":          "mani",     # misspelling

    # ── Kundol ────────────────────────────────────────────────
    "wax gourd":       "kundol",
    "winter melon":    "kundol",
    "white gourd":     "kundol",
    "kundol":          "kundol",
    "kondol":          "kundol",   # misspelling

    # ── Patola ────────────────────────────────────────────────
    "sponge gourd":    "patola",
    "luffa":           "patola",
    "loofah":          "patola",
    "patola":          "patola",
    "patula":          "patola",   # misspelling

    # ── Upo ───────────────────────────────────────────────────
    "bottle gourd":    "upo",
    "calabash":        "upo",
    "upo":             "upo",
    "upo squash":      "upo",

    # ── Pipino ────────────────────────────────────────────────
    "cucumber":        "pipino",
    "pepino":          "pipino",   # Spanish/Bisaya variant
    "pepeno":          "pipino",   # misspelling
    "pipino":          "pipino",
    "pipinu":          "pipino",   # misspelling

    # ── Luya ──────────────────────────────────────────────────
    "ginger":          "luya",
    "luya":            "luya",
    "loya":            "luya",     # misspelling
    "luia":            "luya",     # misspelling

    # ── Pako ──────────────────────────────────────────────────
    "fern":            "pako",
    "vegetable fern":  "pako",
    "pakis":           "pako",     # Tagalog
    "pako":            "pako",

    # ── Carrots ───────────────────────────────────────────────
    "carrot":          "carrots",
    "karot":           "carrots",  # Filipino
    "karots":          "carrots",  # misspelling
    "carots":          "carrots",  # misspelling

    # ── Potato ────────────────────────────────────────────────
    "patatas":         "potato",   # Filipino
    "potato":          "potato",
    "patata":          "potato",   # singular
    "potatoes":        "potato",

    # ── Chinese Petchay ───────────────────────────────────────
    "chinese cabbage": "chinese_petchay",
    "petsay":          "chinese_petchay", # Filipino
    "chinese pechay":  "chinese_petchay",
    "pechay baguio":   "chinese_petchay",
    "napa cabbage":    "chinese_petchay",

    # ── Green Onions ──────────────────────────────────────────
    "green onion":     "green_onions",
    "green onions":    "green_onions",
    "scallion":        "green_onions",
    "scallions":       "green_onions",
    "spring onion":    "green_onions",
    "spring onions":   "green_onions",
    "sibuyas dahon":   "green_onions", # Tagalog
    "sibuyas na dahon":"green_onions",
    "dahon ng sibuyas":"green_onions",
    "kutchay":         "green_onions", # Bisaya/common term

    # ── Repolyo ───────────────────────────────────────────────
    "cabbage":         "repolyo",
    "repolyo":         "repolyo",
    "repollo":         "repolyo",  # Spanish origin
    "repullo":         "repolyo",  # misspelling

    # ── Bokchoy ───────────────────────────────────────────────
    "bok choy":        "bokchoy",
    "pak choi":        "bokchoy",
    "pok choy":        "bokchoy",  # misspelling
    "bokchoi":         "bokchoy",  # misspelling

    # ── Baguio Beans ──────────────────────────────────────────
    "baguio beans":    "baguio_beans",
    "green beans":     "baguio_beans",
    "french beans":    "baguio_beans",
    "snap beans":      "baguio_beans",
    "habitchuelas":    "baguio_beans", # Bisaya
    "habichuelas":     "baguio_beans", # Bisaya variant

    # ── Monggo ────────────────────────────────────────────────
    "mung bean":       "monggo",
    "mung beans":      "monggo",
    "munggo":          "monggo",   # Tagalog variant
    "green gram":      "monggo",
    "mongo":           "monggo",   # common misspelling
    "mungo":           "monggo",   # misspelling

    # ── Turmeric ──────────────────────────────────────────────
    "luyang dilaw":    "turmeric", # Tagalog
    "dilaw":           "turmeric", # Tagalog (yellow)
    "kalawag":         "turmeric", # Bisaya
    "kunig":           "turmeric", # Bisaya variant

    # ── Asthma Plant ──────────────────────────────────────────
    "tawa tawa":       "asthma_plant",
    "tawa-tawa":       "asthma_plant",
    "gatas gatas":     "asthma_plant", # Bisaya
    "tawatawa":        "asthma_plant",

    # ── Lagundi ───────────────────────────────────────────────
    "five leaved chaste tree": "lagundi",
    "lagundi":         "lagundi",
    "dangla":          "lagundi",  # Bisaya
    "lagunde":         "lagundi",  # misspelling

    # ── Basil ─────────────────────────────────────────────────
    "basil":           "basil",
    "sweet basil":     "basil",
    "balanoy":         "basil",    # Filipino
    "solasi":          "basil",    # Bisaya

    # ── Pandan ────────────────────────────────────────────────
    "pandan leaf":     "pandan",
    "screwpine":       "pandan",
    "pandan":          "pandan",
    "pandan leaves":   "pandan",
    "pandan plant":    "pandan",
    "pangdan":         "pandan",   # Bisaya

    # ── Mint ──────────────────────────────────────────────────
    "mint":            "mint",
    "hierba buena":    "mint",     # Filipino/Spanish
    "yerba buena":     "mint",     # Filipino
    "herba buena":     "mint",     # misspelling

    # ── Ube ───────────────────────────────────────────────────
    "purple yam":      "ube",
    "yam":             "ube",
    "ube":             "ube",
    "ubi":             "ube",      # Bisaya
    "violet yam":      "ube",

    # ── Pechay ────────────────────────────────────────────────
    "pechay":          "pechay",
    "petsay":          "pechay",
    "chinese mustard": "pechay",
    "baby pechay":     "pechay",

    # ── Okra ──────────────────────────────────────────────────
    "okra":            "okra",
    "ladies finger":   "okra",
    "lady finger":     "okra",
    "okra plant":      "okra",
    "saluyot":         "okra",     # sometimes confused

    # ── Lettuce ───────────────────────────────────────────────
    "lettuce":         "lettuce",
    "salad":           "lettuce",  # farmers often say this
    "litsugas":        "lettuce",  # Filipino
    "litsugad":        "lettuce",  # misspelling

    # ── Papaya ────────────────────────────────────────────────
    "papaya":          "papaya",
    "papaia":          "papaya",   # misspelling
    "kapaya":          "papaya",   # Bisaya
    "tapaya":          "papaya",   # Bisaya variant
    "pawpaw":          "papaya",

    # ── Radish ────────────────────────────────────────────────
    "radish":          "radish",
    "labanos":         "radish",   # Filipino
    "labanós":         "radish",
    "rabanos":         "radish",   # misspelling

    # ── Oregano ───────────────────────────────────────────────
    "oregano":         "oregano",
    "oregono":         "oregano",  # misspelling
    "suganda":         "oregano",  # Filipino medicinal name
    "wild oregano":    "oregano",

    # ── Rosemary ──────────────────────────────────────────────
    "rosemary":        "rosemary",
    "rosmary":         "rosemary", # misspelling
    "romero":          "rosemary", # Spanish/Filipino

    # ── Chives ────────────────────────────────────────────────
    "chives":          "chives",
    "kutchay":         "chives",   # Filipino (also used for green onions)
    "kuchai":          "chives",   # variant
    "chive":           "chives",   # singular
}

# ══════════════════════════════════════════════════════════════
# CANONICAL DISPLAY
# Preferred Filipino/Bisaya display name per crop key.
# ══════════════════════════════════════════════════════════════

CANONICAL_DISPLAY = {
    "rice":            "palay",
    "corn":            "mais",
    "tomato":          "kamatis",
    "eggplant":        "talong",
    "kangkong":        "kangkong",
    "camote":          "kamote",
    "cassava":         "cassava",
    "onion":           "sibuyas",
    "garlic":          "bawang",
    "mustasa":         "mustasa",
    "ampalaya":        "ampalaya",
    "alugbati":        "alugbati",
    "sitaw":           "sitaw",
    "sili":            "sili",
    "kalamansi":       "kalamansi",
    "malunggay":       "malunggay",
    "tanglad":         "tanglad",
    "sayote":          "sayote",
    "singkamas":       "singkamas",
    "sigarilyas":      "sigarilyas",
    "mani":            "mani",
    "kundol":          "kundol",
    "patola":          "patola",
    "upo":             "upo",
    "pipino":          "pipino",
    "luya":            "luya",
    "pako":            "pako",
    "carrots":         "karot",
    "potato":          "patatas",
    "chinese_petchay": "petsay",
    "green_onions":    "sibuyas dahon",
    "repolyo":         "repolyo",
    "bokchoy":         "bokchoy",
    "baguio_beans":    "baguio beans",
    "monggo":          "monggo",
    "turmeric":        "luyang dilaw",
    "asthma_plant":    "tawa-tawa",
    "lagundi":         "lagundi",
    "pandan":          "pandan",
    "ube":             "ube",
    "pechay":          "pechay",
    "okra":            "okra",
    "lettuce":         "lettuce",
    "papaya":          "papaya",
    "radish":          "labanos",
    "oregano":         "oregano",
    "basil":           "basil",
    "mint":            "yerba buena",
    "rosemary":        "rosemary",
    "chives":          "kutchay",
}

# ══════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════

def normalize_crop_name(raw_name):
    """
    Returns (matched_key, display_name) or (None, None) on no match.

    Step 1 — direct key match (free, instant)
    Step 2 — alias dict: Tagalog, Bisaya, Ilocano, English,
              and common misspellings (free, instant)
    Step 3 — AI fallback for truly unknown inputs (generic phonetic rules)
    """
    cleaned = raw_name.strip().lower()

    # Step 1 — direct key match
    if cleaned in crop_requirements:
        return cleaned, raw_name.strip()

    # Step 2 — alias dict
    if cleaned in CROP_ALIASES:
        matched_key = CROP_ALIASES[cleaned]
        display = CANONICAL_DISPLAY.get(matched_key, raw_name.strip())
        return matched_key, display

    # Step 3 — AI fallback for anything not in the alias dict
    crop_list_str = ', '.join(crop_requirements.keys())
    try:
        response = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are a crop name matcher for Filipino farmers in Mindanao and Visayas. "
                        "You must reply in EXACTLY this format with no other text: key|display\n"
                        "- key: copied exactly from the crop list, nothing else\n"
                        "- display: corrected Filipino/Bisaya spelling if the farmer typed "
                        "Filipino/Bisaya; English word as-is if they typed English\n"
                        "- If no match at all: none|none\n"
                        "Never add explanation, punctuation, or extra words. Only output key|display."
                    )
                },
                {
                    "role": "user",
                    "content": (
                        f"Farmer typed: '{raw_name}'\n\n"
                        f"Crop list: {crop_list_str}\n\n"
                        f"Phonetic matching rules:\n"
                        f"1. Bisaya/Cebuano: vowels shift freely (a↔e↔i, o↔u), "
                        f"consonants soften or swap (k↔g, p↔b, t↔d), "
                        f"letters dropped or doubled when typing fast on mobile\n"
                        f"2. Say the typed word out loud in Filipino — "
                        f"if it sounds like a crop name, match it\n"
                        f"3. Any Filipino regional dialect word for a crop is valid\n"
                        f"4. English crop names with typos are valid\n\n"
                        f"Reply only: key|display"
                    )
                }
            ],
            max_tokens=30,
            temperature=0,
        )

        raw_result = response.choices[0].message.content.strip()
        print(f"[CROP AI] input='{raw_name}' → raw='{raw_result}'")

        cleaned_result = (
            raw_result
            .lower()
            .strip()
            .strip('"').strip("'").strip('`').strip('.')
        )

        if '|' not in cleaned_result:
            print(f"[CROP AI] No pipe separator found — skipping")
            return None, None

        parts = cleaned_result.split('|')
        if len(parts) >= 2:
            matched_key = parts[0].strip().strip('"').strip("'")
            display     = parts[1].strip().strip('"').strip("'")

            print(f"[CROP AI] key='{matched_key}' display='{display}'")

            if matched_key in crop_requirements:
                return matched_key, display
            else:
                print(f"[CROP AI] '{matched_key}' not found in crop_requirements")

    except Exception as e:
        print(f"[CROP AI] Exception: {e}")

    return None, None


def estimate_om(image_bytes, wet_dry_score):
    np_arr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    h, w, _ = img.shape
    cx, cy = w // 2, h // 2
    size = min(h, w) // 4
    crop_img = img[cy-size:cy+size, cx-size:cx+size]
    hsv = cv2.cvtColor(crop_img, cv2.COLOR_BGR2HSV)
    v_mean = np.mean(hsv[:, :, 2])

    corrected_v = v_mean + (wet_dry_score * 15)

    if corrected_v < 76:
        om_level = 'high'
    elif corrected_v <= 127:
        om_level = 'moderate'
    else:
        om_level = 'low'

    return om_level, round(float(corrected_v), 2)

# ══════════════════════════════════════════════════════════════
# ROUTES
# ══════════════════════════════════════════════════════════════

@app.route('/')
def index():
    return jsonify({"message": "Soiltech API is running"})


@app.route('/crops', methods=['GET'])
def get_crops():
    return jsonify({'crops': list(crop_requirements.keys())})


@app.route('/normalize-crop', methods=['POST'])
def normalize_crop():
    data = request.get_json()
    raw = data.get('crop_name', '').strip()

    if not raw:
        return jsonify({'error': 'crop_name is required'}), 400

    matched, display = normalize_crop_name(raw)

    if matched and matched in crop_requirements:
        return jsonify({'crop': matched, 'display': display})
    else:
        return jsonify({'crop': None, 'error': 'No match found'}), 404


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
        "soil_type"          : soil_type,
        "confidence"         : f"{confidence:.2f}%",
        "om_level"           : om_level,
        "om_brightness_value": brightness_value
    })


@app.route('/recommend', methods=['POST'])
def recommend():
    data           = request.get_json()
    soil_type      = data.get('soil_type', '').lower()
    om_level       = data.get('om_level', '').lower()
    drainage_score = data.get('drainage_score', 0)
    crop_name, _   = normalize_crop_name(data.get('crop_name', ''))

    if not crop_name or crop_name not in crop_requirements:
        return jsonify({'error': f'Crop "{data.get("crop_name", "")}" not recognized. Please try another name.'}), 404

    crop           = crop_requirements[crop_name]
    issues         = []
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
        'soil_type'    : soil_type,
        'crop'         : crop_name,
        'compatibility': compatibility,
        'issues'       : issues,
        'amendments'   : amendment_list
    })


@app.route('/explain', methods=['POST'])
def explain():
    data        = request.get_json()
    soil_type   = data.get('soil_type', '')
    om_level    = data.get('om_level', '')
    crop_name   = data.get('crop_name', '')
    issues      = data.get('issues', [])
    farmer_name = data.get('farmer_name', 'Kuya')

    if not soil_type or not crop_name:
        return jsonify({'error': 'Missing soil_type or crop_name'}), 400

    issues_text = ', '.join(issues) if issues else 'none identified'

    prompt = f"""You are an agricultural advisor speaking directly to a Filipino farmer named {farmer_name}.
Soil type: {soil_type}
Organic matter level: {om_level}
Crop chosen: {crop_name}
Issues identified: {issues_text}

In 3 to 4 plain sentences, explain what will likely happen if {farmer_name} 
plants {crop_name} in this soil without fixing the issues.
Address {farmer_name} directly by name at least once.
Be specific, practical, and avoid technical jargon."""

    try:
        response = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "user", "content": prompt}]
        )
        explanation = response.choices[0].message.content
        return jsonify({'explanation': explanation})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ── Blueprint ──────────────────────────────────────────────────
from chat_route import chat_bp
app.register_blueprint(chat_bp)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)