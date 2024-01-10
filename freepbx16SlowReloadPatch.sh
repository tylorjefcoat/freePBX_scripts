#!/bin/bash

####ENABLE OR DISABLE SIGNATURECHECK HERE
# Toggle this variable to true or false to enable or disable signature check
SIGCHECK_DISABLE=true


# Paths and expected hashes
declare -A files_hashes
files_hashes["/var/www/html/admin/modules/core/functions.inc/drivers/PJSip.class.php"]="2d30a362a01b2f122d325997429709e55455ce3fcaf8c22b4fafb0ed05a521d3"
files_hashes["/var/www/html/admin/modules/core/functions.inc.php"]="a9f7d73687b6d7c130b7ead0e103fa78bf31bfb52c9d30969201cd1bb4161a61"

declare -A patched_file_hashes
patched_file_hashes["/var/www/html/admin/modules/core/functions.inc.php"]="bfd00b72fa3952d8db0e8cc5ba966cf06b369c66405a66ffdfc6a9b124cba046"
patched_file_hashes["/var/www/html/admin/modules/core/functions.inc/drivers/PJSip.class.php"]="facbeb9fcffa1b52614a4a14b9cea69c5e7f56aef01478f89acd5d8b3c38e814"

# Minimum required "core" module version
min_core_version="15.0.22.36"

# Function to get the "core" module version
get_core_module_version() {
    local core_version=$(fwconsole ma list | grep "core" | awk '{print $4}')
    echo "$core_version"
}

# Function to apply patch with backup
apply_patch() {
    local file_to_patch="$1"
    echo "Applying patch to $file_to_patch..."

    # Save current directory and change to root directory
    local current_dir="$(pwd)"
    cd /

    # Backup the original file
    local backup_file="$file_to_patch.bak"
    cp "$file_to_patch" "$backup_file"

    if [ "$file_to_patch" == "/var/www/html/admin/modules/core/functions.inc/drivers/PJSip.class.php" ]; then
        # Apply the first patch
        patch "$file_to_patch" << 'EOF'
--- /var/www/html/admin/modules/core/functions.inc/drivers/PJSip.class.php	2024-01-09 12:16:42.193741317 -0600
+++ /var/www/html/admin/modules/core/functions.inc/drivers/PJSip.class.php.update	2024-01-09 12:16:20.693001023 -0600
@@ -24,6 +24,14 @@
 	private $_registration = array();
 	private $_identify = array();
 
+
+//       function logFunctionCall($functionName) {
+//           $backtrace = debug_backtrace();
+//           $caller = $backtrace[1];
+//           $logMessage = "Function '$functionName' called from {$caller['file']} on line {$caller['line']}\n";
+//           file_put_contents('/home/asterisk/debugLog.txt', $logMessage, FILE_APPEND);
+//       }
+       
 	public function __construct($freepbx) {
 		parent::__construct($freepbx);
 		$this->db = $this->database;
@@ -483,6 +491,8 @@
 		}
 		$conf['pjsip.conf']['global'][] = "#include pjsip_custom_post.conf";
 		$trunks = $this->getAllTrunks();
+//		$this->logFunctionCall(__FUNCTION__);
+		$trunkLang = $this->freepbx->Soundlang->getLanguage();
 		foreach($trunks as $trunk) {
 			/**
 			 * Do not write out if disabled.
@@ -639,7 +649,10 @@
 				unset($conf['pjsip.endpoint.conf'][$tn]['send_connected_line']);
 			}
 
-			$lang = !empty($trunk['language']) ? $trunk['language'] : ($this->freepbx->Modules->moduleHasMethod('Soundlang', 'getLanguage') ? $this->freepbx->Soundlang->getLanguage() : "");
+			if(!$trunkLang){$trunkLang = $this->freepbx->Soundlang->getLanguage();};
+//			$lang = !empty($trunk['language']) ? $trunk['language'] : ($this->freepbx->Modules->moduleHasMethod('Soundlang', 'getLanguage') ? $this->freepbx->Soundlang->getLanguage() : "");
+			$lang = !empty($trunk['language']) ? $trunk['language'] : ($this->freepbx->Modules->moduleHasMethod('Soundlang', 'getLanguage') ? $trunkLang : "");
+			
 			if (!empty($lang)) {
 				$conf['pjsip.endpoint.conf'][$tn]['language'] = $lang;
 			}
@@ -1577,6 +1590,7 @@
 	 * Get All Trunks
 	 */
 	public function getAllTrunks() {
+//		$this->logFunctionCall(__FUNCTION__);
 		$get = $this->db->prepare("SELECT id, keyword, data FROM pjsip as tech LEFT OUTER JOIN trunks on (tech.id = trunks.trunkid) OR (tech.id = trunks.trunkid)  where  trunks.disabled = 'off' OR trunks.disabled IS NULL");
 		$get->execute();
 		$result = $get->fetchAll(\PDO::FETCH_ASSOC);
@@ -1779,3 +1793,4 @@
 		}
 	}
 }
