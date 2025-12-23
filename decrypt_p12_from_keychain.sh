#!/bin/bash

# P12 Decryption Script
# Extracts certificate and private key from PKCS#12 files exported from Keychain
# Enhanced with explicit X.509 certificate format support

set -euo pipefail  # Exit on any error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to cleanup on exit
cleanup() {
    if [[ -n "${TEMP_FILES:-}" ]]; then
        for temp_file in $TEMP_FILES; do
            if [[ -f "$temp_file" ]]; then
                rm -f "$temp_file"
            fi
        done
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] -f <p12_file>

Options:
  -f, --file FILE        P12 file to decrypt (required)
  -o, --output DIR       Output directory (default: current directory)
  -n, --name PREFIX      Output file name prefix (default: extracted)
  -e, --keep-encrypted   Keep private key encrypted (default: unencrypted)
  -k, --key-format FMT   Private key format: raw, pem (default: raw)
  -x, --cert-format FMT  X.509 certificate format: pem, der, both (default: pem)
  -c, --combined         Create combined PEM file
  -v, --verify           Verify certificate after extraction
  -a, --all-certs        Extract all certificates from the chain
  -t, --text-output      Also output certificate in human-readable text format
  -h, --help             Show this help message

Certificate Formats (X.509):
  pem      - X.509 certificate in PEM format (Base64 encoded with headers) - default
  der      - X.509 certificate in DER format (binary ASN.1 encoding)
  both     - Export certificate in both PEM and DER formats

Key Formats:
  raw      - Raw binary format: PKCS#1 for RSA, X9.63 (04||X||Y||K) for EC - default
  pem      - Standard PEM format (BEGIN/END blocks)

Raw Format Details:
  - RSA keys: PKCS#1 DER-encoded private key
  - EC keys: ANSI X9.63 format (04 || X || Y || K) where:
    * 04 = uncompressed point indicator
    * X, Y = public key coordinates (fixed-width, big-endian)
    * K = private scalar (fixed-width, big-endian)

Examples:
  $0 -f certificate.p12
  $0 -f cert.p12 -o /tmp -n mycert -x both -v
  $0 -f cert.p12 -x der -t  # DER format with text output
  $0 -f cert.p12 -e -x pem  # Keep private key encrypted, PEM certificate
  $0 -f cert.p12 -k pem -x both  # PEM key format, both certificate formats
  $0 -f cert.p12 -a  # Extract all certificates in the chain
EOF
}

# Default values
P12_FILE=""
OUTPUT_DIR="."
NAME_PREFIX="extracted"
KEEP_ENCRYPTED=false
KEY_FORMAT="raw"
CERT_FORMAT="pem"
COMBINED=false
VERIFY=false
ALL_CERTS=false
TEXT_OUTPUT=false
LEGACY_OPT='-legacy'
TEMP_FILES=""
P12_PASSWORD=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            if [[ -z "${2:-}" ]]; then
                print_error "Option $1 requires an argument"
                exit 1
            fi
            P12_FILE="$2"
            shift 2
            ;;
        -o|--output)
            if [[ -z "${2:-}" ]]; then
                print_error "Option $1 requires an argument"
                exit 1
            fi
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -n|--name)
            if [[ -z "${2:-}" ]]; then
                print_error "Option $1 requires an argument"
                exit 1
            fi
            NAME_PREFIX="$2"
            shift 2
            ;;
        -e|--keep-encrypted)
            KEEP_ENCRYPTED=true
            shift
            ;;
        -k|--key-format)
            if [[ -z "${2:-}" ]]; then
                print_error "Option $1 requires an argument"
                exit 1
            fi
            KEY_FORMAT="$2"
            if [[ ! "$KEY_FORMAT" =~ ^(raw|pem)$ ]]; then
                print_error "Invalid key format: $KEY_FORMAT. Valid options: raw, pem"
                exit 1
            fi
            shift 2
            ;;
        -x|--cert-format)
            if [[ -z "${2:-}" ]]; then
                print_error "Option $1 requires an argument"
                exit 1
            fi
            CERT_FORMAT="$2"
            if [[ ! "$CERT_FORMAT" =~ ^(pem|der|both)$ ]]; then
                print_error "Invalid certificate format: $CERT_FORMAT. Valid options: pem, der, both"
                exit 1
            fi
            shift 2
            ;;
        -c|--combined)
            COMBINED=true
            shift
            ;;
        -v|--verify)
            VERIFY=true
            shift
            ;;
        -a|--all-certs)
            ALL_CERTS=true
            shift
            ;;
        -t|--text-output)
            TEXT_OUTPUT=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$P12_FILE" ]]; then
    print_error "P12 file is required. Use -f or --file option."
    show_usage
    exit 1
