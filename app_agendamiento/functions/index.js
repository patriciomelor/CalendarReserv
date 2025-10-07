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
  .document("appointments/{appointmentId}")
  .onCreate(async (snap, context) => {
    const appointmentData = snap.data();

    // 1. Obtener el ID del documento del profesional
    const professionalDocId = appointmentData.professionalId;
    
    // 2. Obtener el documento del profesional para encontrar su UID
    const professionalDoc = await admin
        .firestore()
        .collection("professionals")
        .doc(professionalDocId)
        .get();

    if (!professionalDoc.exists) {
      console.log("No se encontró el perfil del profesional.");
      return;
    }

    const professionalUid = professionalDoc.data().uid;
    if (!professionalUid) {
      console.log("El profesional no tiene un UID de usuario asociado.");
      return;
    }
    
    // 3. Buscar el documento del usuario del profesional para obtener su token FCM
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(professionalUid)
      .get();
    
    if (!userDoc.exists) {
      console.log("No se encontró el usuario del profesional.");
      return;
    }

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.log("El profesional no tiene un token FCM para notificar.");
      return;
    }

    // 4. Preparar el mensaje de la notificación
    const payload = {
      notification: {
        title: "¡Nueva Cita Agendada!",
        body: `${appointmentData.customerName} ha agendado una cita contigo.`,
      },
    };

    // 5. Enviar la notificación
    try {
      await admin.messaging().sendToDevice(fcmToken, payload);
      console.log("Notificación push enviada con éxito.");
    } catch (error) {
      console.error("Error al enviar la notificación push:", error);
    }
  });