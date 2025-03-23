package service

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"syscall"
)

func Start() error {
	log.Println("Starting service...")

	workDir := os.Getenv("HYPERSERVICE_WORKDIR_PATH")
	log.Printf("HYPERSERVICE_WORKDIR_PATH: %s\n", workDir)
	if workDir == "" {
		log.Println("❌ environment variable HYPERSERVICE_WORKDIR_PATH is not set")
		workDir = "/"
		log.Printf("Defaulting workDir to %s\n", workDir)
	}

	serviceName := os.Getenv("SERVICE_NAME")
	log.Printf("SERVICE_NAME: %s\n", serviceName)
	if serviceName == "" {
		return fmt.Errorf("❌ environment variable SERVICE_NAME is not set")
	}

	serve := os.Getenv("HYPERSERVICE_SERVE") == "true"
	log.Printf("HYPERSERVICE_SERVE: %v\n", serve)

	log.Printf("📁 Changing working directory to: %s\n", workDir)
	if err := os.Chdir(workDir); err != nil {
		return fmt.Errorf("❌ failed to navigate to %s: %v", workDir, err)
	}
	
	runMoonTask("migrate")
	runMoonTask("seed")

	log.Printf("🚀 Starting service '%s' in background...\n", serviceName)

	var cmd *exec.Cmd
	if serve {
		log.Printf("🔧 Service '%s' will be served\n", serviceName)
		cmd = exec.Command("moon", serviceName+":serve")
	} else {
		log.Printf("🔧 Service '%s' will run in dev mode\n", serviceName)
		cmd = exec.Command("moon", serviceName+":dev")
	}

	// Configure the subprocess properly
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	log.Println("📤 Attaching stdout and stderr to process...")
	log.Println("🏁 Starting the command...")

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("❌ failed to start service '%s': %v", serviceName, err)
	}

	log.Println("✅ Command started successfully")

	go func() {
		log.Printf("🕒 Waiting for service '%s' to finish...\n", serviceName)
		err := cmd.Wait()
		if err != nil {
			log.Printf("❌ Service '%s' exited with error: %v\n", serviceName, err)
		} else {
			log.Printf("✅ Service '%s' stopped successfully.\n", serviceName)
		}
	}()

	return nil
}

func runMoonTask(name string) {
	log.Printf("⚙️ Running moon %s...\n", name)
	cmd := exec.Command("moon", name)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		log.Printf("⚠️ moon %s failed: %v\n", name, err)
	} else {
		log.Printf("✅ moon %s completed successfully\n", name)
	}
}
