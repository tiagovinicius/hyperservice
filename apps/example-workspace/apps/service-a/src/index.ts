import express from "express";
const app = express();

const PORT = process.env.PORT || 3000;

app.get("/data", (req, res) => {
  res.json({ message: "Hello from Service A!" });
});

app.get("/metrics/prometheus", (req, res) => {
  const metrics = `
# HELP http_requests_total The total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="get", endpoint="/fetch-data"} 42
http_requests_total{method="get", endpoint="/metrics/prometheus"} 15

# HELP memory_usage_bytes Memory usage in bytes
# TYPE memory_usage_bytes gauge
memory_usage_bytes ${Math.random() * 1000000}

# HELP active_users Number of active users
# TYPE active_users gauge
active_users ${Math.floor(Math.random() * 100)}

# HELP service_uptime_seconds Service uptime in seconds
# TYPE service_uptime_seconds counter
service_uptime_seconds ${process.uptime().toFixed(2)}
  `;

  res.set("Content-Type", "text/plain");
  res.send(metrics);
});

app.listen(PORT, () => {
  console.log(`Service A is running on port ${PORT}`);
});
