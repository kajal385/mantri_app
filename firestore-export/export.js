const admin = require("firebase-admin");
const fs = require("fs");

// Firebase Service Account
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function exportFirestore() {
  const collections = await db.listCollections();

  console.log(`Found ${collections.length} collections...\n`);

  for (const collection of collections) {
    const snapshot = await collection.get();

    const data = [];

    snapshot.forEach((doc) => {
      data.push({
        id: doc.id,
        ...doc.data(),
      });
    });

    fs.writeFileSync(
      `${collection.id}.json`,
      JSON.stringify(data, null, 2)
    );

    console.log(`✅ Exported ${collection.id}.json`);
  }

  console.log("\n🎉 All collections exported successfully!");
}

exportFirestore().catch(console.error);