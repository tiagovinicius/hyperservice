package utils

import (
	"fmt"
	"os"
	"path/filepath"
)

// updateSemaphore writes "true" or "false" to the semaphore file
func UpdateSemaphore(path string, status string) error {
	fmt.Printf("🔄 Updating semaphore file: %s -> %s\n", path, status)

	// Extrai o diretório do caminho do arquivo
	dir := filepath.Dir(path)

	// Garante que o diretório existe, criando se necessário
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create directory %s: %w", dir, err)
	}

	// Abre o arquivo para escrita, criando se não existir
	file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		return fmt.Errorf("failed to open semaphore file: %w", err)
	}
	defer file.Close()

	// Escreve o status no arquivo
	_, err = file.WriteString(status)
	if err != nil {
		return fmt.Errorf("failed to write to semaphore file: %w", err)
	}

	return nil
}