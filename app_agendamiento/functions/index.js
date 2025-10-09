// functions/index.js

const functions = require("firebase-functions");
const nodemailer = require("nodemailer");
const cors = require("cors")({origin: true});
const admin = require("firebase-admin");

admin.initializeApp();

// Configura el "transporter" de Nodemailer usando las variables de entorno
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.GMAIL_EMAIL,
    pass: process.env.GMAIL_PASSWORD,
  },
});

exports.sendEmail = functions.runWith({ secrets: ["GMAIL_EMAIL", "GMAIL_PASSWORD"] }).https.onRequest((req, res) => {
  cors(req, res, () => {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    const {to, subject, htmlBody} = req.body;

    if (!to || !subject || !htmlBody) {
      return res.status(400).send("Faltan parámetros.");
    }

    const mailOptions = {
      from: `App de Agendamiento <${process.env.GMAIL_EMAIL}>`,
      to: to,
      subject: subject,
      html: htmlBody,
    };

    return transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
        console.error("Error al enviar correo:", error);
        return res.status(500).send(error.toString());
      }
      return res.status(200).send("Correo enviado: " + info.response);
    });
  });
});


// En functions/index.js

// Esta función se activa cada vez que se crea un nuevo documento en 'appointments'
exports.sendNewAppointmentNotification = functions.firestore
  .document('appointments/{appointmentId}')
  .onCreate(async (snap, context) => {
    const appointment = snap.data();

    // Agrega logs para depuración
    console.log('Datos de la cita:', appointment);

    // Asegúrate de que el token existe
    const token = appointment?.professionalToken;
    console.log('Token de notificación del profesional:', token);

    // Construye el payload
    const payload = {
      notification: {
        title: 'Nueva cita registrada',
        body: `Tienes una nueva cita para el ${appointment?.date || 'fecha desconocida'}`,
      },
      token: token,
    };
    console.log('Payload a enviar:', payload);

    if (!token) {
      console.error('No se encontró token de notificación para el profesional');
      return;
    }

    try {
      await admin.messaging().send(payload);
      console.log('Notificación enviada correctamente');
    } catch (error) {
      console.error('Error al enviar la notificación push:', error);
    }
  });

exports.confirmAppointment = functions.https.onRequest(async (req, res) => {
  const appointmentId = req.query.id;
  if (!appointmentId) {
    return res.status(400).send("Falta el ID de la cita.");
  }

  try {
    await admin.firestore().collection("appointments").doc(appointmentId).update({
      status: "confirmada",
    });
    return res.status(200).send("Cita confirmada con éxito.");
  } catch (error) {
    console.error("Error al confirmar la cita:", error);
    return res.status(500).send("Error al confirmar la cita.");
  }
});

exports.cancelAppointment = functions.https.onRequest(async (req, res) => {
  const appointmentId = req.query.id;
  if (!appointmentId) {
    return res.status(400).send("Falta el ID de la cita.");
  }

  try {
    await admin.firestore().collection("appointments").doc(appointmentId).update({
      status: "cancelada",
    });
    return res.status(200).send("Cita cancelada con éxito.");
  } catch (error) {
    console.error("Error al cancelar la cita:", error);
    return res.status(500).send("Error al cancelar la cita.");
  }
});

exports.cancelPendingAppointments = functions.pubsub.schedule('every 60 minutes').onRun(async (context) => {
  const now = admin.firestore.Timestamp.now();
  const yesterday = admin.firestore.Timestamp.fromMillis(now.toMillis() - 24 * 60 * 60 * 1000);

  const pendingAppointments = await admin.firestore().collection('appointments')
    .where('status', '==', 'pendiente')
    .where('createdAt', '<=', yesterday)
    .get();

  if (pendingAppointments.empty) {
    console.log('No pending appointments to cancel.');
    return null;
  }

  const batch = admin.firestore().batch();
  pendingAppointments.docs.forEach(doc => {
    batch.update(doc.ref, { status: 'cancelada' });
  });

  await batch.commit();
  console.log(`Cancelled ${pendingAppointments.size} pending appointments.`);
  return null;
});