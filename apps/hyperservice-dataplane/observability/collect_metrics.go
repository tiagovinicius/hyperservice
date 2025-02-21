package observability

import (
	"log"
	"os"
	"os/exec"
)

// collectMetrics inicia o collectd em background, de modo que o processo continue executando
func CollectMetrics() error {
	// Definir o comando para iniciar o collectd
	cmd := exec.Command("collectd", "-C", "/etc/collectd/collectd.conf") // O caminho do arquivo de configuração pode variar

	// Configuração do output para capturar os logs do collectd
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	// Iniciar o collectd em background
	err := cmd.Start()
	if err != nil {
		log.Printf("Error starting collectd: %v\n", err)
	}

	// Garantir que o processo continue rodando em background
	log.Println("Collectd started in background 🎉 usando go routines")

	// Não esperar pelo processo terminar, pois estamos rodando em background
	go func() {
		// Esperar o processo terminar, se necessário
		err = cmd.Wait()
		if err != nil {
			log.Printf("Error while collectd running in background: %v\n", err)
		}
	}()

	return nil
}
