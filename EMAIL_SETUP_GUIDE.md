## Email Service Setup Guide

This document explains how to set up automatic email notifications for your Rentr Workflow app.

### Overview
The app now sends automatic emails for the following events:
1. **Job Assigned** - Contractor receives email when assigned to a job
2. **Job Started** - Agent receives email when contractor starts work
3. **Job Completed** - Agent receives email when contractor completes work
4. **Payment Completed** - Contractor receives email when payment is received

### Architecture
- **Flutter App**: Calls `EmailService` class methods
- **Cloud Functions**: `sendEmail` function receives the requests and sends emails
- **Email Provider**: Gmail or any SMTP-compatible service

### Setup Steps

#### 1. Install Dependencies

In your `functions/package.json`, add:
```json
{
  "dependencies": {
    "firebase-functions": "^4.4.1",
    "firebase-admin": "^11.11.0",
    "nodemailer": "^6.9.7"
  }
}
```

Run: `npm install` in the functions directory

#### 2. Set Up Environment Variables

Configure Firebase environment variables for email credentials:

```bash
firebase functions:config:set gmail.email="your-email@gmail.com"
firebase functions:config:set gmail.password="your-app-password"
```

**Note**: For Gmail, use an [App Password](https://support.google.com/accounts/answer/185833) (not your regular password)

#### 3. Deploy Cloud Function

Navigate to your functions directory and deploy:

```bash
firebase deploy --only functions
```

#### 4. Update pubspec.yaml (if not already added)

Add the Firebase Functions plugin to your Flutter app:

```yaml
dependencies:
  firebase_functions: ^5.0.0
```

#### 5. Enable APIs

In Firebase Console:
- Go to **APIs & Services**
- Enable **Cloud Functions API**
- Enable **Cloud Logging API** (for debugging)

### Email Events

#### When emails are sent:

1. **Job Assigned Email**
   - **Recipient**: Contractor
   - **When**: Agent assigns a job to contractor
   - **Contains**: Job title, description, timeline

2. **Job Started Email**
   - **Recipient**: Agent
   - **When**: Contractor clicks "Start Job"
   - **Contains**: Job title, contractor name

3. **Job Completed Email**
   - **Recipient**: Agent
   - **When**: Contractor clicks "Complete Job"
   - **Contains**: Job title, contractor name

4. **Payment Completed Email**
   - **Recipient**: Contractor
   - **When**: Agent processes payment via Razorpay
   - **Contains**: Job title, amount, payment ID

### Testing

To test the email functionality:

1. Deploy the Cloud Function as described above
2. Run your Flutter app
3. Trigger events:
   - Assign a job to a contractor → Check contractor's email
   - Start a job → Check agent's email
   - Complete a job → Check agent's email
   - Process payment → Check contractor's email

### Troubleshooting

**Emails not sending?**
- Check Firebase Cloud Functions logs in Firebase Console
- Verify email credentials are set correctly
- Ensure Cloud Functions API is enabled
- Check email restrictions (Gmail security settings)

**Gmail Issues?**
- Use App Passwords, not your regular Gmail password
- Enable 2-Factor Authentication on your Gmail account
- Check "Less secure apps" setting if not using App Password

**Function not being called?**
- Verify `firebase_functions` package is installed in Flutter
- Check console logs for errors in `EmailService` calls
- Ensure users have email addresses in Firestore

### Customizing Email Templates

Edit the HTML templates in `functions/sendEmail.js` to customize:
- Email subject lines
- Email body content
- Styling and formatting
- Company branding

### Production Considerations

- Use a dedicated email service account (not personal Gmail)
- Consider using services like SendGrid, Mailgun, or AWS SES for production
- Implement email rate limiting to prevent abuse
- Add email templates with logo and branding
- Set up bounce handling and unsubscribe links
- Monitor email delivery rates
