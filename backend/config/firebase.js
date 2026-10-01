const { initializeApp } = require('firebase/app');
const { getAuth } = require('firebase/auth');
const admin = require('firebase-admin');

const firebaseConfig = {
  apiKey: "AIzaSyDyu2rClid9Jl277JZin7OFJf2MOw9nXw0",
  authDomain: "mpapp-22134.firebaseapp.com",
  projectId: "mpapp-22134",
  storageBucket: "mpapp-22134.firebasestorage.app",
  messagingSenderId: "273578508477",
  appId: "1:273578508477:web:f7f949b18414cf85a2f7d4"
};

const firebaseApp = initializeApp(firebaseConfig);
const auth = getAuth(firebaseApp);

// Initialize Admin SDK with default credentials if available or require file
try {
  const serviceAccount = require('../serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log("Firebase Admin initialized successfully.");
} catch (error) {
  console.warn("Firebase Admin SDK not initialized: serviceAccountKey.json is missing or invalid.");
}

const db = admin.apps.length ? admin.firestore() : null;

module.exports = { auth, admin, db, firebaseApp };
