
# FreePBX 16 Slow Reload Patch Script

## NOTE:
patch is required to be installed before the script can run 
```
yum install patch -y
```

## Overview
This script is designed to patch specific files in a FreePBX 16 installation to address issues related to slow reloads. It specifically modifies files in the core module, focusing on PJSip class and functions.

## Features
- **Hash Checking**: Ensures the integrity of files before and after patching.
- **Signature Check Toggle**: Allows users to enable or disable signature checks.

## Prerequisites
- A FreePBX 16 installation.
- Shell access to the FreePBX server.

## Usage
1. Upload the script to your FreePBX server.
2. Give executable permissions to the script:
   ```
   chmod +x freepbx16SlowReloadPatch
   ```
3. Run the script:
   ```
   ./freepbx16SlowReloadPatch
   ```

## Script Details
The script operates by checking the hashes of specific files in the FreePBX core module. If the hashes match the expected values, the script applies patches to these files. It also allows users to enable or disable signature checking, which is useful in environments where this level of security is managed differently.

### Important Notes
- Ensure you have a backup of your FreePBX installation before running this script.
- Use this script only if you are experiencing slow reloads in FreePBX 16 and understand the implications of modifying core files.

