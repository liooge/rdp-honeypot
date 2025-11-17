#!/bin/bash
# RDP Honeypot Test Runner
# Unified test script supporting different operations via parameters

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_DIR/server.log"
PID_FILE="/tmp/rdp_honeypot.pid"
RDP_PORT=3101
HTTP_PORT=8080

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[RUNNER]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Kill existing processes
cleanup() {
    log "Cleaning up old processes..."
    
    # Kill RDP honeypot
    pkill -9 -f "python3 server/rdp_honeypot_freerdp.py" 2>/dev/null || true
    
    # Kill any lingering rdp_honeypot processes
    pkill -9 -f "python3.*rdp_honeypot" 2>/dev/null || true
    
    # Wait a bit for sockets to close
    sleep 2
    
    # Check if ports are still in use
    if netstat -tlnp 2>/dev/null | grep -q ":$RDP_PORT "; then
        warn "Port $RDP_PORT still in use, trying to force close..."
        fuser -k $RDP_PORT/tcp 2>/dev/null || true
        sleep 1
    fi
    
    if netstat -tlnp 2>/dev/null | grep -q ":$HTTP_PORT "; then
        warn "Port $HTTP_PORT still in use, trying to force close..."
        fuser -k $HTTP_PORT/tcp 2>/dev/null || true
        sleep 1
    fi
    
    log "Cleanup complete"
}

# Start server
start_server() {
    cd "$PROJECT_DIR"
    
    log "Starting RDP honeypot server..."
    
    # Clear old log file
    > "$LOG_FILE"
    
    # Start runner in background (don't wait for it to be ready)
    python3 server/rdp_honeypot_freerdp.py > "$LOG_FILE" 2>&1 &
    local PID=$!
    echo $PID > "$PID_FILE"
    
    log "Server started (PID: $PID)"
    log "Waiting for server to be ready..."
    
    # Give server time to start without blocking
    for i in {1..20}; do
        if netstat -tlnp 2>/dev/null | grep -q ":$RDP_PORT " || lsof -i :$RDP_PORT 2>/dev/null | grep -q LISTEN; then
            log "✓ Server ready on port $RDP_PORT"
            return 0
        fi
        if ! kill -0 $PID 2>/dev/null; then
            error "Server process died unexpectedly"
            tail -20 "$LOG_FILE"
            return 1
        fi
        sleep 0.5
    done
    
    warn "Server startup timeout (but process still running, continuing anyway)"
    return 0
}

# Show logs
show_logs() {
    log "Tailing server logs (Press Ctrl+C to stop)..."
    tail -f "$LOG_FILE"
}

# Check server status
check_status() {
    local port_check=$(netstat -tlnp 2>/dev/null | grep ":$RDP_PORT " || echo "")
    
    if [ -z "$port_check" ]; then
        error "Server NOT running on port $RDP_PORT"
        return 1
    else
        log "Server RUNNING on port $RDP_PORT"
        echo "$port_check" | tail -1
        return 0
    fi
}

# Query database for captured credentials
query_db() {
    log "Fetching captured credentials from database..."
    
    if [ -f "$PROJECT_DIR/rdp_server.db" ]; then
        sqlite3 "$PROJECT_DIR/rdp_server.db" << EOF
.mode box
.headers on
SELECT id, ip, port, c_name, c_pwd, time FROM rdp_client ORDER BY time DESC LIMIT 30;
EOF
    else
        error "Database not found at $PROJECT_DIR/rdp_server.db"
        return 1
    fi
}

# Show hourly reports
show_reports() {
    log "Showing hourly reports..."
    
    if ls "$PROJECT_DIR/logs"/*_report.txt >/dev/null 2>&1; then
        for report in "$PROJECT_DIR/logs"/*_report.txt; do
            echo ""
            echo -e "${BLUE}=== $(basename "$report") ===${NC}"
            cat "$report"
        done
    else
        warn "No reports found in $PROJECT_DIR/logs/"
    fi
}

# Test HTTP health endpoint
test_http() {
    log "Testing HTTP health check endpoint..."
    
    if curl -s http://localhost:$HTTP_PORT >/dev/null 2>&1; then
        log "HTTP server is responding on port $HTTP_PORT"
        return 0
    else
        error "HTTP server not responding (may not be running)"
        return 1
    fi
}

# Clean log file
clean_log() {
    log "Clearing server.log..."
    > "$LOG_FILE"
    log "server.log cleared"
}

# Clean database
clean_db() {
    warn "This will delete all captured data!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        rm -f "$PROJECT_DIR/rdp_server.db"
        rm -f "$PROJECT_DIR/logs"/*_report.txt
        log "Database and reports cleaned"
    else
        log "Cancelled"
    fi
}

# Show help
show_help() {
    cat << EOF
${BLUE}RDP Honeypot Test Runner${NC}

Usage: $0 <command> [options]

Core Commands:
  start       - Kill old processes and start server (default)
  stop        - Kill all RDP honeypot processes
  restart     - Stop and start server
  status      - Check if server is running
  logs        - Tail server logs (Ctrl+C to stop)
  
Database Commands:
  db-query    - Show last 30 captured credentials
  db-report   - Show all hourly reports
  
Maintenance Commands:
  clean-log   - Clear server.log (run before testing)
  clean-db    - Delete database and all reports
  
Diagnostic Commands:
  test-http   - Test HTTP health endpoint
  
Other:
  help        - Show this help message

Examples:
  # Start server and follow logs
  $0 start

  # In another terminal, check credentials
  $0 db-query

  # View hourly summary
  $0 db-report

  # After testing, clean log for next run
  $0 clean-log

${YELLOW}Note: Always start in one console ("buddy") and read server.log to debug.${NC}
EOF
}

# Parse arguments
case "${1:-start}" in
    start)
        cleanup
        start_server
        show_logs
        ;;
    stop)
        cleanup
        ;;
    restart)
        cleanup
        start_server
        ;;
    status)
        check_status
        ;;
    logs)
        show_logs
        ;;
    db-query)
        query_db
        ;;
    db-report)
        show_reports
        ;;
    test-http)
        test_http
        ;;
    clean-log)
        clean_log
        ;;
    clean-db)
        clean_db
        ;;
    help)
        show_help
        ;;
    *)
        error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