fi

# Check if P12 file exists and is readable
if [[ ! -f "$P12_FILE" ]]; then
    print_error "P12 file '$P12_FILE' not found."
    exit 1
fi

if [[ ! -r "$P12_FILE" ]]; then
    print_error "P12 file '$P12_FILE' is not readable."
    exit 1
fi

# Check if OpenSSL is available
if ! command -v openssl &> /dev/null; then
    print_error "OpenSSL is not installed or not in PATH."
    exit 1
fi

# Validate name prefix (no path separators)
if [[ "$NAME_PREFIX" =~ [/\\] ]]; then
    print_error "Name prefix cannot contain path separators."
    exit 1
fi

# Create output directory if it doesn't exist
if [[ ! -d "$OUTPUT_DIR" ]]; then
    print_info "Creating output directory: $OUTPUT_DIR"
    if ! mkdir -p "$OUTPUT_DIR"; then
        print_error "Failed to create output directory: $OUTPUT_DIR"
        exit 1
    fi
fi

# Check if output directory is writable
if [[ ! -w "$OUTPUT_DIR" ]]; then
    print_error "Output directory '$OUTPUT_DIR' is not writable."
    exit 1
fi

# Define output file paths
CERT_PEM_FILE="$OUTPUT_DIR/${NAME_PREFIX}_certificate.crt"
CERT_DER_FILE="$OUTPUT_DIR/${NAME_PREFIX}_certificate.der"
CERT_TEXT_FILE="$OUTPUT_DIR/${NAME_PREFIX}_certificate.txt"
CA_CERT_FILE="$OUTPUT_DIR/${NAME_PREFIX}_ca_certificates.crt"

if [[ "$KEEP_ENCRYPTED" == true ]]; then
    KEY_FILE="$OUTPUT_DIR/${NAME_PREFIX}_private_key_encrypted.pem"
elif [[ "$KEY_FORMAT" == "raw" ]]; then
    KEY_FILE="$OUTPUT_DIR/${NAME_PREFIX}_private_key.bin"
else
    KEY_FILE="$OUTPUT_DIR/${NAME_PREFIX}_private_key.pem"
fi
COMBINED_FILE="$OUTPUT_DIR/${NAME_PREFIX}_combined.pem"

# Check for existing files and warn user
existing_files=()
for file in "$CERT_PEM_FILE" "$CERT_DER_FILE" "$CERT_TEXT_FILE" "$CA_CERT_FILE" "$KEY_FILE" "$COMBINED_FILE"; do
    if [[ -f "$file" ]]; then
        existing_files+=("$file")
    fi
done

