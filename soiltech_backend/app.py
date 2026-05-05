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


# ══════════════════════════════════════════════════════════════════════════════
# CROP_ALIASES
# Maps every possible input → canonical crop_requirements key
# Covers: Bisaya/Cebuano, Tagalog, Ilocano, English, vowel shifts,
#         consonant swaps, doubled/missing letters, mobile fat-finger errors
# ══════════════════════════════════════════════════════════════════════════════

CROP_ALIASES = {

    # ── Rice ──────────────────────────────────────────────────────────────────
    "humay": "rice", "humay2": "rice", "humay rice": "rice",
    "palay": "rice", "palai": "rice", "pallay": "rice", "palaay": "rice",
    "bigas": "rice", "bugas": "rice", "buggas": "rice",
    "kanin": "rice", "kanen": "rice", "kanon": "rice",
    "rice": "rice", "rais": "rice", "rays": "rice", "ris": "rice",
    "ryce": "rice", "ricee": "rice", "ryse": "rice", "riss": "rice",
    "rise": "rice", "rce": "rice",

    # ── Corn ──────────────────────────────────────────────────────────────────
    "mais": "corn", "mays": "corn", "maes": "corn", "maais": "corn",
    "maiss": "corn", "maize": "corn", "maiz": "corn", "maise": "corn",
    "corn": "corn", "korn": "corn", "corm": "corn", "cornn": "corn",
    "cron": "corn", "conr": "corn", "coen": "corn",

    # ── Tomato ────────────────────────────────────────────────────────────────
    "kamatis": "tomato", "kamatiz": "tomato", "kamates": "tomato",
    "kamatis2": "tomato", "kamutes": "tomato", "komatis": "tomato",
    "camatis": "tomato", "camatiz": "tomato", "kamatys": "tomato",
    "kametes": "tomato", "kamotis": "tomato",
    "tomato": "tomato", "tomatis": "tomato", "tomatoe": "tomato",
    "tomatoes": "tomato", "tomat": "tomato", "tomatoo": "tomato",
    "tometo": "tomato", "tomatto": "tomato", "tomaeto": "tomato",
    "tomto": "tomato", "tamoto": "tomato", "tamato": "tomato",
    "tomatos": "tomato",

    # ── Eggplant ──────────────────────────────────────────────────────────────
    "talong": "eggplant", "taloong": "eggplant", "tallong": "eggplant",
    "talung": "eggplant", "talungg": "eggplant", "taloung": "eggplant",
    "tarong": "eggplant", "taroong": "eggplant", "tarung": "eggplant",
    "talond": "eggplant", "tarond": "eggplant", "taroung": "eggplant",
    "talong2": "eggplant", "talungs": "eggplant",
    "eggplant": "eggplant", "egplant": "eggplant", "eggplnat": "eggplant",
    "igplant": "eggplant", "egplnat": "eggplant", "eggplan": "eggplant",
    "egg plant": "eggplant", "egg plnt": "eggplant",
    "eggplnt": "eggplant", "egplnt": "eggplant", "egplant2": "eggplant",
    "eggpant": "eggplant", "eggplat": "eggplant", "egplannt": "eggplant",
    "egglant": "eggplant", "eggpland": "eggplant",
    "aubergine": "eggplant", "aubergene": "eggplant", "aubergin": "eggplant",
    "brinjal": "eggplant", "bringal": "eggplant", "brinjel": "eggplant",

    # ── Kangkong ──────────────────────────────────────────────────────────────
    "kangkong": "kangkong", "kangkon": "kangkong", "kangkung": "kangkong",
    "kang kong": "kangkong", "kangkong2": "kangkong", "kangkung2": "kangkong",
    "tangkong": "kangkong", "tangkon": "kangkong", "tangkung": "kangkong",
    "tinangkong": "kangkong", "tinangkon": "kangkong",
    "kangong": "kangkong", "kangkong3": "kangkong", "kangkong4": "kangkong",
    "water spinach": "kangkong", "waterspinach": "kangkong",
    "river spinach": "kangkong", "riverspinach": "kangkong",
    "water spinch": "kangkong", "wtr spinach": "kangkong",

    # ── Camote ────────────────────────────────────────────────────────────────
    "camote": "camote", "kamote": "camote", "kamoti": "camote",
    "kamute": "camote", "kamuti": "camote", "camuote": "camote",
    "kamotee": "camote", "camoti": "camote", "kamotey": "camote",
    "camotie": "camote", "kamuote": "camote", "kamotii": "camote",
    "tamus": "camote", "tamis": "camote", "tammus": "camote",
    "sweet potato": "camote", "sweetpotato": "camote",
    "sweet patato": "camote", "sweat potato": "camote",
    "swt potato": "camote", "sweet potatoe": "camote",
    "sweet pottato": "camote", "swet potato": "camote",
    "camoteng kahoy": "camote", "kamoteng kahoy": "camote",
    "sweetpotato2": "camote",

    # ── Cassava ───────────────────────────────────────────────────────────────
    "cassava": "cassava", "kasava": "cassava", "cassaba": "cassava",
    "casava": "cassava", "kasaba": "cassava", "kasabba": "cassava",
    "cassavva": "cassava", "cassaava": "cassava", "casssava": "cassava",
    "kassava": "cassava", "kasabba2": "cassava",
    "balinghoy": "cassava", "balinghoi": "cassava", "balingoy": "cassava",
    "balinghoy2": "cassava", "balinhoy": "cassava", "balingoy2": "cassava",
    "manioc": "cassava", "maniok": "cassava", "mannioc": "cassava",
    "yuca": "cassava", "yucca": "cassava", "yukka": "cassava",

    # ── Onion ─────────────────────────────────────────────────────────────────
    "sibuyas": "onion", "sibyas": "onion", "sibuas": "onion",
    "sibuias": "onion", "sibuyas2": "onion", "sibuyaz": "onion",
    "sibuyas3": "onion", "sibias": "onion", "sivuyas": "onion",
    "bumbay": "onion", "bombay": "onion", "bumbai": "onion",
    "bumbay2": "onion", "bombai": "onion",
    "lasona": "onion", "lasuna": "onion", "lasona2": "onion",
    "onion": "onion", "oniun": "onion", "onyon": "onion",
    "onyun": "onion", "unyon": "onion", "unyun": "onion",
    "onions": "onion", "onian": "onion", "onin": "onion",
    "onyons": "onion", "onins": "onion",

    # ── Garlic ────────────────────────────────────────────────────────────────
    "bawang": "garlic", "bawng": "garlic", "bawwang": "garlic",
    "dawang": "garlic", "bawangg": "garlic", "bawwng": "garlic",
    "bavang": "garlic", "bawamg": "garlic",
    "ahos": "garlic", "ahus": "garlic", "ajos": "garlic", "aho": "garlic",
    "ahos2": "garlic", "ahoss": "garlic", "ajus": "garlic",
    "garlic": "garlic", "garlik": "garlic", "garlicc": "garlic",
    "garlick": "garlic", "garlic2": "garlic", "garlc": "garlic",
    "garliic": "garlic", "galic": "garlic", "garlik2": "garlic",
    "bawang putih": "garlic", "garlic bulb": "garlic",

    # ── Mustasa ───────────────────────────────────────────────────────────────
    "mustasa": "mustasa", "mustaza": "mustasa", "mustassa": "mustasa",
    "mustasaa": "mustasa", "mustaasa": "mustasa", "mustsa": "mustasa",
    "mustassa2": "mustasa", "mustasya": "mustasa", "mustaza2": "mustasa",
    "mustard": "mustasa", "mustard greens": "mustasa",
    "mustasa greens": "mustasa", "mustasa leaf": "mustasa",
    "mustart": "mustasa", "mustad": "mustasa", "mustrd": "mustasa",
    "mustard green": "mustasa",

    # ── Ampalaya ──────────────────────────────────────────────────────────────
    "ampalaya": "ampalaya", "amplaya": "ampalaya", "ampalaia": "ampalaya",
    "ampalay": "ampalaya", "ampalya": "ampalaya", "ampalaiya": "ampalaya",
    "ampalaia2": "ampalaya", "ampalaya2": "ampalaya", "ampalaia3": "ampalaya",
    "amplaaya": "ampalaya", "ampalaaya": "ampalaya",
    "parya": "ampalaya", "paria": "ampalaya", "pariya": "ampalaya",
    "paria2": "ampalaya", "paryah": "ampalaya", "parya2": "ampalaya",
    "bitter gourd": "ampalaya", "bittergourd": "ampalaya",
    "bitter melon": "ampalaya", "bittermelon": "ampalaya",
    "bitter gord": "ampalaya", "bitter melun": "ampalaya",
    "biter melon": "ampalaya", "bitter melon2": "ampalaya",

    # ── Alugbati ──────────────────────────────────────────────────────────────
    "alugbati": "alugbati", "alugbate": "alugbati", "alugbat": "alugbati",
    "alugbatti": "alugbati", "alogbati": "alugbati", "alugbate2": "alugbati",
    "alugboti": "alugbati", "alugbate3": "alugbati",
    "libato": "alugbati", "libatu": "alugbati", "libato2": "alugbati",
    "dundula": "alugbati", "dundola": "alugbati",
    "malabar spinach": "alugbati", "malabarspinach": "alugbati",
    "malabar spinch": "alugbati", "malabar spinash": "alugbati",

    # ── Sitaw ─────────────────────────────────────────────────────────────────
    "sitaw": "sitaw", "sitao": "sitaw", "sitau": "sitaw",
    "sitaw2": "sitaw", "sitaaw": "sitaw", "sitaow": "sitaw",
    "batong": "sitaw", "batoong": "sitaw", "batung": "sitaw",
    "battong": "sitaw", "batongan": "sitaw", "batong2": "sitaw",
    "batungg": "sitaw", "battoong": "sitaw",
    "hantak": "sitaw", "hantag": "sitaw", "hanntag": "sitaw",
    "string beans": "sitaw", "string bean": "sitaw", "stringbeans": "sitaw",
    "yardlong beans": "sitaw", "yard long beans": "sitaw",
    "long beans": "sitaw", "longbeans": "sitaw",
    "string bens": "sitaw", "strig beans": "sitaw",
    "yard long bean": "sitaw", "yardlong bean": "sitaw",
    "stringbean": "sitaw", "string ban": "sitaw",

    # ── Sili ──────────────────────────────────────────────────────────────────
    "sili": "sili", "silli": "sili", "sily": "sili",
    "sili2": "sili", "silii": "sili", "siliy": "sili",
    "chili": "sili", "chilli": "sili", "chilly": "sili",
    "chili pepper": "sili", "chile": "sili", "chille": "sili",
    "chilli pepper": "sili", "chili2": "sili",
    "pepper": "sili", "hot pepper": "sili", "lada": "sili",
    "lada2": "sili", "ladda": "sili",
    "siling labuyo": "sili", "siling haba": "sili",
    "siling labuio": "sili", "siling labyo": "sili",

    # ── Kalamansi ─────────────────────────────────────────────────────────────
    "kalamansi": "kalamansi", "calamansi": "kalamansi",
    "calamansee": "kalamansi", "kalamansy": "kalamansi",
    "kalamansee": "kalamansi", "kalamansei": "kalamansi",
    "calamansii": "kalamansi", "kalamannsi": "kalamansi",
    "calamondin": "kalamansi", "calamonding": "kalamansi",
    "kalamunding": "kalamansi", "kalamansi lime": "kalamansi",
    "lemonsito": "kalamansi", "lemonsitu": "kalamansi",
    "lemoncito": "kalamansi", "lemonsitoo": "kalamansi",
    "limon": "kalamansi", "limun": "kalamansi", "limon2": "kalamansi",
    "lemon": "kalamansi", "limon3": "kalamansi",

    # ── Malunggay ─────────────────────────────────────────────────────────────
    "malunggay": "malunggay", "malungay": "malunggay",
    "malunggai": "malunggay", "malungai": "malunggay",
    "malunggey": "malunggay", "malunggay2": "malunggay",
    "malunggei": "malunggay", "malunggoy": "malunggay",
    "malungey": "malunggay", "malunggays": "malunggay",
    "kamunggay": "malunggay", "kamunggai": "malunggay",
    "kamungay": "malunggay", "kamunggey": "malunggay",
    "kamunggoy": "malunggay", "kamunggay2": "malunggay",
    "kamungai": "malunggay", "kamungey": "malunggay",
    "moringa": "malunggay", "muringa": "malunggay",
    "moringga": "malunggay", "moringo": "malunggay",
    "muringa2": "malunggay", "moringa2": "malunggay",
    "morings": "malunggay", "muringga": "malunggay",
    "morenga": "malunggay", "moringah": "malunggay",
    "drumstick tree": "malunggay", "drumstick": "malunggay",
    "drumstic": "malunggay", "drumstick2": "malunggay",

    # ── Tanglad ───────────────────────────────────────────────────────────────
    "tanglad": "tanglad", "tanglads": "tanglad", "tagland": "tanglad",
    "tangad": "tanglad", "tanglad2": "tanglad", "tangland": "tanglad",
    "tanglads2": "tanglad", "tanngad": "tanglad",
    "salai": "tanglad", "salay": "tanglad", "salai2": "tanglad",
    "sallai": "tanglad", "salay2": "tanglad",
    "lemongrass": "tanglad", "lemon grass": "tanglad",
    "lemograss": "tanglad", "lemon gras": "tanglad",
    "lemon grss": "tanglad", "lemongras": "tanglad",
    "lemongrss": "tanglad", "lemon grass2": "tanglad",

    # ── Sayote ────────────────────────────────────────────────────────────────
    "sayote": "sayote", "sayoti": "sayote", "saiote": "sayote",
    "sayor": "sayote", "sayote2": "sayote", "sayotee": "sayote",
    "sayoti2": "sayote", "saioti": "sayote",
    "chayote": "sayote", "chayoti": "sayote", "chayotee": "sayote",
    "choko": "sayote", "choko2": "sayote",
    "vegetable pear": "sayote", "veg pear": "sayote",

    # ── Singkamas ─────────────────────────────────────────────────────────────
    "singkamas": "singkamas", "sengkamas": "singkamas",
    "singkamaz": "singkamas", "singkamas tuber": "singkamas",
    "singkammas": "singkamas", "singkamas2": "singkamas",
    "sengkamaz": "singkamas", "singkamaz2": "singkamas",
    "jicama": "singkamas", "hikama": "singkamas",
    "jicamma": "singkamas", "hikamma": "singkamas",
    "turnip": "singkamas", "turnips": "singkamas",

    # ── Sigarilyas ────────────────────────────────────────────────────────────
    "sigarilyas": "sigarilyas", "sigarilya": "sigarilyas",
    "sigarillas": "sigarilyas", "sigarilias": "sigarilyas",
    "sigarilyas2": "sigarilyas", "sigarilias2": "sigarilyas",
    "sigarilyas3": "sigarilyas", "sigarillyas": "sigarilyas",
    "winged beans": "sigarilyas", "winged bean": "sigarilyas",
    "wingedbeans": "sigarilyas", "winged bens": "sigarilyas",
    "four angled bean": "sigarilyas", "4 angled bean": "sigarilyas",
    "4-angled bean": "sigarilyas",

    # ── Mani ──────────────────────────────────────────────────────────────────
    "mani": "mani", "manies": "mani", "manny": "mani",
    "maani": "mani", "manni": "mani", "mani2": "mani",
    "peanut": "mani", "peanuts": "mani", "peanat": "mani",
    "peanut2": "mani", "penut": "mani", "peanuts2": "mani",
    "peanett": "mani", "peenut": "mani",
    "groundnut": "mani", "ground nut": "mani",
    "groundnuts": "mani", "groundnut2": "mani",

    # ── Kundol ────────────────────────────────────────────────────────────────
    "kundol": "kundol", "kondol": "kundol", "kundol2": "kundol",
    "kondol2": "kundol", "kundoll": "kundol",
    "wax gourd": "kundol", "waxgourd": "kundol",
    "winter melon": "kundol", "wintermelon": "kundol",
    "white gourd": "kundol", "whitegourd": "kundol",
    "winter melon2": "kundol",

    # ── Patola ────────────────────────────────────────────────────────────────
    "patola": "patola", "patula": "patola", "pattola": "patola",
    "patola2": "patola", "patolla": "patola", "patula2": "patola",
    "sponge gourd": "patola", "spongegourd": "patola",
    "luffa": "patola", "lufa": "patola", "luffa2": "patola",
    "loofah": "patola", "loofa": "patola", "lufah": "patola",

    # ── Upo ───────────────────────────────────────────────────────────────────
    "upo": "upo", "upo squash": "upo", "upoo": "upo",
    "upo2": "upo", "uppo": "upo",
    "bottle gourd": "upo", "bottlegourd": "upo",
    "calabash": "upo", "calabahs": "upo", "bottle gord": "upo",

    # ── Pipino ────────────────────────────────────────────────────────────────
    "pipino": "pipino", "pepino": "pipino", "pepeno": "pipino",
    "pipinu": "pipino", "piipino": "pipino", "ppino": "pipino",
    "pipino2": "pipino", "pepinu": "pipino", "piepino": "pipino",
    "cucumber": "pipino", "cucmber": "pipino", "cuccumber": "pipino",
    "cucuumber": "pipino", "cucumbr": "pipino", "cucumbe": "pipino",
    "cucumbber": "pipino", "cuucumber": "pipino", "cucmbre": "pipino",
    "cuecumber": "pipino", "cucumbar": "pipino",

    # ── Luya ──────────────────────────────────────────────────────────────────
    "luya": "luya", "loya": "luya", "luia": "luya",
    "luy a": "luya", "loy a": "luya", "luiya": "luya",
    "loyya": "luya", "luya2": "luya", "loya2": "luya",
    "luyya": "luya", "luiia": "luya",
    "ginger": "luya", "gingger": "luya", "gingr": "luya",
    "giner": "luya", "ginggr": "luya", "ginjer": "luya",
    "gingger2": "luya", "ginger": "luya", "genger": "luya",

    # ── Pako ──────────────────────────────────────────────────────────────────
    "pako": "pako", "pakis": "pako", "pakko": "pako",
    "pako2": "pako", "pakiss": "pako",
    "fern": "pako", "vegetable fern": "pako", "vegfern": "pako",
    "veg fern": "pako", "fern2": "pako",

    # ── Carrots ───────────────────────────────────────────────────────────────
    "carrots": "carrots", "carrot": "carrots", "karot": "carrots",
    "karots": "carrots", "carot": "carrots", "carots": "carrots",
    "karrot": "carrots", "karrots": "carrots", "carrt": "carrots",
    "karoot": "carrots", "carroot": "carrots", "carrrot": "carrots",
    "carrot2": "carrots", "karot2": "carrots",

    # ── Potato ────────────────────────────────────────────────────────────────
    "potato": "potato", "potatoes": "potato", "patatas": "potato",
    "patata": "potato", "potatoe": "potato", "poteto": "potato",
    "patato": "potato", "potatos": "potato", "patatas2": "potato",
    "potaato": "potato", "pottato": "potato", "potatto": "potato",
    "pottatoes": "potato", "potatos2": "potato",

    # ── Chinese Petchay ───────────────────────────────────────────────────────
    "chinese_petchay": "chinese_petchay",
    "chinese petchay": "chinese_petchay",
    "chinese pechay": "chinese_petchay",
    "petsay": "chinese_petchay", "petsai": "chinese_petchay",
    "petchay baguio": "chinese_petchay", "pechay baguio": "chinese_petchay",
    "napa cabbage": "chinese_petchay", "napa": "chinese_petchay",
    "chinese cabbage": "chinese_petchay",
    "chinise cabbage": "chinese_petchay",
    "chines petchay": "chinese_petchay",
    "china cabbage": "chinese_petchay",
    "chinese petsay": "chinese_petchay",
    "chines cabbage": "chinese_petchay",

    # ── Green Onions ──────────────────────────────────────────────────────────
    "green_onions": "green_onions",
    "green onions": "green_onions", "green onion": "green_onions",
    "greenonion": "green_onions", "green onyun": "green_onions",
    "grn onion": "green_onions", "gren onion": "green_onions",
    "scallion": "green_onions", "scallions": "green_onions",
    "scallian": "green_onions", "scallins": "green_onions",
    "spring onion": "green_onions", "spring onions": "green_onions",
    "sibuyas dahon": "green_onions", "sibuyas na dahon": "green_onions",
    "dahon ng sibuyas": "green_onions",
    "kutchay": "green_onions", "kuchay": "green_onions",
    "kutchay2": "green_onions", "kuchay2": "green_onions",
    "kutchey": "green_onions", "kuchai": "green_onions",

    # ── Repolyo ───────────────────────────────────────────────────────────────
    "repolyo": "repolyo", "repollo": "repolyo", "repullo": "repolyo",
    "repolio": "repolyo", "repulyo": "repolyo", "repolyo2": "repolyo",
    "repollyo": "repolyo", "repollio": "repolyo",
    "cabbage": "repolyo", "cabbge": "repolyo", "kabbage": "repolyo",
    "cabagge": "repolyo", "cabbagge": "repolyo", "cabbage2": "repolyo",
    "cabbege": "repolyo", "cabage": "repolyo",

    # ── Bokchoy ───────────────────────────────────────────────────────────────
    "bokchoy": "bokchoy", "bok choy": "bokchoy", "bokchoi": "bokchoy",
    "bok choi": "bokchoy", "pak choi": "bokchoy", "pok choy": "bokchoy",
    "bochoy": "bokchoy", "bokchoy2": "bokchoy", "bokhoy": "bokchoy",
    "bokchoi2": "bokchoy", "bok choy2": "bokchoy",

    # ── Papaya ────────────────────────────────────────────────────────────────
    "papaya": "papaya", "papaia": "papaya", "papaiya": "papaya",
    "kapaya": "papaya", "tapaya": "papaya", "papayya": "papaya",
    "papya": "papaya", "papaia2": "papaya", "kapaiya": "papaya",
    "tapaiya": "papaya", "papaya2": "papaya", "papaay": "papaya",
    "pawpaw": "papaya", "pawpaw2": "papaya",

    # ── Baguio Beans ──────────────────────────────────────────────────────────
    "baguio_beans": "baguio_beans",
    "baguio beans": "baguio_beans", "baguio bean": "baguio_beans",
    "green beans": "baguio_beans", "green bean": "baguio_beans",
    "french beans": "baguio_beans", "french bean": "baguio_beans",
    "snap beans": "baguio_beans", "snap bean": "baguio_beans",
    "habitchuelas": "baguio_beans", "habichuelas": "baguio_beans",
    "bagyo beans": "baguio_beans", "baguio bens": "baguio_beans",
    "baguio bean2": "baguio_beans", "bagueo beans": "baguio_beans",
    "bagyo bean": "baguio_beans",

    # ── Monggo ────────────────────────────────────────────────────────────────
    "monggo": "monggo", "munggo": "monggo", "mongo": "monggo",
    "mungo": "monggo", "monggoo": "monggo", "mongggo": "monggo",
    "mung bean": "monggo", "mung beans": "monggo", "mungbean": "monggo",
    "green gram": "monggo", "greengram": "monggo",
    "mung bens": "monggo", "munggo2": "monggo",

    # ── Radish ────────────────────────────────────────────────────────────────
    "radish": "radish", "raddish": "radish", "radis": "radish",
    "labanos": "radish", "labanós": "radish", "labanu": "radish",
    "rabanos": "radish", "labanos2": "radish", "labbanoss": "radish",
    "labanus": "radish", "labanos3": "radish", "labanoss": "radish",
    "raddis": "radish", "radich": "radish", "radiss": "radish",

    # ── Turmeric ──────────────────────────────────────────────────────────────
    "turmeric": "turmeric", "termeric": "turmeric", "tumeric": "turmeric",
    "tumerik": "turmeric", "turmeric2": "turmeric", "turmerik": "turmeric",
    "termeric2": "turmeric", "turmeric3": "turmeric",
    "luyang dilaw": "turmeric", "luyang dilau": "turmeric",
    "luyang dilaw2": "turmeric", "luyang dila": "turmeric",
    "dilaw": "turmeric", "dilau": "turmeric",
    "kalawag": "turmeric", "kalawog": "turmeric",
    "kunig": "turmeric", "kuning": "turmeric",
    "kalawag2": "turmeric", "kalawog2": "turmeric",

    # ── Asthma Plant ──────────────────────────────────────────────────────────
    "asthma_plant": "asthma_plant", "asthma plant": "asthma_plant",
    "tawa tawa": "asthma_plant", "tawa-tawa": "asthma_plant",
    "tawatawa": "asthma_plant", "tawa": "asthma_plant",
    "tawa2": "asthma_plant", "tawa tawa2": "asthma_plant",
    "tawa-tawa2": "asthma_plant",
    "gatas gatas": "asthma_plant", "gatas-gatas": "asthma_plant",
    "gatasgatas": "asthma_plant", "gatas gatas2": "asthma_plant",

    # ── Lagundi ───────────────────────────────────────────────────────────────
    "lagundi": "lagundi", "lagunde": "lagundi", "lagunti": "lagundi",
    "lagundi2": "lagundi", "lagundy": "lagundi", "lagundii": "lagundi",
    "dangla": "lagundi", "danggla": "lagundi", "dangla2": "lagundi",
    "five leaved chaste tree": "lagundi",
    "five-leaved chaste tree": "lagundi",

    # ── Basil ─────────────────────────────────────────────────────────────────
    "basil": "basil", "bazil": "basil", "bassil": "basil",
    "basil2": "basil", "basill": "basil", "bazill": "basil",
    "sweet basil": "basil", "sweet bazil": "basil",
    "balanoy": "basil", "balanoi": "basil", "balanoy2": "basil",
    "balanoi2": "basil", "balanuy": "basil",
    "solasi": "basil", "solasin": "basil", "solasi2": "basil",

    # ── Pandan ────────────────────────────────────────────────────────────────
    "pandan": "pandan", "pandaan": "pandan", "pandan leaf": "pandan",
    "pandan leaves": "pandan", "pandan2": "pandan",
    "pandann": "pandan", "pandaan2": "pandan",
    "screwpine": "pandan", "screw pine": "pandan",
    "pangdan": "pandan", "pangdan2": "pandan", "pandang": "pandan",

    # ── Mint ──────────────────────────────────────────────────────────────────
    "mint": "mint", "mnt": "mint", "minnt": "mint",
    "mint2": "mint", "mintt": "mint", "mints": "mint",
    "hierba buena": "mint", "yerba buena": "mint",
    "herba buena": "mint", "yerbas buena": "mint",
    "hierba buena2": "mint", "herba buena2": "mint",
    "peppermint": "mint", "spearmint": "mint",
    "pepermint": "mint", "spearemint": "mint",

    # ── Ube ───────────────────────────────────────────────────────────────────
    "ube": "ube", "ubi": "ube", "ubbe": "ube", "ubee": "ube",
    "ube2": "ube", "ubii": "ube", "ubee2": "ube",
    "purple yam": "ube", "violet yam": "ube", "yam": "ube",
    "purpleyam": "ube", "purple yam2": "ube",

    # ── Pechay ────────────────────────────────────────────────────────────────
    "pechay": "pechay", "pitsay": "pechay", "pechey": "pechay",
    "pechai": "pechay", "pechay2": "pechay", "petchay": "pechay",
    "petsay pechay": "pechay", "baby pechay": "pechay",
    "baby petsay": "pechay", "baby pechay2": "pechay",
    "chinese mustard": "pechay", "chinese mustad": "pechay",

    # ── Okra ──────────────────────────────────────────────────────────────────
    "okra": "okra", "ukra": "okra", "okraa": "okra",
    "okras": "okra", "okka": "okra", "okra2": "okra",
    "okrra": "okra", "okkra": "okra", "okrah": "okra",
    "ladies finger": "okra", "lady finger": "okra",
    "ladyfinger": "okra", "ladies fingers": "okra",
    "ladys finger": "okra", "ladiesfinger": "okra",
    "ladyfinger2": "okra", "ladies figr": "okra",

    # ── Lettuce ───────────────────────────────────────────────────────────────
    "lettuce": "lettuce", "letuce": "lettuce", "lettuse": "lettuce",
    "lettuces": "lettuce", "lettucee": "lettuce", "lettuse2": "lettuce",
    "lletuce": "lettuce", "lettcue": "lettuce",
    "litsugas": "lettuce", "litsugad": "lettuce",
    "letius": "lettuce", "litsuga": "lettuce",
    "salad": "lettuce",

    # ── Oregano ───────────────────────────────────────────────────────────────
    "oregano": "oregano", "oregono": "oregano", "oreganno": "oregano",
    "origano": "oregano", "oregnao": "oregano", "oregano2": "oregano",
    "oreganoo": "oregano", "origano2": "oregano",
    "suganda": "oregano", "wild oregano": "oregano",
    "oregano leaf": "oregano", "suganda2": "oregano",

    # ── Rosemary ──────────────────────────────────────────────────────────────
    "rosemary": "rosemary", "rosmary": "rosemary", "rosemerry": "rosemary",
    "rozzmarry": "rosemary", "rosemarry": "rosemary", "rosemary2": "rosemary",
    "roseemary": "rosemary", "rosmarry": "rosemary",
    "romero": "rosemary", "romero herb": "rosemary", "romero2": "rosemary",

    # ── Chives ────────────────────────────────────────────────────────────────
    "chives": "chives", "chive": "chives", "chivs": "chives",
    "chives2": "chives", "chivves": "chives",
    "kuchai": "chives", "chinese chives": "chives",
    "garlic chives": "chives", "kuchai2": "chives",
}


