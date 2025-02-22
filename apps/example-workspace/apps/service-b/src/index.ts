import express from "express";
import axios from "axios";
const app = express();

const PORT = process.env.PORT || 3000;

app.get("/call-service-a", async (req, res) => {
  try {
    const response = await axios.get(
      "http://service-a.hyperservice.svc.cluster.local:3000/data"
    );
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
