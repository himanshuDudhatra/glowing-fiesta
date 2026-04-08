const express = require("express");

const app = express();
const PORT = process.env.PORT || 3000;
app.set("trust proxy", true);

app.get("/", (req, res) => {

  res.json({
    timestamp: new Date().toISOString(),
    ip: req.ip,
  });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`SimpleTimeService running on port ${PORT}`);
});
