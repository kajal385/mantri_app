const { createUserWithEmailAndPassword, signInWithEmailAndPassword } = require('firebase/auth');
const { auth, db, admin } = require('../config/firebase');

exports.signup = async (req, res) => {
    const { email, password, name } = req.body;
    try {
        const userCredential = await createUserWithEmailAndPassword(auth, email, password);
        const user = userCredential.user;

        // Automatically store in database if Admin SDK is configured
        if (db) {
            await db.collection('users').doc(user.uid).set({
                name: name || '',
                email: email,
                role: 'user', // default role
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }

        res.status(201).json({
            message: 'User created successfully',
            uid: user.uid,
            email: user.email
        });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

exports.login = async (req, res) => {
    const { email, password } = req.body;
    try {
        const userCredential = await signInWithEmailAndPassword(auth, email, password);
        const user = userCredential.user;
        const token = await user.getIdToken();
        
        res.status(200).json({
            message: 'Login successful',
            token: token,
            uid: user.uid,
            email: user.email
        });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};
