# Adhesion AI – AI-Powered Post-Surgery Adhesion Detection

## Overview
Adhesion complications after surgery are a significant medical challenge. Early detection is often difficult, leading to delayed treatment and increased healthcare costs.  

**Adhesion AI** is an AI-powered system designed to detect adhesions using medical images and real-time videos, providing accurate and fast analysis accessible via a mobile app and web platform.

---

## Features
- Real-time AI-based adhesion detection
- Supports both image and video analysis
- Color-coded results (Red = Present, Green = Not Present)
- Accuracy score & graph visualization
- Google Sign-In (Firebase) for secure authentication
- Cloud storage of patient history
- Professional doctor-friendly UI
- Web app with APK download

---

## Demo

**Mobile App:**
- Upload/scan medical image or real-time video
- Instant adhesion analysis
- Save & share reports with doctors

**Web App:**
- Health-tech themed landing page
- APK download option

**Live Demo:** [https://adhesion-ai.netlify.app/](https://adhesion-ai.netlify.app/)

---

## Tech Stack
- **Frontend:** Flutter / Android (Tailwind-inspired UI)
- **Backend:** Firebase (Authentication, Firestore, Storage)
- **AI/ML:** TensorFlow / PyTorch (Trained adhesion detection model)
- **Deployment:** Firebase Hosting (Web app)
- **Authentication:** Google Sign-in (OAuth2 + Firebase)

---

## Architecture
1. User uploads image/video via mobile app  
2. Data is sent to the server with AI model  
3. Model analyzes and returns:  
   - Adhesion status (Red/Green)  
   - Accuracy percentage  
   - Graph visualization  
4. Results are stored in Firebase for patient history  
5. Doctors can review saved reports  
6. Web app provides project info and APK download  

---

## Impact & Use Cases
- Speeds up adhesion detection for doctors  
- Reduces diagnosis time & medical errors  
- Accessible AI healthcare for everyone  

**Use Cases:**  
- Post-surgery adhesion monitoring  
- Hospital & clinic scalable diagnostics  
- Remote healthcare applications  

**Future Scope:**  
- Extend to detect other medical imaging conditions (tumors, fractures)  
- Integration with hospital management systems  
- Build a full SaaS product for healthcare AI  

---

## Installation
1. Clone the repository:  
   ```bash
   git clone https://github.com/your-username/adhesion-ai.git
2.Open the mobile app folder in Flutter/Android Studio

3.Configure Firebase credentials in the app

4.Run the app on an emulator or physical device

4.Access the web app via Firebase Hosting URL

Contributing

We welcome contributions! Please fork the repository, create a new branch, and submit a pull request.![WhatsApp Image 2025-09-28 at 07 06 07_18680848](https://github.com/user-attachments/assets/00a28e53-eba7-48c7-b604-54bd23472d12)









