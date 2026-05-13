function safeServerError(res, error) {
  console.error('❌ SERVER ERROR:', error?.response?.body || error);
  return res.status(500).json({
    message: 'Internal server error.',
  });
}

module.exports = {
  safeServerError,
};