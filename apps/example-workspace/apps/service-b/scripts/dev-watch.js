import { spawn } from "child_process";
import chokidar from "chokidar";

let app;

function startApp() {
  app = spawn("node", ["dist/index.cjs"], { stdio: "inherit" });
}

function restartApp() {
  if (app) {
    app.kill();
  }
  startApp();
}

chokidar.watch("dist/index.cjs").on("change", () => {
  console.log("🔁 Código recompilado. Reiniciando app...");
  restartApp();
});

startApp();
