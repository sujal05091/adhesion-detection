# AdhesioSense Backend Server

Python Flask backend for AI-assisted adhesion detection in medical images.

## Features

- RESTful API for image processing and adhesion prediction
- Image preprocessing (resize to 224x224, RGB conversion, normalization)
- Mock AI prediction system (replace with actual trained model)
- CORS support for cross-origin requests from Flutter app
- Error handling and validation

## Setup Instructions

### Prerequisites

- Python 3.8 or higher
- pip (Python package manager)

### Installation

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Create virtual environment (recommended):**
   ```bash
   python -m venv venv
   ```

3. **Activate virtual environment:**
   - Windows:
     ```bash
     venv\Scripts\activate
     ```
   - macOS/Linux:
     ```bash
     source venv/bin/activate
     ```

4. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

### Running the Server

1. **Start the development server:**
   ```bash
   python app.py
   ```

2. **Server will be available at:**
   - Local: http://localhost:5000
   - Network: http://0.0.0.0:5000

3. **Test the server:**
   ```bash
   curl http://localhost:5000/health
   ```

## API Endpoints

### POST /predict
Process an image for adhesion detection.

**Request:**
- Method: POST
- Content-Type: multipart/form-data
- Body: image file (form field name: 'image')

**Response:**
```json
{
  "prediction": "Yes" | "No",
  "probability": 0.87,
  "graph_data": [0.13, 0.87],
  "message": "Prediction successful"
}
```

**Example using curl:**
```bash
curl -X POST -F "image=@path/to/your/image.jpg" http://localhost:5000/predict
```

### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "message": "AdhesioSense AI Server is running",
  "version": "1.0.0"
}
```

### GET /
API information endpoint.

## Integrating Real AI Model

### Step 1: Prepare Your Trained Model

1. Train your adhesion detection model using TensorFlow/Keras
2. Save the model in appropriate format:
   - `.h5` for Keras models
   - `.pb` for TensorFlow SavedModel
   - `.tflite` for TensorFlow Lite

### Step 2: Update Model Loading

In `app.py`, replace the `predict_adhesion()` function with actual model loading:

```python
import tensorflow as tf
from tensorflow import keras

def load_model():
    """Load your trained AI model"""
    try:
        # Example for Keras .h5 model
        model = keras.models.load_model('models/your_model.h5')
        return model
    except Exception as e:
        print(f"Model loading failed: {e}")
        return None

# Global model variable
model = load_model()

def predict_adhesion(image_array):
    """Make prediction using actual model"""
    if model is None:
        raise Exception("Model not loaded")
    
    # Make prediction
    prediction = model.predict(image_array)
    
    # Process prediction results
    adhesion_prob = prediction[0][0]  # Adjust based on your model output
    no_adhesion_prob = 1 - adhesion_prob
    
    if adhesion_prob > 0.5:
        prediction_label = "Yes"
    else:
        prediction_label = "No"
    
    graph_data = [no_adhesion_prob, adhesion_prob]
    
    return prediction_label, adhesion_prob, graph_data
```

### Step 3: Install ML Dependencies

Uncomment the ML dependencies in `requirements.txt`:
```
tensorflow==2.13.0
keras==2.13.1
opencv-python==4.8.1.78
scikit-learn==1.3.0
```

Then install:
```bash
pip install -r requirements.txt
```

### Step 4: Model Directory Structure

Create a `models/` directory and place your trained model files:
```
backend/
├── models/
│   ├── your_model.h5
│   └── classes.json  # Optional: class labels
├── app.py
├── requirements.txt
└── README.md
```

## Model Training Considerations

### Input Requirements
- Image size: 224x224 pixels
- Color format: RGB
- Normalization: Pixel values scaled to [0, 1]

### Dataset Preparation
Your training dataset should include:
1. Images with adhesion (positive class)
2. Images without adhesion (negative class)
3. Images with similar conditions but no adhesion (to reduce false positives)

### Avoiding False Positives
To help the model distinguish adhesions from other marks:
- Include images with burn marks, white spots, rashes, infections
- Consider adding normal skin baseline comparisons
- Use data augmentation techniques

## Deployment

### Production Deployment
For production use:

1. **Use production WSGI server:**
   ```bash
   pip install gunicorn
   gunicorn -w 4 -b 0.0.0.0:5000 app:app
   ```

2. **Environment variables:**
   Create `.env` file:
   ```
   FLASK_ENV=production
   MODEL_PATH=models/production_model.h5
   ```

3. **Docker support (optional):**
   Create `Dockerfile` for containerized deployment

### Security Considerations

- Enable HTTPS for production
- Implement authentication if needed
- Validate and sanitize all inputs
- Rate limiting for API endpoints
- Regular security updates

## Troubleshooting

### Common Issues

1. **Import errors:** Ensure all dependencies are installed
2. **Model loading issues:** Check model file path and format
3. **CORS errors:** Verify Flask-CORS is installed and configured
4. **Image processing errors:** Check Pillow installation

### Getting Help

Check the Flask documentation for detailed API reference:
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Flask-CORS Documentation](https://flask-cors.readthedocs.io/)

## License

This project is part of the AdhesioSense medical application suite.

---

*For medical use: Ensure your AI model is properly validated and meets regulatory requirements before clinical use.*