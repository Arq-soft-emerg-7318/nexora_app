package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
)

const (
	// Texto → Groq
	GROQ_URL   = "https://api.groq.com/openai/v1/chat/completions"
	GROQ_MODEL = "llama-3.1-8b-instant"

	// Imagen → HuggingFace
	IMAGE_MODEL = "black-forest-labs/FLUX.1-schnell"
	HF_URL      = "https://router.huggingface.co/hf-inference/models/"
)

type GenerateResponse struct {
	Text  string `json:"text"`
	Image string `json:"image"` // base64
}

func main() {
	// Load optional config file in the tools folder: generate_server_config.json
	// Format: { "GROQ_API_KEY": "...", "HF_TOKEN": "..." }
	cfgPath := "generate_server_config.json"
	if _, err := os.Stat(cfgPath); err == nil {
		b, err := os.ReadFile(cfgPath)
		if err == nil {
			var m map[string]string
			if json.Unmarshal(b, &m) == nil {
				if k, ok := m["GROQ_API_KEY"]; ok && k != "" {
					os.Setenv("GROQ_API_KEY", k)
					log.Printf("Loaded GROQ_API_KEY from %s", cfgPath)
				}
				if t, ok := m["HF_TOKEN"]; ok && t != "" {
					os.Setenv("HF_TOKEN", t)
					log.Printf("Loaded HF_TOKEN from %s", cfgPath)
				}
			}
		}
	}

	http.Handle("/", http.FileServer(http.Dir(".")))
	http.HandleFunc("/generate", handleGenerate)

	fmt.Println("Servidor listo → http://localhost:3000")
	http.ListenAndServe(":3000", nil)
}

// ---------------------- HANDLER ----------------------

func handleGenerate(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "Solo POST", 405)
		return
	}

	log.Printf("/generate desde=%s método=%s", r.RemoteAddr, r.Method)

	// Decodificar el cuerpo como mapa para ignorar cualquier "history" enviado
	var bodyMap map[string]interface{}
	json.NewDecoder(r.Body).Decode(&bodyMap)

	// Extraer prompt de forma segura
	prompt := ""
	if p, ok := bodyMap["prompt"].(string); ok {
		prompt = p
	}

	// Opciones para la generación de imagen: include_map (bool) y country (string)
	// Por defecto no incluir mapa para evitar insertar país en todas las imágenes
	includeMap := false
	if v, ok := bodyMap["include_map"]; ok {
		if b, ok2 := v.(bool); ok2 {
			includeMap = b
		}
	}

	country := "Perú"
	if c, ok := bodyMap["country"].(string); ok && c != "" {
		country = c
	}

	log.Printf("Prompt recibido: %q", prompt)

	// 1) Texto desde GROQ
	text, err := generarTextoGroq(prompt)
	if err != nil {
		http.Error(w, "Error texto: "+err.Error(), 500)
		return
	}

	// 2) Imagen desde HF pero con prompt especializado
	// Construir prompt de imagen, opcionalmente incluyendo el mapa del país
	imgPrompt := "Genera una ilustración moderna y profesional relacionada con el siguiente tema: " +
		prompt +
		". La imagen debe representar el sector tecnológico y minero del país especificado, con estilo digital moderno, elementos de inteligencia artificial, sensores, automatización, datos y maquinaria minera"

	if includeMap {
		imgPrompt = imgPrompt + ", e incluir un mapa de " + country + "."
	} else {
		imgPrompt = imgPrompt + "."
	}

	imgBytes, err := generarImagenHF(imgPrompt)
	if err != nil {
		http.Error(w, "Error imagen: "+err.Error(), 500)
		return
	}

	resp := GenerateResponse{
		Text:  text,
		Image: base64.StdEncoding.EncodeToString(imgBytes),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)

	// Asegurar que no se preserva historial: si el cliente envió un campo "history", lo ignoramos
	if _, ok := bodyMap["history"]; ok {
		log.Printf("Historial recibido y eliminado para la petición desde=%s", r.RemoteAddr)
	}
}

// ---------------------- TEXTO (GROQ) ----------------------

