import express from "express";
import axios from "axios";
const app = express();

const PORT = process.env.PORT || 3000;

app.get("/call-service-x", async (req, res) => {
  try {
    const response = await axios.get(process.env.SERVICE_X_API_URL ?? "");
    res.json({
      message: "Data fetched from Service X",
      data: response.data,
    });
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    console.error(errorMessage);
    res.status(200).json({
      error: "Failed to fetch data from Service X: " + errorMessage,
      url: process.env.SERVICE_X_API_URL,
    });
  }
});

app.listen(PORT, () => {
  console.log(`Service B is running on port ${PORT}`);
});
