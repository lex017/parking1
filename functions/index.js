const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

// Helper: ส่ง notification ไปยัง token
async function sendFCM(token, title, body, data = {}) {
    const message = {
        notification: { title, body },
        data,
        token,
    };

    try {
        await admin.messaging().send(message);
        console.log("✅ Notification sent to:", token);
    } catch (error) {
        console.error("❌ Error sending notification:", error);
    }
}

// รันทุก ๆ 1 นาที
exports.checkTicketTimes = functions.pubsub.schedule("every 1 minutes").onRun(async (context) => {
    const now = new Date();
    const ticketsRef = db.collection("bookings");
    const snapshot = await ticketsRef.where("Status", "==", "pending").get();

    for (const doc of snapshot.docs) {
        try {
            const data = doc.data();
            const timestamp = data.timestamp;

            if (!timestamp) continue;

            const ticketTime = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
            const expiryTime = new Date(ticketTime.getTime() + 60 * 60000); // 60 นาที
            const remainingMs = expiryTime.getTime() - now.getTime();
            const remainingMinutes = Math.floor(remainingMs / 60000);

            const ticketId = doc.id;
            const userId = data.userId;
            if (!userId) continue;

            const userDoc = await db.collection("users").doc(userId).get();
            const token = userDoc.exists ? userDoc.data().fcmToken : null;
            if (!token) continue;

            // เตรียม reminder flags
            const reminders = data.reminders || {};

            // แจ้งเตือนล่วงหน้า
            const reminderTimes = [15, 10, 5];
            for (const minute of reminderTimes) {
                if (remainingMinutes === minute && !reminders[`min${minute}`]) {
                    await sendFCM(
                        token,
                        `⏰ เหลือเวลาอีก ${minute} นาที`,
                        `คุณมีเวลาเหลือ ${minute} นาทีในการเช็คอิน`,
                        { action: "reminder", ticketId }
                    );
                    reminders[`min${minute}`] = true;
                }
            }

            // แจ้งเตือนหมดเวลา
            if (remainingMinutes <= 0 && data.Status !== "Time-out") {
                await sendFCM(
                    token,
                    "⛔ ตั๋วหมดเวลา",
                    "คุณไม่ได้เช็คอินภายใน 1 ชั่วโมง ระบบจะทำการเช็คเอาท์โดยอัตโนมัติ",
                    { action: "timeout", ticketId }
                );
                await doc.ref.update({ Status: "Time-out" });
            }

            // อัปเดต reminder flags
            await doc.ref.update({ reminders });

        } catch (error) {
            console.error(`❌ Error processing ticket ${doc.id}:`, error);
        }
    }

    return null;
});