# ══════════════════════════════════════════════════════════════════════════════
# CANONICAL_DISPLAY  (Tagalog — default Filipino display)
# Used when farmer types Tagalog, or as Bisaya fallback
# ══════════════════════════════════════════════════════════════════════════════

CANONICAL_DISPLAY = {
    "rice":            "Palay",
    "corn":            "Mais",
    "tomato":          "Kamatis",
    "eggplant":        "Talong",
    "kangkong":        "Kangkong",
    "camote":          "Kamote",
    "cassava":         "Cassava",
    "onion":           "Sibuyas",
    "garlic":          "Bawang",
    "mustasa":         "Mustasa",
    "ampalaya":        "Ampalaya",
    "alugbati":        "Alugbati",
    "sitaw":           "Sitaw",
    "sili":            "Sili",
    "kalamansi":       "Kalamansi",
    "malunggay":       "Malunggay",
    "tanglad":         "Tanglad",
    "sayote":          "Sayote",
    "singkamas":       "Singkamas",
    "sigarilyas":      "Sigarilyas",
    "mani":            "Mani",
    "kundol":          "Kundol",
    "patola":          "Patola",
    "upo":             "Upo",
    "pipino":          "Pipino",
    "luya":            "Luya",
    "pako":            "Pako",
    "carrots":         "Karot",
    "potato":          "Patatas",
    "chinese_petchay": "Petsay",
    "green_onions":    "Sibuyas Dahon",
    "repolyo":         "Repolyo",
    "bokchoy":         "Bokchoy",
    "baguio_beans":    "Baguio Beans",
    "monggo":          "Monggo",
    "turmeric":        "Luyang Dilaw",
    "asthma_plant":    "Tawa-Tawa",
    "lagundi":         "Lagundi",
    "pandan":          "Pandan",
    "ube":             "Ube",
    "pechay":          "Pechay",
    "okra":            "Okra",
    "lettuce":         "Lettuce",
    "papaya":          "Papaya",
    "radish":          "Labanos",
    "oregano":         "Oregano",
    "basil":           "Basil",
    "mint":            "Yerba Buena",
    "rosemary":        "Rosemary",
    "chives":          "Kutchay",
}


