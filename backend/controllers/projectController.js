const { db, admin } = require('../config/firebase');
const collectionName = 'projects';

exports.createProject = async (req, res) => {
    try {
        if (!db) return res.status(500).json({ error: "Database not initialized" });
        const data = req.body;
        const ref = db.collection(collectionName).doc();
        await ref.set({
            ...data,
            id: ref.id,
            status: data.status || 'Ongoing',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        res.status(201).json({ message: "Created successfully", id: ref.id });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

exports.getProjects = async (req, res) => {
    try {
        if (!db) return res.status(500).json({ error: "Database not initialized" });
        const snapshot = await db.collection(collectionName).get();
        const results = snapshot.docs.map(doc => doc.data());
        res.status(200).json(results);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

exports.getProjectById = async (req, res) => {
    try {
        if (!db) return res.status(500).json({ error: "Database not initialized" });
        const { id } = req.params;
        const doc = await db.collection(collectionName).doc(id).get();
        if (!doc.exists) return res.status(404).json({ error: "Not found" });
        res.status(200).json(doc.data());
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

exports.updateProject = async (req, res) => {
    try {
        if (!db) return res.status(500).json({ error: "Database not initialized" });
        const { id } = req.params;
        await db.collection(collectionName).doc(id).update(req.body);
        res.status(200).json({ message: "Updated successfully" });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

exports.deleteProject = async (req, res) => {
    try {
        if (!db) return res.status(500).json({ error: "Database not initialized" });
        const { id } = req.params;
        await db.collection(collectionName).doc(id).delete();
        res.status(200).json({ message: "Deleted successfully" });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};
