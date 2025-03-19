const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.resetTodayViews = functions.pubsub.schedule('0 0 * * *') // 매일 자정 실행
  .timeZone('Asia/Seoul') // 한국 시간대
  .onRun(async (context) => {
    const usersRef = admin.firestore().collection('users');
    const usersSnapshot = await usersRef.get();

    const batch = admin.firestore().batch();
    usersSnapshot.forEach((userDoc) => {
      const userRef = usersRef.doc(userDoc.id);
      batch.update(userRef, {
        todayViews: 0,
        lastResetAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
    console.log('Successfully reset todayViews for all users');
    return null;
  });