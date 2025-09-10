const functions = require("firebase-functions");
const nodemailer = require("nodemailer");
const cors = require("cors")({origin: true});

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
