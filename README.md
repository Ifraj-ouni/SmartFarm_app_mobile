# 🌱 SmartFarm – Smart Agriculture Mobile Application with AI & Admin Dashboard

SmartFarm is a **mobile and web application platform** designed to support **smart agriculture**.  
It helps farmers **monitor crops, detect plant diseases, get advice, track history, and manage farms**, all in one system.

The system integrates:  
- **Mobile application** (Flutter)  
- **AI model** for plant disease detection from leaf images  
- **Admin dashboard** for managing users, crops, and diseases  
- **Chatbot** for user support and guidance  

---

## 📌 Project Overview

SmartFarm provides farmers with a **digital toolkit** to improve farm management, increase crop health awareness, and reduce losses due to plant diseases.  

Key functionalities include:

- **Mobile App**: Capture leaf images to detect disease, view advice, and manage crops and fields.  
- **AI Model**: Classify plant diseases from leaf images and provide recommendations.  
- **History Tracking**: Record detected diseases and associate them with specific crops or fields.  
- **Admin Dashboard**: Manage users, crops, diseases, and view system analytics.  
- **Chatbot**: Help users with advice, recommendations, and general queries.

---

## 🎯 Objectives

- Support **smart agriculture practices**  
- Detect **plant diseases** using AI  
- Provide **recommendations and advice** to farmers  
- Track disease detection **history** per crop or field  
- Enable **administrative control** via dashboard  
- Offer **real-time chatbot assistance** for users  

---

## ✨ Key Features

### 📱 Mobile Application
- Manage **fields and crops**  
- Capture or upload **leaf images** to detect diseases  
- Receive **advice and guidance** on plant health  
- View **history of detected diseases**  
- Consult historical records for crops or fields  

### 🧠 AI-Based Disease Detection
- Deep learning model detects plant diseases from leaf images  
- Returns **disease name and confidence score**  
- Integrates recommendations based on detected disease  

### 🏢 Admin Dashboard
- **Manage users** (create, edit, delete)  
- **Manage diseases** and their descriptions  
- Monitor crop and field data  
- Visual analytics and statistics  

### 💬 Chatbot
- Provides **advice** to farmers  
- Answers questions about crops, diseases, and farm management  
- Guides users on how to use the app  

---

## 🛠️ Technologies Used

### Mobile Application
- Flutter  
- Dart  
- Material Design  

### AI Model
- Python  
- TensorFlow / Keras  
- OpenCV, NumPy, Pandas  

### Backend & Dashboard
- Node.js + Express.js  
- MySQL / PostgreSQL  
- Admin dashboard: Angular / React  

### Chatbot
- LangChain / OpenAI API (or custom NLP)  

---

## 🧠 AI Model – Plant Disease Detection

The AI model analyzes leaf images and classifies them into:  
- Healthy leaf  
- Diseased leaf (with specific disease type)  

### Workflow
1. **Image Input** – Capture or upload a leaf image  
2. **Preprocessing** – Resize, normalize, convert format  
3. **Feature Extraction** – Deep learning extracts visual features  
4. **Classification** – Predict disease class  
5. **Output** – Display disease name, confidence score, and advice  

Example output:
Prediction: Tomato Early Blight
Confidence: 93%
Advice: Remove affected leaves and apply recommended fungicide.


💻 Usage

Open the mobile app, register, and create your fields.

Capture a leaf image → AI detects disease → advice displayed → history saved.

Admins log into the dashboard to manage users, crops, and diseases.

Use chatbot for tips and guidance on crops and disease prevention.