+

EOF
    elif [ "$file_to_patch" == "/var/www/html/admin/modules/core/functions.inc.php" ]; then
        # Apply the second patch
        patch "$file_to_patch" << 'EOF'
--- /var/www/html/admin/modules/core/functions.inc.php	2024-01-08 15:00:57.261550931 -0600
+++ /var/www/html/admin/modules/core/functions.inc.php.FIXED	2024-01-08 15:00:25.301446684 -0600
@@ -1759,6 +1759,7 @@
 			$tcustom = 'tcustom';
 			$generate_texten = false;
 			$generate_tcustom = false;
+			$_trunks = null;
 
 			foreach ($trunklist as $trunkprops) {
 				if (trim($trunkprops['disabled']) == 'on') {
@@ -1798,7 +1799,8 @@
 					// fall-through
 					case 'pjsip':
 						$pjsip 		= \FreePBX::Core()->getDriver('pjsip');
-						$_trunks 	= $pjsip->getAllTrunks();
+						
+						if(!$_trunks){$_trunks 	= $pjsip->getAllTrunks();};
 						$tio_hide 	= "no";
 						if(!empty($trunkprops["trunkid"]) && !empty($_trunks[$trunkprops["trunkid"]])){
 							$tio 	= $_trunks[$trunkprops["trunkid"]]["trust_id_outbound"];


EOF
    else
        echo "No patch available for $file_to_patch"
    fi

    # Return to original directory
    cd "$current_dir"
}

RED='\033[0;31m'
BLINK='\033[5m'
NC='\033[0m' # No Color

# Get the current "core" module version
core_version=$(get_core_module_version)

# Check if the script was called with the --IGNOREVERSION flag
ignore_version=false
if [[ "$#" -eq 1 && "$1" == "--IGNOREVERSION" ]]; then
    ignore_version=true
fi

if [[ "$core_version" == "$min_core_version" || "$ignore_version" == "true" ]]; then
    echo "Version check is passed. Applying patches..."
	
	if [ "$SIGCHECK_DISABLE" = true ] ; then 
	   /usr/sbin/fwconsole setting SIGNATURECHECK 0
	fi   
    
    # Checking each file and applying patches...
    for file in "${!files_hashes[@]}"; do
        if [ -f "$file" ]; then
            computed_hash=$(sha256sum "$file" | awk '{ print $1 }')
            expected_hash=${files_hashes[$file]}

            if [ "$computed_hash" = "$expected_hash" ] && [ "${patched_file_hashes[$file]}" != "$computed_hash" ]; then
                echo "File $file has not been molested, continuing...."
                apply_patch "$file"
                patched_file_hashes["$file"]=$computed_hash
            else
                echo "File $file is unknown or already patched. No patch needed."
            fi
        else
            echo "File $file does not exist."
        fi
    done
else
    echo -e "${RED}${BLINK}The current 'core' module version ($core_version) does not match the required version ($min_core_version)."
    echo -e "!!!!RUN AT YOUR OWN RISK!!!!${NC}"
    echo -e "${RED}Use --IGNOREVERSION to bypass${NC}"
    exit 1
fi