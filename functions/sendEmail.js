// Firebase Cloud Function for sending emails
// Deploy using: firebase deploy --only functions

const functions = require("firebase-functions");
const nodemailer = require("nodemailer");

// Configure email service
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD,
  },
});

// Cloud Function to send emails
exports.sendEmail = functions.https.onCall(async (data, context) => {
  const emailType = data.type;
  let mailOptions = {};

  try {
    switch (emailType) {
      case "job_assigned":
        mailOptions = {
          from: process.env.EMAIL_USER,
          to: data.to,
          subject: `New Job Assigned: ${data.jobTitle}`,
          html: `<h2>Job Assignment Notification</h2>
<p>Hello ${data.contractorName},</p>
<p>You have been assigned to a new job:</p>
<ul>
<li><strong>Job Title:</strong> ${data.jobTitle}</li>
<li><strong>Description:</strong> ${data.jobDescription}</li>
<li><strong>Timeline:</strong> ${
  new Date(data.timeline).toLocaleDateString()}</li>
</ul>
<p>Please log in to view more details and start the job.</p>
<p>Best regards,<br>Rentr Workflow Team</p>`,
        };
        break;

      case "job_started":
        mailOptions = {
          from: process.env.EMAIL_USER,
          to: data.to,
          subject: `Job Started: ${data.jobTitle}`,
          html: `<h2>Job Started Notification</h2>
<p>Hello ${data.agentName},</p>
<p>The contractor started working on the job:</p>
<ul>
<li><strong>Job Title:</strong> ${data.jobTitle}</li>
<li><strong>Contractor:</strong> ${data.contractorName}</li>
</ul>
<p>The work is now in progress. Please monitor the
job status in your account.</p>
<p>Best regards,<br>Rentr Workflow Team</p>`,
        };
        break;

      case "job_completed":
        mailOptions = {
          from: process.env.EMAIL_USER,
          to: data.to,
          subject: `Job Completed: ${data.jobTitle}`,
          html: `<h2>Job Completed Notification</h2>
<p>Hello ${data.agentName},</p>
<p>The contractor completed the job:</p>
<ul>
<li><strong>Job Title:</strong> ${data.jobTitle}</li>
<li><strong>Contractor:</strong> ${data.contractorName}</li>
</ul>
<p>Please review the work and process payment if
everything is satisfactory.</p>
<p>Best regards,<br>Rentr Workflow Team</p>`,
        };
        break;

      case "payment_completed":
        mailOptions = {
          from: process.env.EMAIL_USER,
          to: data.to,
          subject: "Payment Received - Rentr Workflow",
          html: `<h2>Payment Completed</h2>
<p>Hello ${data.contractorName},</p>
<p>Payment has been processed successfully:</p>
<ul>
<li><strong>Amount:</strong> $${data.amount}</li>
<li><strong>Payment ID:</strong> ${data.paymentId}</li>
<li><strong>Job Title:</strong> ${data.jobTitle}</li>
</ul>
<p>Thank you for your excellent work. Please allow
1-2 business days for funds to appear in your account.</p>
<p>Best regards,<br>Rentr Workflow Team</p>`,
        };
        break;

      default:
        return {
          success: false,
          message: "Unknown email type",
        };
    }

    // Send email
    await transporter.sendMail(mailOptions);

    return {
      success: true,
      message: "Email sent successfully",
    };
  } catch (error) {
    console.error("Error sending email:", error);
    return {
      success: false,
      message: `Error sending email: ${error.message}`,
    };
  }
});