# ══════════════════════════════════════════════════════════════════════════════
# BISAYA_DISPLAY
# Canonical Bisaya/Cebuano display name per crop key.
# Used when farmer types Bisaya.
# Falls back to CANONICAL_DISPLAY (Tagalog) if None.
# ══════════════════════════════════════════════════════════════════════════════

BISAYA_DISPLAY = {
    "rice":            "Humay",
    "corn":            "Mais",           # same across languages
    "tomato":          "Kamatis",        # same across languages
    "eggplant":        "Tarong",
    "kangkong":        "Tangkong",
    "camote":          "Kamote",         # same
    "cassava":         "Balinghoy",
    "onion":           "Bumbay",
    "garlic":          "Ahos",
    "mustasa":         "Mustasa",        # same
    "ampalaya":        "Parya",
    "alugbati":        "Libato",
    "sitaw":           "Sitaw",          # same (batong is a variant but sitaw is also used)
    "sili":            "Sili",           # same
    "kalamansi":       "Lemonsito",
    "malunggay":       "Kamunggay",
    "tanglad":         "Salai",
    "sayote":          "Sayote",         # same
    "singkamas":       "Singkamas",      # same
    "sigarilyas":      "Sigarilyas",     # same
    "mani":            "Mani",           # same
    "kundol":          "Kundol",         # same
    "patola":          "Patola",         # same
    "upo":             "Upo",            # same
    "pipino":          "Pipino",         # same
    "luya":            "Luya",           # same (loya is misspelling, luya is Bisaya too)
    "pako":            "Pakis",
    "carrots":         "Karot",          # same
    "potato":          "Patatas",        # same
    "chinese_petchay": "Petsay",         # same
    "green_onions":    "Kutchay",
    "repolyo":         "Repolyo",        # same
    "bokchoy":         "Bokchoy",        # same
    "baguio_beans":    "Baguio Beans",   # same
    "monggo":          "Monggo",         # same
    "turmeric":        "Kalawag",
    "asthma_plant":    "Gatas-Gatas",
    "lagundi":         "Dangla",
    "pandan":          "Pandang",
    "ube":             "Ube",            # same across all languages
    "pechay":          "Pechay",         # same
    "okra":            "Okra",           # same
    "lettuce":         "Lettuce",        # same
    "papaya":          "Kapaya",
    "radish":          "Labanos",        # same
    "oregano":         "Oregano",        # same
    "basil":           "Solasi",
    "mint":            "Hierba Buena",
    "rosemary":        "Rosemary",       # same
    "chives":          "Kuchai",
}


