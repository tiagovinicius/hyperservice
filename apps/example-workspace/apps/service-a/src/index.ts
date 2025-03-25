import express from "express";
import axios from "axios";
const app = express();

const PORT = process.env.PORT || 3000;

app.get("/call-service-b", async (req, res) => {
  try {
    const response = await axios.get(process.env.SERVICE_B_API_URL ?? "");
    res.json({
      message: "Data fetched from Service B XXXXX",
      data: response.data,
    });
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    console.error(errorMessage);
    res.status(200).json({
      error: "Failed to fetch data from Service B: " + errorMessage,
      url: process.env.SERVICE_B_API_URL,
    });
  }
});

app.listen(PORT, () => {
  console.log(`Service A is running on port ${PORT}`);
});
