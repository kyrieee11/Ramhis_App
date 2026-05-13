function logger(req, _res, next) {
  console.log(`${req.method} ${req.url}`);
  next();
}

module.exports = logger;