# ══════════════════════════════════════════════════════════════════════════════
# ENGLISH_DISPLAY
# Used for default UI grid (no user input) and when farmer typed English.
# Rule: if no English equivalent exists, use the most recognized name.
# ══════════════════════════════════════════════════════════════════════════════

ENGLISH_DISPLAY = {
    "rice":            "Rice",
    "corn":            "Corn",
    "tomato":          "Tomato",
    "eggplant":        "Eggplant",
    "kangkong":        "Kangkong",       # no common English, keep name
    "camote":          "Sweet Potato",
    "cassava":         "Cassava",
    "onion":           "Onion",
    "garlic":          "Garlic",
    "mustasa":         "Mustasa",        # no direct English, keep name
    "ampalaya":        "Bitter Melon",
    "alugbati":        "Malabar Spinach",
    "sitaw":           "String Beans",
    "sili":            "Chili",
    "kalamansi":       "Kalamansi",      # recognized as-is globally
    "malunggay":       "Moringa",
    "tanglad":         "Lemongrass",
    "sayote":          "Chayote",
    "singkamas":       "Jicama",
    "sigarilyas":      "Winged Beans",
    "mani":            "Peanut",
    "kundol":          "Winter Melon",
    "patola":          "Luffa",
    "upo":             "Bottle Gourd",
    "pipino":          "Cucumber",
    "luya":            "Ginger",
    "pako":            "Vegetable Fern",
    "carrots":         "Carrots",
    "potato":          "Potato",
    "chinese_petchay": "Chinese Cabbage",
    "green_onions":    "Green Onions",
    "repolyo":         "Cabbage",
    "bokchoy":         "Bok Choy",
    "baguio_beans":    "Green Beans",
    "monggo":          "Mung Beans",
    "turmeric":        "Turmeric",
    "asthma_plant":    "Tawa-Tawa",      # no English, use recognized name
    "lagundi":         "Lagundi",        # no English, use recognized name
    "pandan":          "Pandan",         # recognized globally
    "ube":             "Ube",            # recognized globally
    "pechay":          "Pechay",         # recognized globally
    "okra":            "Okra",
    "lettuce":         "Lettuce",
    "papaya":          "Papaya",
    "radish":          "Radish",
    "oregano":         "Oregano",
    "basil":           "Basil",
    "mint":            "Mint",
    "rosemary":        "Rosemary",
    "chives":          "Chives",
}


