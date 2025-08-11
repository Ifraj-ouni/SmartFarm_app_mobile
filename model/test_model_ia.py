import sys
import os
import tensorflow as tf
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
import numpy as np

sys.path.append(r"D:/model")

class_names = [
    "Mildiou", "oidium", "alternariose", "sunburn",
    "helicoverpa", "fruit_saine", "feuil_saine", "excesnit",
    "blossom_end_rot", "tuta", "bacterial", "mited",
    "virosis", "black mold"
]

def preprocess_image(img_path, target_size=(224, 224)):
    img = image.load_img(img_path, target_size=target_size)
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    img_array /= 255.0
    return img_array

def load_model_smart(model_path):
    """Charge un modèle .h5 ou SavedModel (si compatible Keras 3)"""
    if os.path.isfile(model_path) and model_path.endswith('.h5'):
        return load_model(model_path, compile=False)
    elif os.path.isdir(model_path) and os.path.exists(os.path.join(model_path, "saved_model.pb")):
        raise ValueError("⚠️ Ce modèle est au format SavedModel non supporté par `load_model()` dans Keras 3.")
    else:
        raise ValueError(f"❌ Format de modèle non supporté ou fichier absent : {model_path}")

def test_model_prediction(model_path, img_path):
    model = load_model_smart(model_path)
    img_prepared = preprocess_image(img_path)
    preds = model.predict(img_prepared)
    predicted_index = np.argmax(preds)
    model_name = os.path.basename(os.path.dirname(model_path)) if os.path.isfile(model_path) else os.path.basename(model_path)
    print(f"[Modèle: {model_name}] Image: {os.path.basename(img_path)} -> Classe prédite : {class_names[predicted_index]} ({preds[0][predicted_index]*100:.2f}%)")

if __name__ == "__main__":
    models_paths = [
        "D:/model/models/mildiw/mildiw.h5",
        "D:/model/models/late blight",  # erreur format possible
        "D:/model/models/mited/tomato-disease-detection-model.h5",
        "D:/model/models/sunburn",
        "D:/model/models/alternaria mite/alternaeia.h5",
        "D:/model/models/bacterial floudering/bacterial floudering.h5",
        "D:/model/models/bloss end rot/blossom end rot.h5",
        "D:/model/models/exces nitrogen/exces nitrogen.h5",
        "D:/model/models/helicoverpa",
    ]

    images_to_test = [
        #"D:/model/images/feuille_test.jpg",
        "D:/model/images/mildiou-img.jpg",
    ]

    for model_path in models_paths:
        if not os.path.exists(model_path):
            print(f"❌ Chemin non trouvé : {model_path}")
            continue
        for img_path in images_to_test:
            if not os.path.exists(img_path):
                print(f"❌ Image non trouvée : {img_path}")
                continue
            try:
                test_model_prediction(model_path, img_path)
            except Exception as e:
                print(f"❌ Erreur avec [{model_path}] sur image [{img_path}]\n    ➜ {e}")
