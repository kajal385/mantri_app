const { db } = require('../config/firebase');

exports.getAllUsers = async (req, res) => {
    try {
        if (!db) return res.status(500).json({ error: "Database not initialized" });
        const snapshot = await db.collection('users').get();
        const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        res.status(200).json(users);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

exports.getUserProfile = async (req, res) => {
    try {
        if (!db) return res.status(500).json({ error: "Database not initialized" });
        const { id } = req.params;
        const doc = await db.collection('users').doc(id).get();
        if (!doc.exists) return res.status(404).json({ error: "User not found" });
        res.status(200).json({ id: doc.id, ...doc.data() });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

exports.updateUserProfile = async (req, res) => {
    try {
        if (!db) return res.status(500).json({ error: "Database not initialized" });
        const { id } = req.params;
        await db.collection('users').doc(id).update(req.body);
        res.status(200).json({ message: "Profile updated successfully" });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

exports.deleteUser = async (req, res) => {
    try {
        if (!db) return res.status(500).json({ error: "Database not initialized" });
        const { id } = req.params;
        await db.collection('users').doc(id).delete();
        // Option: Also use admin.auth().deleteUser(id) if deleting from Authentication
        res.status(200).json({ message: "User deleted successfully" });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};
