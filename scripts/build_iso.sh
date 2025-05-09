#!/usr/bin/env bash
# Ferrari OS Build Script
# Version: 1.0.0 makeki/claude
# Description: Builds a custom Ferrari OS ISO based on Arch Linux

# Strict error handling
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default settings
SKIP_CLEAN=false
VERBOSE=false
DRY_RUN=false
LOG_FILE="build_$(date +%Y%m%d_%H%M%S).log"

# Version information
VERSION="1.0.0"
BUILD_DATE=$(date +"%Y-%m-%d %H:%M:%S")

# Function to display usage information
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Build a Ferrari OS ISO image

Options:
  -h, --help          Show this help message and exit
  -o, --output DIR    Set custom output directory
  -w, --work DIR      Set custom work directory
  -s, --skip-clean    Skip cleaning previous build
  -v, --verbose       Enable verbose output
  -d, --dry-run       Show what would be done without building
  -l, --log FILE      Specify log file (default: $LOG_FILE)
  --version           Show version information

EOF
}

# Function to display version information
show_version() {
    echo "Ferrari OS Build Script v$VERSION"
    echo "Build date: $BUILD_DATE"
}

# Function for logging messages
log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Display to console with color based on level
    case "$level" in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        *)
            echo -e "[${level}] $message"
            ;;
    esac
}

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log "ERROR" "Required command '$1' not found. Please install it and try again."
        exit 1
    fi
}

# Function to check available disk space
check_disk_space() {
    local dir=$1
    local required_mb=$2
    local available_kb=$(df -k "$dir" | tail -1 | awk '{print $4}')
    local available_mb=$((available_kb / 1024))
    
    if [ "$available_mb" -lt "$required_mb" ]; then
        log "ERROR" "Not enough disk space in $dir. Required: ${required_mb}MB, Available: ${available_mb}MB"
        return 1
    fi
    
    log "INFO" "Disk space check passed. Available: ${available_mb}MB"
    return 0
}

# Function to set up directories
setup_directories() {
    log "INFO" "Setting up directories"
    
    # Create directories if they don't exist
    mkdir -p "$PACKAGE_DIR"
    mkdir -p "$CONFIG_DIR/airootfs/usr/local/bin"
    mkdir -p "$CONFIG_DIR/airootfs/usr/share/bash-completion/completions"
    mkdir -p "$CONFIG_DIR/airootfs/etc/profile.d"
    mkdir -p "$CONFIG_DIR/airootfs/etc/systemd/system/basic.target.wants"
    
    if [ "$VERBOSE" = true ]; then
        log "INFO" "Created directory structure"
    fi
}

# Function to set up Ferrari OS specific files
setup_ferrari_files() {
    log "INFO" "Setting up Ferrari OS specific files"
    
    # Make livecd-sound executable
    if [ -f "$CONFIG_DIR/airootfs/usr/local/bin/livecd-sound" ]; then
        chmod +x "$CONFIG_DIR/airootfs/usr/local/bin/livecd-sound"
    else
        log "WARNING" "livecd-sound file not found, skipping..."
    fi
    
    # Create symbolic link for boot sound service
    ln -sf /etc/systemd/system/boot-sound.service "$CONFIG_DIR/airootfs/etc/systemd/system/basic.target.wants/boot-sound.service"
    
    # Create Ferrari OS aliases file
    cat > "$CONFIG_DIR/airootfs/etc/profile.d/pit-aliases.sh" << 'EOL'
# Ferrari OS package manager aliases
alias update='pit -Syu'
alias install='pit -S'
alias remove='pit -R'
alias search='pit -Ss'
alias clean='pit -Sc'
alias info='pit -Si'
alias packages='pit -Q'
EOL
    
    # Set file permissions
    if [ -f "$CONFIG_DIR/airootfs/usr/local/bin/pit" ]; then
        chmod +x "$CONFIG_DIR/airootfs/usr/local/bin/pit"
    else
        log "ERROR" "pit wrapper not found. It needs to be created before running this script."
        exit 1
    fi
    
    if [ -f "$CONFIG_DIR/airootfs/usr/share/bash-completion/completions/pit" ]; then
        chmod 644 "$CONFIG_DIR/airootfs/usr/share/bash-completion/completions/pit"
    else
        log "ERROR" "pit completion file not found. It needs to be created before running this script."
        exit 1
    fi
    
    chmod 644 "$CONFIG_DIR/airootfs/etc/profile.d/pit-aliases.sh"
    
    # Verify permissions on pit
    if [ ! -x "$CONFIG_DIR/airootfs/usr/local/bin/pit" ]; then
        log "ERROR" "pit wrapper is not executable"
        exit 1
    fi
    
    log "INFO" "Ferrari OS specific files set up successfully"
}