# ══════════════════════════════════════════════════════════════════════════════
# LANGUAGE DETECTION
# ══════════════════════════════════════════════════════════════════════════════

# FIX (Problem 2): Expanded to include phonetic English misspellings
ENGLISH_CROP_WORDS = {
    # Clean English
    "rice", "corn", "maize", "tomato", "tomatoes", "eggplant", "cucumber",
    "ginger", "garlic", "onion", "onions", "carrot", "carrots", "potato",
    "potatoes", "cabbage", "lettuce", "radish", "chili", "chilli", "chilly",
    "pepper", "peanut", "peanuts", "basil", "mint", "oregano", "rosemary",
    "chives", "turmeric", "cassava", "manioc", "yuca", "yucca", "luffa",
    "loofah", "chayote", "jicama", "moringa", "lemongrass", "sweet potato",
    "pandan", "bitter melon", "bitter gourd", "mung bean", "mung beans",
    "string bean", "string beans", "winged bean", "winged beans",
    "green bean", "green beans", "green onion", "green onions",
    "scallion", "scallions", "spring onion", "bok choy", "napa cabbage",
    "bottle gourd", "winter melon", "wax gourd", "sponge gourd",
    "vegetable fern", "fern", "yam", "purple yam", "malabar spinach",
    "water spinach", "river spinach", "aubergine", "brinjal",
    "pawpaw", "papaya", "turnip",
    # Phonetic English misspellings (Problem 2 fix)
    "muringa", "muringga", "moringo", "morenga", "moringah",
    "igplant", "egplant", "eggplnat", "egplnat", "eggplan",
    "eggplnt", "egplnt", "eggpant", "eggplat", "egglant",
    "tomatoe", "tomatoes", "tometo", "tomatto", "tomto",
    "cucmber", "cuccumber", "cucuumber", "cucumbr", "cucumbe",
    "cucumbber", "cuucumber", "cucmbre", "cuecumber", "cucumbar",
    "gingger", "gingr", "giner", "ginjer", "ginger", "genger",
    "aubergene", "aubergin", "bringal", "brinjel",
    "penut", "peanat", "peanett", "peenut",
    "lemongras", "lemongrss", "lemograss",
    "tumeric", "termeric", "tumerik", "turmerik",
    "chayoti", "chayotee",
    "jiccama", "hikama",
    "lufa", "lufah", "loofa",
    "sweetpotato", "sweet patato", "sweat potato",
    "maniok", "mannioc", "yukka",
    "drumstic", "drumstick",
    "scallian", "scallins",
    "pawpaw",
    "bitermelon", "bittergourd", "biter melon",
    "bottlegourd", "wintermelon", "waxgourd",
    "vegfern", "veg fern",
    "purpleyam",
    "peppermint", "spearmint", "pepermint",
    "rosemarry", "rosmary", "rosemerry",
    "bazil", "bassil",
    "garlik", "garlicc", "garlick", "galic",
    "raddish", "radis", "radiss", "radich",
    "letuce", "lettuse", "letius",
    "cabagge", "cabbge", "kabbage",
    "carot", "carots", "karrot", "karrots", "carrt",
    "potatoe", "poteto", "patato",
}

