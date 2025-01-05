const express = require("express");
const axios = require("axios");
const app = express();

const PORT = process.env.PORT || 3002;

app.get("/fetch-data", async (req, res) => {
  try {
    const response = await axios.get("http://service-a.mesh/data");
    res.json({
      message: "Data fetched from Service A",
      data: response.data,
    });
  } catch (error) {
    console.error(error.message);
    res.status(500).json({ error: "Failed to fetch data from Service A" });
  }
});

app.listen(PORT, () => {
  console.log(`Service B is running on port ${PORT}`);
});