# Function to validate package files
validate_package_files() {
    log "INFO" "Validating package files"
    
    REQUIRED_FILES=("base.txt" "desktop.txt" "development.txt" "multimedia.txt")
    MISSING_FILES=()
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$PACKAGE_DIR/$file" ]; then
            MISSING_FILES+=("$file")
        elif [ ! -s "$PACKAGE_DIR/$file" ]; then
            log "WARNING" "Package file $file exists but is empty"
        fi
    done
    
    if [ ${#MISSING_FILES[@]} -ne 0 ]; then
        log "ERROR" "Missing required package files:"
        for file in "${MISSING_FILES[@]}"; do
            log "ERROR" "- $file"
        done
        exit 1
    fi
    
    log "INFO" "All required package files found"
}

# Function to gather packages
gather_packages() {
    log "INFO" "Gathering packages from package lists"
    
    PACKAGES=""
    TOTAL_PACKAGES=0
    
    for file in "${REQUIRED_FILES[@]}"; do
        log "INFO" "Processing file: $file"
        
        # Extract packages, ignoring comments and empty lines
        FILE_PACKAGES=$(grep -v '^#' "$PACKAGE_DIR/$file" | grep -v '^$' | awk '{print $1}' | tr '\n' ' ')
        FILE_PACKAGE_COUNT=$(echo "$FILE_PACKAGES" | wc -w)
        TOTAL_PACKAGES=$((TOTAL_PACKAGES + FILE_PACKAGE_COUNT))
        
        PACKAGES+="$FILE_PACKAGES "
        
        if [ "$VERBOSE" = true ]; then
            log "INFO" "Added $FILE_PACKAGE_COUNT packages from $file"
        fi
    done
    
    log "INFO" "Total packages to install: $TOTAL_PACKAGES"
}

# Function to clean previous build
clean_previous_build() {
    if [ "$SKIP_CLEAN" = true ]; then
        log "INFO" "Skipping cleanup of previous build"
        return
    fi
    
    if [ -d "$WORK_DIR" ]; then
        log "INFO" "Cleaning previous build from $WORK_DIR"
        if [ "$DRY_RUN" = false ]; then
            rm -rf "$WORK_DIR"
        else
            log "INFO" "[DRY RUN] Would remove $WORK_DIR"
        fi
    else
        log "INFO" "No previous build to clean"
    fi
}

# Function to build the ISO
build_iso() {
    log "INFO" "Starting Ferrari OS ISO build"
    
    if [ "$DRY_RUN" = true ]; then
        log "INFO" "[DRY RUN] Would build ISO with these settings:"
        log "INFO" "- Work directory: $WORK_DIR"
        log "INFO" "- Output directory: $OUT_DIR"
        log "INFO" "- Config directory: $CONFIG_DIR"
        log "INFO" "- Package count: $(echo $PACKAGES | wc -w)"
        return 0
    fi
    
    log "INFO" "Building Ferrari OS ISO..."
    
    # Add version information to the ISO
    echo "Ferrari OS - Build date: $BUILD_DATE" > "$CONFIG_DIR/airootfs/etc/ferrari-os-version"
    
    # Build the ISO
    if [ "$VERBOSE" = true ]; then
        mkarchiso -v \
            -w "$WORK_DIR" \
            -o "$OUT_DIR" \
            -p "$PACKAGES" \
            "$CONFIG_DIR"
    else
        mkarchiso \
            -w "$WORK_DIR" \
            -o "$OUT_DIR" \
            -p "$PACKAGES" \
            "$CONFIG_DIR" >> "$LOG_FILE" 2>&1
    fi
    
    # Check build result
    if [ $? -eq 0 ]; then
        log "SUCCESS" "Build completed successfully!"
        log "SUCCESS" "ISO location: $OUT_DIR"
        return 0
    else
        log "ERROR" "Build failed! Check $LOG_FILE for details."
        return 1
    fi
}

# Function to handle cleanup on error
cleanup_on_error() {
    log "WARNING" "Build process interrupted. Cleaning up..."
    
    # Save the current state for potential resume
    if [ -d "$WORK_DIR" ]; then
        touch "$WORK_DIR/.incomplete_build"
    fi
    
    exit 1
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -o|--output)
                OUT_DIR="$2"
                shift 2
                ;;
            -w|--work)
                WORK_DIR="$2"
                shift 2
                ;;
            -s|--skip-clean)
                SKIP_CLEAN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            --version)
                show_version
                exit 0
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Directory setup
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ROOT_DIR="$(dirname "$SCRIPT_DIR")"
    CONFIG_DIR="${ROOT_DIR}/configs"
    PACKAGE_DIR="${CONFIG_DIR}/packages"
    
    # Use default directories if not specified
    if [ -z "${WORK_DIR:-}" ]; then
        WORK_DIR="${ROOT_DIR}/work"
    fi
    
    if [ -z "${OUT_DIR:-}" ]; then
        OUT_DIR="${ROOT_DIR}/out"
    fi
    
    # Create output directory if it doesn't exist
    mkdir -p "$OUT_DIR"
    
    # Start logging
    echo "Ferrari OS Build Log - $(date)" > "$LOG_FILE"
    log "INFO" "Starting Ferrari OS build script v$VERSION"
    log "INFO" "Build date: $BUILD_DATE"
    
    # Check for required tools
    check_command "mkarchiso"
    check_command "grep"
    check_command "awk"
    
    # Check disk space (require at least 10GB for work dir and 5GB for output)
    check_disk_space "$(dirname "$WORK_DIR")" 10240 || exit 1
    check_disk_space "$(dirname "$OUT_DIR")" 5120 || exit 1
    
    # Set up trap for cleanup on error
    trap cleanup_on_error INT TERM
    
    # Run build steps
    setup_directories
    setup_ferrari_files
    validate_package_files
    gather_packages
    clean_previous_build
    build_iso
    
    # Return the build result
    return $?
}

# Call main function with all arguments
main "$@"