if [[ ${#existing_files[@]} -gt 0 ]]; then
    print_warning "The following files will be overwritten:"
    for file in "${existing_files[@]}"; do
        echo "  $file"
    done
    echo -n "Continue? [y/N]: "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "Operation cancelled."
        exit 0
    fi
fi

print_info "Starting P12 decryption process..."
print_info "Input file: $P12_FILE"
print_info "Output directory: $OUTPUT_DIR"
print_info "Certificate format: $CERT_FORMAT (X.509)"
print_info "Private key format: $KEY_FORMAT"
if [[ "$KEEP_ENCRYPTED" == true ]]; then
    print_info "Private key will remain encrypted"
else
    print_info "Private key will be exported unencrypted"
fi
if [[ "$ALL_CERTS" == true ]]; then
    print_info "All certificates in chain will be extracted"
fi

# Function to extract X.509 certificates
extract_certificates() {
    print_info "Extracting X.509 certificates..."
    local temp_cert=$(mktemp)
    TEMP_FILES="$TEMP_FILES $temp_cert"
    
    if [[ "$ALL_CERTS" == true ]]; then
        # Extract all certificates (including CA certificates)
        local temp_all_certs=$(mktemp)
        local temp_ca_certs=$(mktemp)
        TEMP_FILES="$TEMP_FILES $temp_all_certs $temp_ca_certs"
        
        # Extract client certificate
        if openssl pkcs12 $LEGACY_OPT -in "$P12_FILE" -clcerts -nokeys -out "$temp_cert" -passin pass:"$P12_PASSWORD"; then
            if grep -q "BEGIN CERTIFICATE" "$temp_cert"; then
                sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' "$temp_cert" > "$temp_all_certs"
                print_success "Client certificate extracted"
            else
                print_warning "No client certificate found in P12 file."
            fi
        else
            print_error "Failed to extract client certificate."
            exit 1
        fi
        
        # Extract CA certificates
        if openssl pkcs12 $LEGACY_OPT -in "$P12_FILE" -cacerts -nokeys -out "$temp_ca_certs" -passin pass:"$P12_PASSWORD" 2>/dev/null; then
            if grep -q "BEGIN CERTIFICATE" "$temp_ca_certs"; then
                sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' "$temp_ca_certs" >> "$temp_all_certs"
                # Also save CA certificates separately
                sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' "$temp_ca_certs" > "$CA_CERT_FILE"
                chmod 644 "$CA_CERT_FILE"
                print_success "CA certificates extracted to: $CA_CERT_FILE"
            else
                print_info "No CA certificates found in P12 file."
            fi
        fi
        
        # Use the combined certificates as the main certificate file
        if [[ -s "$temp_all_certs" ]]; then
            cp "$temp_all_certs" "$temp_cert"
        fi
    else
        # Extract only the client certificate
        if openssl pkcs12 $LEGACY_OPT -in "$P12_FILE" -clcerts -nokeys -out "$temp_cert" -passin pass:"$P12_PASSWORD"; then
            if ! grep -q "BEGIN CERTIFICATE" "$temp_cert"; then
                print_error "No certificate found in P12 file."
                exit 1
            fi
        else
            print_error "Failed to extract certificate. Check your password and P12 file."
            exit 1
        fi
    fi
    
    # Clean up and save in requested format(s)
    sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' "$temp_cert" > "$CERT_PEM_FILE"
    chmod 644 "$CERT_PEM_FILE"
    
    case "$CERT_FORMAT" in
        pem)
            print_success "X.509 certificate extracted in PEM format: $CERT_PEM_FILE"
            ;;
        der)
            convert_cert_to_der
            rm -f "$CERT_PEM_FILE"  # Remove PEM file if only DER requested
            ;;
        both)
            print_success "X.509 certificate extracted in PEM format: $CERT_PEM_FILE"
            convert_cert_to_der
            ;;
    esac
    
    # Generate text output if requested
    if [[ "$TEXT_OUTPUT" == true ]]; then
        generate_cert_text_output
    fi
}

# Function to convert certificate to DER format
convert_cert_to_der() {
    print_info "Converting X.509 certificate to DER format..."
    if openssl x509 -in "$CERT_PEM_FILE" -outform DER -out "$CERT_DER_FILE"; then
        chmod 644 "$CERT_DER_FILE"
        print_success "X.509 certificate in DER format: $CERT_DER_FILE"
    else
        print_error "Failed to convert certificate to DER format."
        exit 1
    fi
}

# Function to generate human-readable text output of certificate
generate_cert_text_output() {
    print_info "Generating human-readable X.509 certificate text..."
    if openssl x509 -in "$CERT_PEM_FILE" -text -noout > "$CERT_TEXT_FILE"; then
        chmod 644 "$CERT_TEXT_FILE"
        print_success "X.509 certificate text output: $CERT_TEXT_FILE"
    else
        print_error "Failed to generate certificate text output."
        exit 1
    fi
}