func generarTextoGroq(prompt string) (string, error) {
	apiKey := os.Getenv("GROQ_API_KEY")
	if apiKey == "" {
		// Fallback: generar texto simulado para desarrollo local
		log.Printf("WARNING: GROQ_API_KEY no configurada — usando fallback de texto simulado")
		// Construir título a partir de las primeras palabras del prompt
		trimmed := strings.TrimSpace(prompt)
		if trimmed == "" {
			return "Título de prueba\nTexto de prueba generado sin GROQ_API_KEY.", nil
		}

		// título: hasta 5 palabras
		parts := strings.Fields(trimmed)
		titleWords := 5
		if len(parts) < titleWords {
			titleWords = len(parts)
		}
		title := strings.Join(parts[:titleWords], " ")
		if len(title) > 60 {
			title = title[:60]
		}

		body := "(Generado localmente - sin clave) " + trimmed
		// acortar body si es demasiado largo
		if len(body) > 940 {
			body = body[:940]
		}

		final := title + "\n" + body
		return final, nil
	}

	payload := map[string]interface{}{
		"model": GROQ_MODEL,
		"messages": []map[string]string{
			{"role": "user", "content": prompt},
		},
	}

	bodyBytes, _ := json.Marshal(payload)

	req, _ := http.NewRequest("POST", GROQ_URL, bytes.NewBuffer(bodyBytes))
	req.Header.Add("Authorization", "Bearer "+apiKey)
	req.Header.Add("Content-Type", "application/json")

	log.Printf("-> Enviando solicitud a GROQ model=%s url=%s", GROQ_MODEL, GROQ_URL)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer res.Body.Close()

	raw, _ := io.ReadAll(res.Body)

	// Loguear respuesta (truncada a 1000 chars para evitar volcar cosas enormes)
	rawStr := string(raw)
	if len(rawStr) > 1000 {
		log.Printf("<- GROQ status=%d body(trunc)=%s... (len=%d)", res.StatusCode, rawStr[:1000], len(rawStr))
	} else {
		log.Printf("<- GROQ status=%d body=%s", res.StatusCode, rawStr)
	}

	var data struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}

	json.Unmarshal(raw, &data)

	var result string
	if len(data.Choices) > 0 {
		result = data.Choices[0].Message.Content
	} else {
		result = string(raw)
	}

	// Limitar la longitud total del texto a 1000 caracteres
	const maxTotal = 1000
	if len(result) > maxTotal {
		log.Printf("Texto generado original len=%d; truncando a %d caracteres", len(result), maxTotal)
		result = result[:maxTotal]
	}

	// Construir título corto antes del primer salto de línea
	const maxTitle = 60
	var title, body string

	if idx := strings.Index(result, "\n"); idx != -1 {
		title = strings.TrimSpace(result[:idx])
		body = strings.TrimSpace(result[idx+1:])
	} else {
		// intentar usar la primera oración como título si existe
		if p := strings.Index(result, "."); p != -1 && p < 120 {
			title = strings.TrimSpace(result[:p+1])
			body = strings.TrimSpace(result[p+1:])
		} else {
			if len(result) > maxTitle {
				title = strings.TrimSpace(result[:maxTitle])
				body = strings.TrimSpace(result[maxTitle:])
			} else {
				title = strings.TrimSpace(result)
				body = ""
			}
		}
	}

	if len(title) > maxTitle {
		title = title[:maxTitle]
	}

	// Ajustar para que title + "\n" + body no exceda maxTotal
	allowedBody := maxTotal - len(title) - 1 // 1 por el '\n'
	if allowedBody < 0 {
		// título demasiado largo (no esperado): truncar título y vaciar body
		title = title[:maxTitle]
		body = ""
	} else if len(body) > allowedBody {
		body = body[:allowedBody]
	}

	final := title
	if body != "" {
		final = title + "\n" + body
	} else {
		final = title + "\n"
	}

	return final, nil
}

// ---------------------- IMAGEN (HUGGINGFACE) ----------------------

func generarImagenHF(prompt string) ([]byte, error) {
	token := os.Getenv("HF_TOKEN")
	if token == "" {
		// Fallback: devolver imagen placeholder (1x1 PNG) para desarrollo
		log.Printf("WARNING: HF_TOKEN no configurado — usando imagen placeholder (1x1 PNG)")
		placeholderBase64 := "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII="
		b, _ := base64.StdEncoding.DecodeString(placeholderBase64)
		return b, nil
	}

	payload := map[string]string{
		"inputs": prompt,
	}

	bodyBytes, _ := json.Marshal(payload)

	req, _ := http.NewRequest("POST", HF_URL+IMAGE_MODEL, bytes.NewBuffer(bodyBytes))
	req.Header.Add("Authorization", "Bearer "+token)
	req.Header.Add("Content-Type", "application/json")

	log.Printf("-> Enviando solicitud a HF model=%s url=%s", IMAGE_MODEL, HF_URL+IMAGE_MODEL)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()

	imgBytes, err := io.ReadAll(res.Body)
	if err != nil {
		return nil, err
	}

	log.Printf("<- HF status=%d bytes=%d", res.StatusCode, len(imgBytes))

	return imgBytes, nil
}
