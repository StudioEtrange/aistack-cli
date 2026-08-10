#!/bin/bash
AISTACK_CURRENT_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
AISTACK_CURRENT_RUNNING_DIR="$( cd "$( dirname "." )" && pwd )"

# NOTE: do not load stella if it was already loaded in another app
# i.e see launch_test.sh
if [ ! "$1" = "DO_NOT_LOAD_STELLA" ]; then
	STELLA_LOG_STATE="OFF"
	. "${AISTACK_CURRENT_FILE_DIR}/stella-link.sh" include

	# NOTE:
	#   From HERE, $STELLA_ORIGINAL_SYSTEM_PATH contains $PATH before stella features are included
fi



. "${AISTACK_CURRENT_FILE_DIR}/lib/lib.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_json.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_yaml.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_node.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_bun.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_rust.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_python.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_agy.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_cpa.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_vscode.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_gemini.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_opencode.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_och.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_kilo.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_orla.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_bmad.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_gsd.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_adk.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_asm.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_playwright.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_mcp.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_llmfit.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_sktor.sh"
. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_ciss.sh"

aistack_initialize

aistack_runtime_detect
aistack_module_detect
aistack_tool_detect
aistack_mcp_detect

aistack_generic_context_file_generate
aistack_launcher_and_context_files_regenerate