# Function to extract private key
extract_private_key() {
    print_info "Extracting private key..."
    local temp_key=$(mktemp)
    local temp_converted=$(mktemp)
    TEMP_FILES="$TEMP_FILES $temp_key $temp_converted"
    
    if [[ "$KEEP_ENCRYPTED" == true ]]; then
        if openssl pkcs12 $LEGACY_OPT -in "$P12_FILE" -nocerts -out "$temp_key" -passin pass:"$P12_PASSWORD"; then
            # Remove extra text and keep only the key
            if grep -q "BEGIN.*PRIVATE KEY" "$temp_key"; then
                sed -n '/BEGIN.*PRIVATE KEY/,/END.*PRIVATE KEY/p' "$temp_key" > "$temp_converted"
                cp "$temp_converted" "$KEY_FILE"
                chmod 600 "$KEY_FILE"
                print_success "Encrypted private key extracted to: $KEY_FILE"
            else
                print_error "No private key found in P12 file."
                exit 1
            fi
        else
            print_error "Failed to extract private key. Check your password and P12 file."
            exit 1
        fi
    else
        # Extract unencrypted private key and convert to desired format
        if openssl pkcs12 $LEGACY_OPT -in "$P12_FILE" -nocerts -nodes -out "$temp_key" -passin pass:"$P12_PASSWORD"; then
            # Remove extra text and keep only the key
            if grep -q "BEGIN.*PRIVATE KEY" "$temp_key"; then
                sed -n '/BEGIN.*PRIVATE KEY/,/END.*PRIVATE KEY/p' "$temp_key" > "$temp_converted"
                
                # Convert to desired format
                convert_key_format "$temp_converted" "$KEY_FILE"
                chmod 600 "$KEY_FILE"
                print_success "Unencrypted private key extracted to: $KEY_FILE (format: $KEY_FORMAT)"
                if [[ "$KEY_FORMAT" == "raw" ]]; then
                    print_warning "Private key is in raw binary format. Handle with appropriate tools."
                else
                    print_warning "Private key is unencrypted. Keep it secure!"
                fi
            else
                print_error "No private key found in P12 file."
                exit 1
            fi
        else
            print_error "Failed to extract private key. Check your password and P12 file."
            exit 1
        fi
    fi
}

# Function to convert private key to specified format
convert_key_format() {
    local input_file="$1"
    local output_file="$2"
    
    if [[ "$KEY_FORMAT" == "pem" ]]; then
        # Keep as PEM format
        cp "$input_file" "$output_file"
        print_info "Exported in PEM format"
        return
    fi
    
    # For raw format, we need to determine key type and convert appropriately
    local temp_der=$(mktemp)
    TEMP_FILES="$TEMP_FILES $temp_der"
    
    # First, convert PEM to DER to work with binary data
    if openssl pkey -in "$input_file" -outform DER -out "$temp_der" 2>/dev/null; then
        # Check if it's an RSA key
        if openssl rsa -in "$input_file" -noout 2>/dev/null; then
            print_info "Detected RSA key, converting to PKCS#1 DER format"
            # Convert to PKCS#1 DER format for RSA
            if openssl rsa -in "$input_file" -outform DER -out "$output_file" 2>/dev/null; then
                print_success "RSA key exported in PKCS#1 DER format"
            else
                print_error "Failed to convert RSA key to PKCS#1 DER format"
                exit 1
            fi
        # Check if it's an EC key
        elif openssl ec -in "$input_file" -noout 2>/dev/null; then
            print_info "Detected EC key, converting to X9.63 format"
            convert_ec_to_x963 "$input_file" "$output_file"
        else
            print_error "Unknown key type, cannot convert to raw format"
            exit 1
        fi
    else
        print_error "Failed to process private key"
        exit 1
    fi
}

