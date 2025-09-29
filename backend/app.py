"""
AdhesioSense Flask Backend Server
AI-Assisted Adhesion Detection API

This server provides a REST API endpoint for processing medical images
and predicting adhesion presence using AI models.
"""

import os
import io
import numpy as np
from PIL import Image
from flask import Flask, request, jsonify
from flask_cors import CORS

# Initialize Flask application
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Configuration
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'bmp'}
MODEL_PATH = 'model/adhesion_detector_model.h5'  # Replace with actual model path

# Create upload directory
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def preprocess_image(image):
    """
    Preprocess image for AI model input
    - Resize to 224x224 pixels
    - Convert to RGB
    - Normalize pixel values
    - Expand dimensions for batch processing
    """
    try:
        # Resize and convert to RGB
        image = image.resize((224, 224))
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Convert to numpy array and normalize
        img_array = np.array(image) / 255.0
        
        # Expand dimensions for batch processing
        img_array = np.expand_dims(img_array, axis=0)
        
        return img_array
    except Exception as e:
        raise Exception(f"Image preprocessing failed: {str(e)}")

def predict_adhesion(image_array):
    """
    Predict adhesion presence using AI model
    This is a placeholder function - replace with actual model loading and prediction
    
    Returns:
        tuple: (prediction_label, confidence_score, graph_data)
    """
    try:
        # TODO: Replace with actual model loading and prediction
        # Example: model = load_model(MODEL_PATH)
        # prediction = model.predict(image_array)
        
        # Mock prediction for demonstration
        # In real implementation, this would come from your trained model
        confidence = np.random.uniform(0.0, 1.0)
        
        if confidence > 0.5:
            prediction_label = "Yes"
            adhesion_prob = confidence
            no_adhesion_prob = 1 - confidence
        else:
            prediction_label = "No"
            no_adhesion_prob = 1 - confidence
            adhesion_prob = confidence
        
        # Ensure probabilities sum to 1
        total = adhesion_prob + no_adhesion_prob
        adhesion_prob /= total
        no_adhesion_prob /= total
        
        graph_data = [no_adhesion_prob, adhesion_prob]
        
        return prediction_label, adhesion_prob, graph_data
        
    except Exception as e:
        raise Exception(f"Prediction failed: {str(e)}")

@app.route('/predict', methods=['POST'])
def predict():
    """
    Main prediction endpoint
    Accepts image file via POST request and returns adhesion prediction
    """
    try:
        # Check if file was uploaded
        if 'image' not in request.files:
            return jsonify({
                'error': 'No image file provided',
                'prediction': 'Error',
                'probability': 0.0,
                'graph_data': [0.0, 0.0]
            }), 400
        
        file = request.files['image']
        
        # Check if file is selected
        if file.filename == '':
            return jsonify({
                'error': 'No file selected',
                'prediction': 'Error',
                'probability': 0.0,
                'graph_data': [0.0, 0.0]
            }), 400
        
        # Check file type
        if not allowed_file(file.filename):
            return jsonify({
                'error': 'Invalid file type. Allowed types: PNG, JPG, JPEG, BMP',
                'prediction': 'Error',
                'probability': 0.0,
                'graph_data': [0.0, 0.0]
            }), 400
        
        # Read and process image
        image_bytes = file.read()
        image = Image.open(io.BytesIO(image_bytes))
        
        # Preprocess image for model
        processed_image = preprocess_image(image)
        
        # Make prediction
        prediction, probability, graph_data = predict_adhesion(processed_image)
        
        # Return prediction results
        return jsonify({
            'prediction': prediction,
            'probability': float(probability),
            'graph_data': [float(x) for x in graph_data],
            'message': 'Prediction successful'
        }), 200
        
    except Exception as e:
        return jsonify({
            'error': f'Internal server error: {str(e)}',
            'prediction': 'Error',
            'probability': 0.0,
            'graph_data': [0.0, 0.0]
        }), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'message': 'AdhesioSense AI Server is running',
        'version': '1.0.0'
    }), 200

@app.route('/')
def index():
    """Root endpoint with API information"""
    return jsonify({
        'name': 'AdhesioSense AI Server',
        'version': '1.0.0',
        'endpoints': {
            '/predict': 'POST - Process image for adhesion detection',
            '/health': 'GET - Server health check',
            '/': 'GET - API information'
        },
        'documentation': 'See README.md for API usage instructions'
    })

if __name__ == '__main__':
    print("Starting AdhesioSense AI Server...")
    print("Server running on http://localhost:5000")
    print("Available endpoints:")
    print("  GET  /health - Health check")
    print("  POST /predict - Adhesion prediction")
    print("  GET  / - API information")
    
    # Run Flask development server
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True,
        threaded=True
    )