# Bisaya-specific words (not shared with Tagalog)
BISAYA_CROP_WORDS = {
    "humay", "bugas", "buggas", "kanon", "kanen",
    "tarong", "taroong", "tarung", "tarond", "taroung",
    "tangkong", "tangkon", "tangkung", "tinangkong", "tinangkon",
    "kamuti", "kamute", "tamus", "tamis", "tammus",
    "balinghoy", "balinghoi", "balingoy", "balinhoy",
    "bumbay", "bombay", "bumbai", "bombai",
    "ahos", "ahus", "ajos", "aho", "ahoss", "ajus",
    "parya", "paria", "pariya", "paryah", "paria2",
    "libato", "libatu", "dundula", "dundola",
    "batong", "batoong", "batung", "battong", "batongan", "batungg",
    "hantak", "hantag",
    "lada", "ladda",
    "lemonsito", "lemonsitu", "lemoncito",
    "limon", "limun",
    "kamunggay", "kamunggai", "kamungay", "kamunggey",
    "kamunggoy", "kamungai", "kamungey",
    "salai", "salay", "sallai",
    "kasaba", "kasabba",
    "lasona", "lasuna",
    "kapaya", "tapaya", "kapaiya", "tapaiya",
    "labanu", "labanus",
    "kalawag", "kalawog", "kunig", "kuning",
    "gatas gatas", "gatas-gatas", "gatasgatas",
    "dangla", "danggla",
    "solasi", "solasin",
    "pangdan", "pandang",
    "ubi", "ubii",
    "pitsay",
    "ukra",
    "loya", "luia", "loy a",
    "kuchai", "kuchai2",
    "kutchay", "kutchay2", "kutchey",
    "hierba buena",
    "libato", "libatu",
    "sengkamas",
    "sitau", "sitao",
}


