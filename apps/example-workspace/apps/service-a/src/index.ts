import express from "express";
const app = express();

const PORT = process.env.PORT || 3000;

app.get("/data", (req, res) => {
  res.json({ message: "Hello from Service A!" });
});

app.listen(PORT, () => {
  console.log(`Service A is running on port ${PORT}`);
});
