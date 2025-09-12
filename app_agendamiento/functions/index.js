// functions/index.js

const functions = require("firebase-functions");
const nodemailer = require("nodemailer");
const cors = require("cors")({origin: true});

// Configura el "transporter" de Nodemailer usando las variables de entorno
// Asegúrate de haber configurado estas variables en tu entorno de Firebase
// con `firebase functions:config:set gmail.email="tu_email" gmail.password="tu_contraseña"`
// O usando el nuevo sistema de secretos:
// `firebase functions:secrets:set GMAIL_EMAIL` y `firebase functions:secrets:set GMAIL_PASSWORD`
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