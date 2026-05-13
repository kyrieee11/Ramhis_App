const { sgMail, SENDGRID_API_KEY, SENDGRID_FROM_EMAIL } = require('../config/email');

const APP_RESET_LINK_BASE = process.env.APP_RESET_LINK_BASE || 'myapp://reset-password';
const WEB_RESET_LINK_BASE = process.env.WEB_RESET_LINK_BASE || 'http://localhost:5000/reset-password';

// ── Reset link builder ────────────────────────────────────────────────────────
function buildResetLinks(rawToken) {
  const appResetLink = `${APP_RESET_LINK_BASE}?token=${encodeURIComponent(rawToken)}`;
  const webResetLink = `${WEB_RESET_LINK_BASE}?token=${encodeURIComponent(rawToken)}`;
  return { appResetLink, webResetLink };
}

// ── Reset email HTML template ─────────────────────────────────────────────────
function buildResetEmailHtml(appResetLink, webResetLink) {
  return `
    <div style="font-family: Arial, sans-serif; color: #1f2937; line-height: 1.6;">
      <h2>Reset Password</h2>
      <p>You requested to reset your password.</p>
      <p>Open in app:</p>
      <p>
        <a href="${appResetLink}" style="display:inline-block;background:#4766C7;color:#ffffff;text-decoration:none;padding:12px 18px;border-radius:8px;">
          Open in App
        </a>
      </p>
      <p>If the button above does not work, use this browser link:</p>
      <p><a href="${webResetLink}">${webResetLink}</a></p>
      <p>This link will expire in 15 minutes.</p>
    </div>
  `;
}

// ── Send password reset email ─────────────────────────────────────────────────
async function sendPasswordResetEmail(user, rawToken) {
  const { appResetLink, webResetLink } = buildResetLinks(rawToken);

  // Fallback mode — SendGrid not configured
  if (!SENDGRID_API_KEY || !SENDGRID_FROM_EMAIL) {
    console.log('🔗 APP RESET LINK:', appResetLink);
    console.log('🔗 WEB RESET LINK:', webResetLink);

    return {
      fallback: true,
      message: 'Reset link generated (fallback mode).',
      resetLink: appResetLink,
      appResetLink,
      webResetLink,
    };
  }

  // SendGrid mode
  await sgMail.send({
    to: user.email,
    from: {
      email: SENDGRID_FROM_EMAIL,
      name: 'RAMHIS Support',
    },
    subject: 'Reset your password',
    html: buildResetEmailHtml(appResetLink, webResetLink),
  });

  console.log('✅ Email sent to:', user.email);
  console.log('🔗 APP RESET LINK:', appResetLink);
  console.log('🔗 WEB RESET LINK:', webResetLink);

  return {
    fallback: false,
    message: 'Reset email sent successfully.',
    resetLink: appResetLink,
    appResetLink,
    webResetLink,
  };
}

module.exports = {
  sendPasswordResetEmail,
};