# Function to convert EC key to X9.63 format (04 || X || Y || K)
convert_ec_to_x963() {
    local input_file="$1"
    local output_file="$2"
    local temp_pubkey=$(mktemp)
    local temp_privkey_hex=$(mktemp)
    local temp_pubkey_hex=$(mktemp)
    TEMP_FILES="$TEMP_FILES $temp_pubkey $temp_privkey_hex $temp_pubkey_hex"
    
    # Extract the public key in uncompressed format
    if ! openssl ec -in "$input_file" -pubout -conv_form uncompressed -outform DER -out "$temp_pubkey" 2>/dev/null; then
        print_error "Failed to extract public key from EC private key"
        exit 1
    fi
    
    # Get the curve name to determine field size
    local curve_name
    curve_name=$(openssl ec -in "$input_file" -text -noout 2>/dev/null | grep "ASN1 OID:" | sed 's/.*ASN1 OID: //' | tr -d ' ')
    
    if [[ -z "$curve_name" ]]; then
        print_error "Could not determine EC curve"
        exit 1
    fi
    
    # Determine field size based on curve
    local field_size
    case "$curve_name" in
        prime256v1|secp256r1)
            field_size=32
            ;;
        secp384r1)
            field_size=48
            ;;
        secp521r1)
            field_size=66
            ;;
        *)
            print_warning "Unknown curve $curve_name, attempting to determine field size"
            # Try to determine field size from public key length
            local pubkey_size
            pubkey_size=$(stat -f%z "$temp_pubkey" 2>/dev/null || stat -c%s "$temp_pubkey" 2>/dev/null)
            # DER public key has some overhead, subtract it
            field_size=$(( (pubkey_size - 26) / 2 ))
            ;;
    esac
    
    print_info "Using curve: $curve_name, field size: $field_size bytes"
    
    # Extract the private scalar
    local private_scalar
    private_scalar=$(openssl ec -in "$input_file" -text -noout 2>/dev/null | grep -A 10 "priv:" | grep -E "^[[:space:]]*[0-9a-f]" | sed 's/[^0-9a-f]//g' | tr -d '\n')
    
    if [[ -z "$private_scalar" ]]; then
        print_error "Could not extract private scalar from EC key"
        exit 1
    fi
    
    # Extract public key coordinates from DER format
    # Skip the DER header and extract the uncompressed point
    local pubkey_hex
    pubkey_hex=$(xxd -p -c 256 "$temp_pubkey" | tr -d '\n' | sed 's/.*04/04/')
    
    if [[ ! "$pubkey_hex" =~ ^04[0-9a-f]+$ ]]; then
        print_error "Could not extract public key coordinates"
        exit 1
    fi
    
    # Ensure private scalar is the correct length (pad with leading zeros if needed)
    local padded_private_scalar
    padded_private_scalar=$(printf "%0*s" $((field_size * 2)) "$private_scalar")
    
    # Create X9.63 format: 04 || X || Y || K
    local x963_hex="${pubkey_hex}${padded_private_scalar}"
    
    # Convert hex to binary
    echo "$x963_hex" | xxd -r -p > "$output_file"
    
    print_success "EC key exported in X9.63 format (04||X||Y||K)"
    print_info "Format: 04(1) || X($field_size) || Y($field_size) || K($field_size) bytes"
}

