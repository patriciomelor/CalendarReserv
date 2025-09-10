const functions = require("firebase-functions");
const nodemailer = require("nodemailer");
const cors = require("cors")({origin: true});
const admin = require("firebase-admin");
// Configura tu cuenta de Gmail. Es recomendable usar una "Contraseña de aplicación".
// Búscalo en Google: "Cómo generar una contraseña de aplicación de Google".
const gmailEmail = "riquelmepatricio.m@gmail.com";
const gmailPassword = "evrn ghta sgtl ckhl";

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: gmailEmail,
    pass: gmailPassword,
  },
});

exports.sendEmail = functions.https.onRequest((req, res) => {
  // Habilitamos CORS para que el navegador no bloquee la petición
  cors(req, res, () => {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    const {to, subject, htmlBody} = req.body;

    if (!to || !subject || !htmlBody) {
      return res.status(400).send("Faltan parámetros.");
    }

    const mailOptions = {
      from: `"App de Agendamiento" <${gmailEmail}>`,
      to: to,
      subject: subject,
      html: htmlBody,
    };

    transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
        console.error("Error al enviar correo:", error);
        return res.status(500).send(error.toString());
      }
      return res.status(200).send("Correo enviado: " + info.response);
    });
  });
});
// Este comentario es para forzar un nuevo despliegue.
admin.initializeApp();

// Esta función se activa cada vez que se crea un nuevo documento en 'appointments'
exports.sendNewAppointmentNotification = functions.firestore
  .document("appointments/{appointmentId}")
  .onCreate(async (snap, context) => {
    const appointmentData = snap.data();

    // 1. Obtener el ID del profesional
    const professionalId = appointmentData.professionalId;

    // 2. Buscar el documento del profesional en la colección 'users' para obtener su token
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(professionalId) // ¡OJO! Esto asume que el professionalId es el UID del usuario.
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

    // 3. Preparar el mensaje de la notificación
    const payload = {
      notification: {
        title: "¡Nueva Cita Agendada!",
        body: `${appointmentData.customerName} ha agendado un servicio de "${appointmentData.serviceName}" para el ${appointmentData.startTime}.`,
        // click_action: "FLUTTER_NOTIFICATION_CLICK", // Para manejar el toque en la app
      },
    };

    // 4. Enviar la notificación al token del profesional
    try {
      await admin.messaging().sendToDevice(fcmToken, payload);
      console.log("Notificación enviada con éxito.");
    } catch (error) {
      console.error("Error al enviar la notificación:", error);
    }
  });