def detect_language(raw_input: str) -> str:
    """
    Returns 'english', 'bisaya', or 'tagalog'.
    Tagalog is the default fallback.
    """
    cleaned = raw_input.strip().lower()

    if cleaned in ENGLISH_CROP_WORDS:
        return "english"

    if cleaned in BISAYA_CROP_WORDS:
        return "bisaya"

    # Heuristic: if multiple words and contains English pattern
    words = cleaned.split()
    english_count = sum(1 for w in words if w in ENGLISH_CROP_WORDS)
    if english_count >= len(words) / 2 and len(words) > 1:
        return "english"

    return "tagalog"


def get_display_name(matched_key: str, raw_input: str, lang: str) -> str:
    """
    Returns the display name in the correct language per spec:
    - english input  → ENGLISH_DISPLAY  → CANONICAL_DISPLAY → key
    - bisaya input   → BISAYA_DISPLAY   → CANONICAL_DISPLAY → ENGLISH_DISPLAY
    - tagalog input  → CANONICAL_DISPLAY → ENGLISH_DISPLAY
    - default (None) → CANONICAL_DISPLAY
    """
    if lang == "english":
        return (
            ENGLISH_DISPLAY.get(matched_key)
            or CANONICAL_DISPLAY.get(matched_key)
            or matched_key.replace("_", " ").title()
        )

    if lang == "bisaya":
        return (
            BISAYA_DISPLAY.get(matched_key)
            or CANONICAL_DISPLAY.get(matched_key)
            or ENGLISH_DISPLAY.get(matched_key)
            or matched_key.replace("_", " ").title()
        )

    # tagalog (default)
    return (
        CANONICAL_DISPLAY.get(matched_key)
        or ENGLISH_DISPLAY.get(matched_key)
        or matched_key.replace("_", " ").title()
    )


# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

def normalize_crop_name(raw_name: str):
    """
    Returns (matched_key, display_name) or (None, None).

    Step 1 — direct key match (free, instant)
    Step 2 — alias dict (free, instant, covers 95%+ of inputs)
    Step 3 — Groq AI fallback (language-aware, only for unknown inputs)
    """
    cleaned = raw_name.strip().lower()

    # Step 1 — direct key match
    if cleaned in crop_requirements:
        lang = detect_language(cleaned)
        display = get_display_name(cleaned, raw_name.strip(), lang)
        return cleaned, display

    # Step 2 — alias dict
    if cleaned in CROP_ALIASES:
        matched_key = CROP_ALIASES[cleaned]
        lang = detect_language(cleaned)
        display = get_display_name(matched_key, raw_name.strip(), lang)
        return matched_key, display

    # Step 3 — AI fallback
    crop_list_str = ', '.join(crop_requirements.keys())
    try:
        response = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are a crop name matcher for Filipino farmers in Mindanao and Visayas.\n"
                        "Reply in EXACTLY this format with no other text: key|display|lang\n\n"
                        "- key: exact key from the crop list, nothing else\n"
                        "- display: corrected name in the SAME LANGUAGE the farmer typed\n"
                        "  * Bisaya typed → corrected Bisaya name\n"
                        "  * Tagalog typed → corrected Tagalog name\n"
                        "  * English typed → corrected English name\n"
                        "  * Bisaya with no translation → fallback to Tagalog\n"
                        "  * Tagalog with no translation → fallback to English\n"
                        "  * NEVER return empty display\n"
                        "- lang: one of: bisaya, tagalog, english\n"
                        "- No match: none|none|none\n\n"
                        "No explanation. No punctuation. Only key|display|lang."
                    )
                },
                {
                    "role": "user",
                    "content": (
                        f"Farmer typed: '{raw_name}'\n\n"
                        f"Crop list: {crop_list_str}\n\n"
                        f"Phonetic rules:\n"
                        f"1. Bisaya: a↔e↔i, o↔u freely interchange; k↔g, p↔b, t↔d swap\n"
                        f"2. Doubled or missing letters are common: taloong=talong\n"
                        f"3. Spaces in the middle: 'luy a' = 'luya'\n"
                        f"4. Say it aloud — if it sounds like a crop name, match it\n"
                        f"5. English phonetic misspellings are valid: 'muringa' = moringa\n\n"
                        f"Reply only: key|display|lang"
                    )
                }
            ],
            max_tokens=30,
            temperature=0,
        )

        raw_result = response.choices[0].message.content.strip()
        print(f"[CROP AI] input='{raw_name}' → raw='{raw_result}'")

        cleaned_result = (
            raw_result.lower().strip()
            .strip('"').strip("'").strip('`').strip('.')
        )

        if '|' not in cleaned_result:
            return None, None

        parts = cleaned_result.split('|')
        if len(parts) >= 3:
            matched_key = parts[0].strip().strip('"').strip("'")
            display     = parts[1].strip().strip('"').strip("'")
            lang        = parts[2].strip()

            print(f"[CROP AI] key='{matched_key}' display='{display}' lang='{lang}'")

            if matched_key in crop_requirements:
                if not display or display == "none":
                    display = get_display_name(matched_key, raw_name.strip(), lang)
                return matched_key, display.capitalize()

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


# ══════════════════════════════════════════════════════════════════════════════
# ROUTES
# ══════════════════════════════════════════════════════════════════════════════

@app.route('/')
def index():
    return jsonify({"message": "Soiltech API is running"})


@app.route('/crops', methods=['GET'])
def get_crops():
    return jsonify({'crops': list(crop_requirements.keys())})


@app.route('/crops-display', methods=['GET'])
def get_crops_display():
    """
    Returns crops with English display names for the default Flutter UI grid.
    If no English equivalent, uses the most recognized name.
    """
    result = []
    for key in crop_requirements.keys():
        result.append({
            'key':     key,
            'display': ENGLISH_DISPLAY.get(key, key.replace('_', ' ').title())
        })
    return jsonify({'crops': result})


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


# ── Blueprint ───────────────────────────────────────────────────
from chat_route import chat_bp
app.register_blueprint(chat_bp)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)