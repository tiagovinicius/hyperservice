package observability

import (
	"log"
	"os"
	"os/exec"
)

// collectMetrics inicia o collectd, o que pode ser feito através de um comando do sistema
func CollectMetrics() error {
	// Definir o comando para iniciar o collectd
	cmd := exec.Command("collectd", "-C", "/etc/collectd/collectd.conf") // O caminho do arquivo de configuração pode variar

	// Configuração do output para capturar os logs do collectd
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	// Iniciar o collectd
	err := cmd.Start()
	if err != nil {
		log.Printf("Error starting collectd: %v\n", err)
		return err
	}

	log.Println("Collectd started in background 🎉")


	return nil
}
