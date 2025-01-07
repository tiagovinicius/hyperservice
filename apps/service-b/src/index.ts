import express from "express";
import axios from "axios";
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
    if (error instanceof Error) {
      console.error(error.message);
    } else {
      console.error("An unknown error occurred");
    }
    res.status(500).json({ error: "Failed to fetch data from Service A" });
  }
});

app.listen(PORT, () => {
  console.log(`Service B is running on port ${PORT}`);
});
