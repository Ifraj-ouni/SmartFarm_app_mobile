import os
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.models import Model, load_model
from tensorflow.keras.layers import Dense, Dropout, GlobalAveragePooling2D, Input
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
from tensorflow.keras.applications import MobileNetV2

# === CONFIGURATION ===
DATA_DIR = 'D:/Plant_leave_diseases_dataset_without_augmentation'
MODEL_SAVE_PATH = 'D:/model/models/plant_disease_model_mobilenet.h5'  # Changé en .h5 pour meilleure compatibilité
CLASS_NAMES_PATH = 'D:/model/class_names.py'
IMG_HEIGHT, IMG_WIDTH = 224, 224
BATCH_SIZE = 32

# === VÉRIFICATIONS INITIALES ===
assert os.path.exists(DATA_DIR), f"Le dossier de données {DATA_DIR} n'existe pas"
os.makedirs(os.path.dirname(MODEL_SAVE_PATH), exist_ok=True)
os.makedirs(os.path.dirname(CLASS_NAMES_PATH), exist_ok=True)

# === 1. Prétraitement et Data Augmentation ===
try:
    datagen = ImageDataGenerator(
        rescale=1./255,
        validation_split=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        rotation_range=20,
        width_shift_range=0.1,
        height_shift_range=0.1,
        horizontal_flip=True
    )

    train_generator = datagen.flow_from_directory(
        DATA_DIR,
        target_size=(IMG_HEIGHT, IMG_WIDTH),
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='training',
        shuffle=True
    )

    val_generator = datagen.flow_from_directory(
        DATA_DIR,
        target_size=(IMG_HEIGHT, IMG_WIDTH),
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='validation',
        shuffle=False
    )
except Exception as e:
    raise RuntimeError(f"Erreur lors du chargement des données: {str(e)}")

# === 2. Sauvegarde des noms de classes ===
try:
    index_to_class = {v: k for k, v in train_generator.class_indices.items()}
    class_names = [index_to_class[i] for i in range(len(index_to_class))]
    print("✅ Classes détectées :", class_names)

    with open(CLASS_NAMES_PATH, 'w') as f:
        f.write(f"class_names = {class_names}\n")
except Exception as e:
    print(f"⚠️ Erreur lors de la sauvegarde des classes: {str(e)}")

# === 3. Construction du modèle avec vérification explicite ===
def build_model(num_classes):
    try:
        # Charger MobileNetV2 pré-entraîné
        base_model = MobileNetV2(
            input_shape=(IMG_HEIGHT, IMG_WIDTH, 3),
            include_top=False,
            weights='imagenet'
        )
        base_model._name = 'mobilenetv2_base'  # Nommage explicite
        
        # Geler les couches de base
        base_model.trainable = False
        
        # Construction du modèle
        inputs = Input(shape=(IMG_HEIGHT, IMG_WIDTH, 3))
        x = base_model(inputs)
        x = GlobalAveragePooling2D()(x)
        x = Dense(256, activation='relu')(x)
        x = Dropout(0.5)(x)
        outputs = Dense(num_classes, activation='softmax')(x)
        
        model = Model(inputs, outputs, name='disease_classifier')
        
        return model, base_model
    except Exception as e:
        raise RuntimeError(f"Erreur lors de la construction du modèle: {str(e)}")

try:
    model, mobilenet_base = build_model(train_generator.num_classes)
    model.compile(optimizer='adam', 
                 loss='categorical_crossentropy', 
                 metrics=['accuracy'])
except Exception as e:
    raise RuntimeError(f"Erreur lors de la compilation du modèle: {str(e)}")

# === 4. Callbacks ===
callbacks = [
    EarlyStopping(patience=8, monitor='val_accuracy', restore_best_weights=True, verbose=1),
    ModelCheckpoint(
        filepath=MODEL_SAVE_PATH,
        monitor='val_accuracy',
        save_best_only=True,
        save_weights_only=False,
        mode='max',
        verbose=1
    ),
    ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=4, min_lr=1e-6, verbose=1)
]

# === 5. Entraînement initial ===
print("\n🔁 Étape 1 : Entraînement des couches supérieures")
try:
    history = model.fit(
        train_generator,
        validation_data=val_generator,
        epochs=10,
        callbacks=callbacks,
        verbose=1
    )
except Exception as e:
    raise RuntimeError(f"Erreur lors de l'entraînement initial: {str(e)}")

# === 6. Fine-tuning avec vérification renforcée ===
print("\n🔥 Étape 2 : Fine-tuning des couches profondes")
try:
    # Vérification explicite du fichier modèle
    if not os.path.exists(MODEL_SAVE_PATH):
        raise FileNotFoundError(f"Fichier modèle introuvable: {MODEL_SAVE_PATH}")
    
    # Chargement avec vérification
    model = load_model(MODEL_SAVE_PATH)
    print("✅ Modèle chargé avec succès")
    
    # Vérification de la présence de MobileNetV2
    mobilenet_layer = None
    for layer in model.layers:
        if isinstance(layer, Model) and 'mobilenetv2' in layer.name.lower():
            mobilenet_layer = layer
            break
    
    if mobilenet_layer is None:
        raise ValueError("Couche MobileNetV2 introuvable dans le modèle chargé")
    
    # Configuration du fine-tuning
    mobilenet_layer.trainable = True
    for layer in mobilenet_layer.layers[:-30]:
        layer.trainable = False
    
    # Vérification du nombre de couches entraînables
    trainable_count = sum([1 for layer in mobilenet_layer.layers if layer.trainable])
    print(f"🔢 Couches MobileNetV2 entraînables: {trainable_count}/{len(mobilenet_layer.layers)}")
    
    # Recompilation
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    # Entraînement
    history_fine = model.fit(
        train_generator,
        validation_data=val_generator,
        epochs=20,
        callbacks=callbacks,
        verbose=1
    )
    
    # Sauvegarde finale
    model.save(MODEL_SAVE_PATH)
    print(f"\n✅ Modèle final sauvegardé avec succès à: {MODEL_SAVE_PATH}")
    print(f"Taille du fichier: {os.path.getsize(MODEL_SAVE_PATH)/1024/1024:.2f} MB")

except Exception as e:
    print(f"\n❌ ERREUR CRITIQUE lors du fine-tuning: {str(e)}")
    print("Conseils de dépannage:")
    print("1. Vérifiez que le modèle a bien été sauvegardé à l'étape 1")
    print("2. Vérifiez les permissions d'écriture")
    print("3. Essayez de réduire la taille du batch si vous manquez de mémoire")
    print("4. Inspectez model.summary() pour vérifier l'architecture")