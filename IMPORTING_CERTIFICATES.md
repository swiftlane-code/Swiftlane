# Importing Certificates and Keys into Encrypted Certs Repository

This guide describes how to import new certificates and keys into your encrypted certificates repository using the `SwiftlaneCLI certs add` command.

## Prerequisites

1. Build the SwiftlaneCLI tool:
   ```bash
   swift build
   ```

2. Have your encrypted certificates repository URL ready:
   ```bash
   export CODESIGNING_CERTS_REPO_URL="git@github.com:myorg/encrypted-certs.git"
   ```

## Table of Contents

- [Importing App Store Connect API Keys (.p8)](#importing-app-store-connect-api-keys-p8)
- [Importing Code Signing Certificates (.p12)](#importing-code-signing-certificates-p12)
  - [Step 1: Export Certificate from Keychain](#step-1-export-certificate-from-keychain)
  - [Step 2: Decrypt the P12 File](#step-2-decrypt-the-p12-file)
  - [Step 3: Rename Certificate Files](#step-3-rename-certificate-files)
  - [Step 4: Import into Encrypted Repository](#step-4-import-into-encrypted-repository)
  - [Step 5: Clean Up Decrypted Files](#step-5-clean-up-decrypted-files)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Security Notes](#security-notes)

---

## Importing App Store Connect API Keys (.p8)

App Store Connect API keys are simple unencrypted `.p8` files that can be imported directly.

### Command

```bash
CODESIGNING_CERTS_REPO_URL="git@github.com:myorg/encrypted-certs.git" \
  .build/debug/SwiftlaneCLI certs add \
  --cloned-repo-dir $(pwd)/tmp \
  --log-level verbose \
  ~/Downloads/AuthKey_ABCDEFGHIK.p8
```

### What happens:

1. The `.p8` file will be encrypted using your repository password (you'll be prompted to enter it)
2. The encrypted file will be committed to the repository
3. The file will be stored at: `authKeys/AuthKey_ABCDEFGHIK.p8`

**Note:** Use a strong password for your repository encryption. This password will be used to decrypt the files when you need to use them.

---

## Importing Code Signing Certificates (.p12)

Code signing certificates (Development, Distribution, Developer ID Application, etc.) require a few additional steps because they are exported from Keychain as password-protected P12 files.

### Overview

The process involves:
1. Exporting the certificate and private key from Keychain as a `.p12` file
2. Decrypting the P12 file to extract the certificate and private key
3. Renaming the extracted files with meaningful names
4. Importing the files into the encrypted repository
5. Cleaning up the decrypted files (security-critical step)

---

### Step 1: Export Certificate from Keychain

1. Open the **Keychain Access** application
2. Select the **My Certificates** category from the sidebar
3. Find the certificate you want to export
   - Certificates with a private key will show a dropdown arrow ▶
   - Click the arrow to verify the private key is present
4. Right-click on the certificate and select **Export "Certificate Name"**
5. Choose a location to save the `.p12` file
6. **Important:** Enter a secure password when prompted
   - This password encrypts the P12 file during export
   - This is NOT the same password used for the encrypted certificates repository
   - macOS requires a password for P12 export - files exported without a password will be corrupted

**Important: Export one certificate+key pair at a time!**

While Keychain Access allows you to select and export multiple certificates into a single `.p12` file, **DO NOT do this**. The decryption script only supports extracting one certificate-key pair per P12 file. If you export multiple certificates together, only the first pair will be decrypted, and the rest will be lost.

Always export each certificate individually into separate `.p12` files.

**Result:** You now have a `.p12` file containing both the certificate and its private key.

---

### Step 2: Decrypt the P12 File

Before importing into Swiftlane, you need to decrypt the P12 file to extract the certificate and private key separately.

#### Command

```bash
./decrypt_p12_from_keychain.sh \
  -f path/to/your/certandkey.p12 \
  -k pem \
  -x pem \
  -o SIGN \
  -v
```

#### Parameters:
- `-f`: Path to your P12 file
- `-k pem`: Output format for the private key (PEM format)
- `-x pem`: Output format for the certificate (PEM format)
- `-o SIGN`: Output directory (will be created if it doesn't exist)
- `-v`: Verbose output

#### What happens:

The script will:
1. Prompt you for the P12 password (the one you set during export)
2. Extract the certificate and private key
3. Create a `SIGN` directory in your current working directory
4. Save the extracted files:
   ```
   SIGN/
   ├── extracted_private_key.pem
   └── extracted_certificate.crt
   ```

#### Verify extraction:

```bash
find SIGN
```

Expected output:
```
SIGN/extracted_private_key.pem
SIGN/extracted_certificate.crt
```

---

### Step 3: Rename Certificate Files

Give the extracted files meaningful names to help identify them later:

```bash
mv SIGN/extracted_private_key.pem SIGN/my_DeveloperIDApplication.pem
mv SIGN/extracted_certificate.crt SIGN/my_DeveloperIDApplication.crt
```

**Naming suggestions:**
- For Developer ID Application: `DeveloperIDApplication_YourName.pem` / `.crt`
- For Developer ID Installer: `DeveloperIDInstaller_YourName.pem` / `.crt`
- For iOS Distribution: `iOSDistribution_YourCompany.pem` / `.crt`
- For iOS Development: `iOSDevelopment_YourName.pem` / `.crt`

**Note:** The filename is only for your reference. When these files are imported into the keychain later, the filename won't matter - the certificate's actual name comes from its internal metadata.

---

### Step 4: Import into Encrypted Repository

Now import all files in the SIGN directory into your encrypted certificates repository.

#### Verify directory contents:

```bash
ls -al SIGN
```

Expected output:
```
drwxr-xr-x   4 user  staff   128 Nov 26 12:00 .
drwxr-xr-x  20 user  staff   640 Nov 26 12:00 ..
-rw-r--r--   1 user  staff  1234 Nov 26 12:00 my_DeveloperIDApplication.crt
-rw-r--r--   1 user  staff  1679 Nov 26 12:00 my_DeveloperIDApplication.pem
```

#### Import command:

```bash
CODESIGNING_CERTS_REPO_URL="git@github.com:myorg/encrypted-certs.git" \
  .build/debug/SwiftlaneCLI certs add \
  --cloned-repo-dir $(pwd)/tmp \
  --log-level verbose \
  SIGN/*
```

#### What happens:

1. You'll be prompted to enter your repository encryption password
2. All files in the SIGN directory will be encrypted
3. The encrypted files will be committed to the repository
4. The changes will be pushed to the remote repository

#### Success indicators:

Look for these messages in the output:

```
[master 9dc601e] [swiftlane] Imported: my_DeveloperIDApplication.crt, my_DeveloperIDApplication.pem
```

Followed by:

```
git push --set-upstream origin HEAD
```

If you see these messages, everything went smoothly!

---

### Step 5: Clean Up Decrypted Files

**IMPORTANT:** After successful import, you must delete the SIGN directory containing the unencrypted private keys and certificates.

```bash
rm -rf SIGN
```

**Why this is critical:**
- The SIGN directory contains your unencrypted private keys
- Leaving these files on disk is a security risk
- Once imported into the encrypted repository, these files are no longer needed
- Always verify the import was successful (check the git push output) before deleting

---

## Verification

After importing, verify the files are in your repository:

1. Navigate to your encrypted certificates repository on GitHub/GitLab/etc.
2. You should see your newly added files:
   - For `.p8` keys: `authKeys/AuthKey_ABCDEFGHIK.p8`
   - For certificates: The `.crt` and `.pem` files in the `certs` directory

**Important:** The files in the repository will be encrypted. You won't be able to read their contents directly on GitHub - they can only be decrypted using your repository password.

---

## Troubleshooting

- Check the verbose logs (`--log-level verbose`) for detailed error messages

---

## Security Notes

- **Repository Password:** Use a strong, unique password for your encrypted certificates repository. This password protects all certificates and keys stored in the repository.
- **P12 Export Password:** This is temporary and only used during the export/import process. It can be different from your repository password.
- **Never commit unencrypted certificates:** Always use the `SwiftlaneCLI certs add` command to ensure files are encrypted before being committed.
- **Keep your private keys secure:** The decrypted files in the `SIGN` directory contain your private keys. Delete them after successful import.
