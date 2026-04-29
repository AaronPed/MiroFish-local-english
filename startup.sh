#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

wait_for_port() {
    local port=$1
    local service=$2
    local max_attempts=${3:-30}
    local attempt=0

    while ! nc -z localhost "$port" 2>/dev/null; do
        attempt=$((attempt + 1))
        if [ "$attempt" -ge "$max_attempts" ]; then
            log_error "$service failed to start on port $port"
            return 1
        fi
        sleep 1
    done
    log_info "$service ready on port $port"
}

# ─────────────────────────────────────────────
# 1. Stop existing services
# ─────────────────────────────────────────────
log_info "Stopping existing services..."

pkill -f "uv run python run.py" 2>/dev/null || true
pkill -f "llama-server" 2>/dev/null || true
pkill -f "ollama serve" 2>/dev/null || true
pkill -f "vite" 2>/dev/null || true

docker-compose -f docker-compose.local.yml down 2>/dev/null || true

sleep 2
log_info "Cleanup complete."

# ─────────────────────────────────────────────
# 2. Neo4j
# ─────────────────────────────────────────────
log_info "Starting Neo4j..."
docker-compose -f docker-compose.local.yml up -d neo4j
wait_for_port 7687 "Neo4j" 60

# ─────────────────────────────────────────────
# 3. Ollama
# ─────────────────────────────────────────────
log_info "Starting Ollama..."
if ! pgrep -x "ollama" > /dev/null; then
    ollama serve > /tmp/ollama.log 2>&1 &
    wait_for_port 11434 "Ollama" 30
else
    log_warn "Ollama already running"
    wait_for_port 11434 "Ollama" 5
fi

# Ensure nomic-embed-text is available
if ! ollama list | grep -q "nomic-embed-text"; then
    log_info "Pulling nomic-embed-text..."
    ollama pull nomic-embed-text
fi

# ─────────────────────────────────────────────
# 4. llama-server (Qwen3-14B)
# ─────────────────────────────────────────────
log_info "Starting llama-server..."
if [ -f ~/code/llama.cpp/build/bin/llama-server ]; then
    ~/code/llama.cpp/build/bin/llama-server \
        -m ~/code/models/Qwen3-14B-Q4_K_M.gguf \
        --host 0.0.0.0 \
        --port 8080 \
        -ngl 999 \
        --device ROCm0 \
        --flash-attn on \
        --reasoning off \
        -np 8 \
        -cb \
        -c 16384 \
        -b 512 \
        --mlock \
        > /tmp/llama-server.log 2>&1 &
    wait_for_port 8080 "llama-server" 60
else
    log_error "llama-server binary not found at ~/code/llama.cpp/build/bin/llama-server"
    exit 1
fi

# ─────────────────────────────────────────────
# 5. Backend
# ─────────────────────────────────────────────
log_info "Starting MiroFish backend..."
cd backend
uv run python run.py > /tmp/backend.log 2>&1 &
cd ..
wait_for_port 5001 "Backend" 60

# ─────────────────────────────────────────────
# 6. Frontend
# ─────────────────────────────────────────────
log_info "Starting MiroFish frontend..."
cd frontend
npm run dev > /tmp/frontend.log 2>&1 &
cd ..
wait_for_port 3000 "Frontend" 30

# ─────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────
echo ""
log_info "All services are up!"
echo ""
echo "  Frontend:  http://localhost:3000"
echo "  Backend:   http://localhost:5001"
echo "  LLM:       http://localhost:8080"
echo "  Embeddings: http://localhost:11434"
echo "  Neo4j:     bolt://localhost:7687"
echo ""
echo "  Logs:"
echo "    /tmp/llama-server.log"
echo "    /tmp/backend.log"
echo "    /tmp/frontend.log"
echo ""