# Function to create combined PEM file
create_combined() {
    print_info "Creating combined PEM file with X.509 certificate..."
    local temp_combined=$(mktemp)
    local temp_key_for_combined=$(mktemp)
    TEMP_FILES="$TEMP_FILES $temp_combined $temp_key_for_combined"
    
    # Always use PEM format certificate for combined file
    if [[ ! -f "$CERT_PEM_FILE" ]]; then
        # If we only have DER format, convert back to PEM for combined file
        if [[ -f "$CERT_DER_FILE" ]]; then
            print_info "Converting DER certificate back to PEM for combined file"
            openssl x509 -in "$CERT_DER_FILE" -inform DER -outform PEM -out "$CERT_PEM_FILE"
        else
            print_error "No certificate file available for combined PEM"
            exit 1
        fi
    fi
    
    if [[ "$KEEP_ENCRYPTED" == true ]]; then
        if openssl pkcs12 $LEGACY_OPT -in "$P12_FILE" -out "$temp_combined" -passin pass:"$P12_PASSWORD"; then
            # Clean up the combined file - remove extra text
            if grep -q "BEGIN CERTIFICATE\|BEGIN.*PRIVATE KEY" "$temp_combined"; then
                sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p; /BEGIN.*PRIVATE KEY/,/END.*PRIVATE KEY/p' "$temp_combined" > "$COMBINED_FILE"
                chmod 600 "$COMBINED_FILE"
                print_success "Combined PEM file with X.509 certificate created: $COMBINED_FILE"
            else
                print_error "No certificate or private key found in P12 file."
                exit 1
            fi
        else
            print_error "Failed to create combined PEM file."
            exit 1
        fi
    else
        # Create combined file with X.509 certificate and unencrypted private key
        cp "$CERT_PEM_FILE" "$COMBINED_FILE"
        
        # For combined files, always use PEM format for compatibility
        if [[ "$KEY_FORMAT" == "raw" ]]; then
            print_info "Using PEM format for private key in combined file (raw format not suitable for combined PEM)"
            # Extract private key in PEM format for combined file
            local temp_pem_key=$(mktemp)
            TEMP_FILES="$TEMP_FILES $temp_pem_key"
            
            if openssl pkcs12 $LEGACY_OPT -in "$P12_FILE" -nocerts -nodes -out "$temp_pem_key" -passin pass:"$P12_PASSWORD"; then
                sed -n '/BEGIN.*PRIVATE KEY/,/END.*PRIVATE KEY/p' "$temp_pem_key" >> "$COMBINED_FILE"
            else
                print_error "Failed to extract private key for combined file"
                exit 1
            fi
        else
            # Private key is already in PEM format
            cat "$KEY_FILE" >> "$COMBINED_FILE"
        fi
        
        chmod 600 "$COMBINED_FILE"
        print_success "Combined PEM file with X.509 certificate created: $COMBINED_FILE"
        print_warning "Combined file contains unencrypted private key. Keep it secure!"
    fi
}

# Function to verify X.509 certificate
verify_certificate() {
    print_info "Verifying extracted X.509 certificate..."
    echo ""
    echo "X.509 Certificate Details:"
    echo "=========================="
    
    # Use PEM file for verification, convert from DER if needed
    local cert_to_verify="$CERT_PEM_FILE"
    if [[ ! -f "$CERT_PEM_FILE" && -f "$CERT_DER_FILE" ]]; then
        local temp_pem_for_verify=$(mktemp)
        TEMP_FILES="$TEMP_FILES $temp_pem_for_verify"
        openssl x509 -in "$CERT_DER_FILE" -inform DER -outform PEM -out "$temp_pem_for_verify"
        cert_to_verify="$temp_pem_for_verify"
    fi
    
    # Check if certificate is valid and display details
    if openssl x509 -in "$cert_to_verify" -text -noout; then
        echo ""
        echo "Certificate Summary:"
        echo "==================="
        openssl x509 -in "$cert_to_verify" -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:|Serial Number:|Public Key Algorithm:|Signature Algorithm:)"
        echo ""
        
        # Check certificate chain if CA certs are available
        if [[ -f "$CA_CERT_FILE" ]]; then
            print_info "Verifying certificate chain..."
            if openssl verify -CAfile "$CA_CERT_FILE" "$cert_to_verify" 2>/dev/null; then
                print_success "Certificate chain verification passed."
            else
                print_warning "Certificate chain verification failed or incomplete."
            fi
        fi
        
        # Check if certificate is expired
        if ! openssl x509 -in "$cert_to_verify" -checkend 0 >/dev/null 2>&1; then
            print_warning "Certificate has expired!"
        else
            print_success "Certificate is valid and not expired."
        fi
        
        # Display X.509 version and extensions
        echo ""
        echo "X.509 Technical Details:"
        echo "======================="
        openssl x509 -in "$cert_to_verify" -text -noout | grep -E "(Version:|X509v3)"
    else
        print_error "Certificate file appears to be corrupted or invalid."
        exit 1
    fi
}

# Function to test P12 file validity and get password
test_p12_file() {
    print_info "Testing P12 file validity..."
    
    # First try with empty password (some P12 files don't have passwords)
    if openssl pkcs12 $LEGACY_OPT -in "$P12_FILE" -noout -passin 'pass:' 2>/dev/null; then
        P12_PASSWORD=""
        print_success "P12 file is valid (no password required)."
        return 0
    fi
    
    # If that fails, prompt for password
    echo -n "Enter P12 file password: "
    read -s P12_PASSWORD
    echo ""
    
    if openssl pkcs12 $LEGACY_OPT -in "$P12_FILE" -noout -passin pass:"$P12_PASSWORD" 2>/dev/null; then
        print_success "P12 file is valid."
        return 0
    else
        print_error "Invalid password or corrupted P12 file."
        exit 1
    fi
}

