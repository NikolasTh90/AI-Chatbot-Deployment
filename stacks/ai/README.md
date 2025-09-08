# AI Services Stack

This stack deploys a complete AI service setup with Open WebUI, Ollama, and a reranker service.

## 📋 Services

### Open WebUI
- **Container**: `open-webui`
- **Image**: `quay.io/pxworks/open-webui:0.6.14`
- **Purpose**: Web interface for AI interactions
- **Access**: Via Nginx Proxy Manager (no direct port exposure)

### Ollama
- **Container**: `ollama`
- **Image**: `ollama/ollama:latest`
- **Purpose**: Large Language Model server
- **Access**: Internal only (port 11434)

### Reranker
- **Container**: `reranker`
- **Image**: `quay.io/nikolas/reranker:cuda-12.4`
- **Purpose**: Query reranking service
- **Model**: Qwen/Qwen3-Reranker-4B
- **Access**: Internal only (port 8000)

## 🚀 Deployment

### Prerequisites

1. **Docker and Docker Compose** installed
2. **Proxy network** created:
   ```bash
   docker network create proxy
   ```
3. **NVIDIA support** (optional, for GPU acceleration)
4. **Portainer** deployed and accessible

### Deploy via Portainer

1. **Access Portainer** web interface
2. **Go to Stacks → Add Stack**
3. **Stack name**: `ai-services`
4. **Upload** this `docker-compose.yml` file
5. **Deploy stack**

### Deploy via Command Line

```bash
# Deploy the stack
docker compose up -d

# For GPU support, use both compose files
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

## 🔧 Configuration

### Networks
- **proxy**: External network for NPM integration
- **ai**: Internal network for service communication

### GPU Support
- **Automatic detection** of NVIDIA GPUs
- **Quantization**: FP8 for reranker
- **Memory optimization** configured

### Environment Variables

#### Open WebUI
- `OLLAMA_BASE_URL=http://ollama:11434`
- `WEBUI_SECRET_KEY`: Secure random key
- `WEBUI_NAME=ParallaxWorks`
- `AIOHTTP_CLIENT_TIMEOUT=900`
- Various feature toggles

#### Reranker
- `MODEL_NAME=Qwen/Qwen3-Reranker-4B`
- `HF_HOME=/workspace/hf`
- `QUANTIZATION=fp8`

### Data Persistence
- **Open WebUI**: `./data/open-webui`
- **Ollama**: `./data/ollama`
- **Reranker**: `./data/reranker/hf`

## 🌐 Access Configuration

### Setup Nginx Proxy Manager

1. **Access NPM** web interface (port 81)
2. **Add Proxy Host**:
   - **Domain**: ai.yourdomain.com
   - **Scheme**: http
   - **Forward Hostname**: `open-webui`
   - **Forward Port**: `8080`
   - **Enable SSL** with Let's Encrypt

### DNS Configuration
Point your domain to your server:
```
A  ai    YOUR_SERVER_IP
```

## 🎛️ Management

### Viewing Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f open-webui
docker compose logs -f ollama
docker compose logs -f reranker
```

### Scaling Services
```bash
# Scale reranker for load balancing
docker compose up -d --scale reranker=2
```

### Service Health Checks
- Monitor in Portainer dashboard
- Check Docker logs for errors
- Verify GPU allocation with `nvidia-smi`

## 🤖 Using the AI Services

### First Setup

1. **Access Open WebUI** via your configured domain
2. **Download models** in Ollama:
   ```bash
   docker exec -it ollama ollama pull llama2
   docker exec -it ollama ollama pull codellama
   ```
3. **Configure models** in Open WebUI interface

### Available Features
- **Chat interface** with multiple AI models
- **Code generation** and assistance
- **Document analysis** with reranking
- **Multi-user support**
- **Conversation history**

### Model Management
```bash
# List available models
docker exec -it ollama ollama list

# Download new model
docker exec -it ollama ollama pull model-name

# Remove model
docker exec -it ollama ollama rm model-name
```

## 🔧 Customization

### Adding Models
1. **Download via CLI**:
   ```bash
   docker exec -it ollama ollama pull new-model
   ```
2. **Or use Open WebUI interface**
3. **Models appear automatically** in chat interface

### Environment Overrides
Create a `.env` file:
```env
WEBUI_NAME=YourCompany
RERANKER_MODEL=different/model
QUANTIZATION=int8
```

### Custom Reranker Model
Update the docker-compose.yml:
```yaml
environment:
  - MODEL_NAME=your/preferred-reranker-model
```

## 📊 Monitoring

### GPU Usage
```bash
# Monitor GPU utilization
nvidia-smi -l 1

# Check container GPU access
docker exec -it ollama nvidia-smi
```

### Resource Monitoring
- **Portainer dashboard** for container stats
- **Docker stats** for real-time metrics:
  ```bash
  docker stats open-webui ollama reranker
  ```

### Storage Usage
```bash
# Check data directory sizes
du -sh data/*/

# Monitor disk usage
df -h
```

## 🔍 Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check logs for errors
docker compose logs

# Verify networks exist
docker network ls | grep -E 'proxy|ai'

# Check resource constraints
docker system df
```

#### GPU Not Detected
```bash
# Verify NVIDIA runtime
docker run --rm --gpus all nvidia/cuda:12.2-base-ubuntu22.04 nvidia-smi

# Check compose file GPU configuration
grep -A5 -B5 nvidia docker-compose.yml
```

#### Models Not Loading
```bash
# Check Ollama logs
docker compose logs ollama

# Verify model downloads
docker exec -it ollama ollama list

# Test model access
curl http://localhost:11434/api/generate -d '{"model":"llama2","prompt":"Hello"}'
```

#### Open WebUI Errors
```bash
# Check Open WebUI logs
docker compose logs open-webui

# Verify Ollama connectivity
docker exec -it open-webui curl http://ollama:11434/api/tags

# Check storage permissions
ls -la data/open-webui/
```

### Performance Issues

#### Slow Response Times
1. **Check GPU utilization**: `nvidia-smi`
2. **Monitor memory usage**: `docker stats`
3. **Adjust quantization** settings
4. **Scale services** if needed

#### Out of Memory
1. **Reduce model sizes** or use smaller models
2. **Adjust container memory limits**
3. **Enable swap** if necessary
4. **Use quantization** options

## 🔐 Security

### Access Control
- **Use strong passwords** in Open WebUI
- **Enable authentication** features
- **Regular updates** of all images
- **Network isolation** between services

### Data Privacy
- **Local deployment** - no data leaves your server
- **Encrypted storage** options available
- **User data isolation** in Open WebUI

## 🔄 Updates

### Update Services
```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d

# Clean up old images
docker image prune -f
```

### Backup Data
```bash
# Create backup of all data
sudo tar -czf ai-services-backup-$(date +%Y%m%d).tar.gz data/

# Restore backup
sudo tar -xzf ai-services-backup-YYYYMMDD.tar.gz
```

This AI stack provides a complete, self-hosted AI service platform with web interface, model serving, and advanced reranking capabilities.