# Test P12 file first
test_p12_file

# Main extraction process
extract_certificates
extract_private_key

# Optional operations
if [[ "$COMBINED" == true ]]; then
    create_combined
fi

if [[ "$VERIFY" == true ]]; then
    verify_certificate
fi

# Summary
echo ""
print_success "P12 decryption completed successfully!"
echo ""
echo "Generated files:"

# Display certificate files
case "$CERT_FORMAT" in
    pem)
        echo "  X.509 Certificate (PEM): $CERT_PEM_FILE"
        ;;
    der)
        echo "  X.509 Certificate (DER): $CERT_DER_FILE"
        ;;
    both)
        echo "  X.509 Certificate (PEM): $CERT_PEM_FILE"
        echo "  X.509 Certificate (DER): $CERT_DER_FILE"
        ;;
esac

if [[ "$TEXT_OUTPUT" == true ]]; then
    echo "  X.509 Certificate (Text): $CERT_TEXT_FILE"
fi

if [[ "$ALL_CERTS" == true && -f "$CA_CERT_FILE" ]]; then
    echo "  CA Certificates (X.509 PEM): $CA_CERT_FILE"
fi

echo "  Private Key: $KEY_FILE (format: $KEY_FORMAT)"

if [[ "$COMBINED" == true ]]; then
    echo "  Combined PEM (X.509 + Key): $COMBINED_FILE"
fi

echo ""
echo "X.509 Certificate Format Details:"
case "$CERT_FORMAT" in
    pem)
        echo "  - PEM format: Base64-encoded X.509 certificate with BEGIN/END headers"
        echo "  - Standard format for most applications and web servers"
        ;;
    der)
        echo "  - DER format: Binary ASN.1-encoded X.509 certificate"
        echo "  - Compact binary format, often used in Java applications"
        ;;
    both)
        echo "  - PEM format: Base64-encoded X.509 certificate with BEGIN/END headers"
        echo "  - DER format: Binary ASN.1-encoded X.509 certificate"
        echo "  - Both formats provided for maximum compatibility"
        ;;
esac

echo ""
if [[ "$KEEP_ENCRYPTED" == false ]]; then
    print_warning "Security reminders:"
    if [[ "$KEY_FORMAT" == "raw" ]]; then
        echo "  - Private key is exported in RAW BINARY format"
        echo "  - RSA keys: PKCS#1 DER format"
        echo "  - EC keys: X9.63 format (04||X||Y||K)"
        echo "  - Use appropriate tools to handle binary key data"
        echo "  - Keep private keys secure and restrict file permissions (600)"
    else
        echo "  - Private key is exported UNENCRYPTED for easier use"
        echo "  - Keep private keys secure and restrict file permissions (600)"
    fi
    echo "  - X.509 certificates are public and can be shared safely"
    echo "  - Remove temporary files when no longer needed"
    echo "  - Use encrypted storage for sensitive materials"
    echo "  - Consider using a password manager for P12 passwords"
    echo "  - Use -e flag if you need to keep the private key encrypted"
else
    print_warning "Security reminders:"
    echo "  - Keep private keys secure and restrict file permissions"
    echo "  - X.509 certificates are public and can be shared safely"
    echo "  - Remove temporary files when no longer needed"
    echo "  - Use encrypted storage for sensitive materials"
    echo "  - Consider using a password manager for P12 passwords"
fi

echo ""
print_info "X.509 Certificate Usage:"
echo "  - PEM format (.crt, .pem): Apache, Nginx, most Linux applications"
echo "  - DER format (.der, .cer): Windows applications, Java KeyStore"
echo "  - Combined PEM: Applications requiring certificate and key in one file"
echo "  - Text format: Human-readable certificate information and debugging"
