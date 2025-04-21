// ========= INCLUDES =========
// HL2SDK
#include <const.h>
#include <eiface.h>
#include <tier0/icommandline.h>

// Metamod Source
#include <sourcehook/sourcehook_impl.h>

// Plugin
#include "hooks.h"
#include "globals.h"


// ========= HOOK IMPLEMENTATIONS =========
float get_tick_interval() {
    RETURN_META_VALUE(MRES_SUPERCEDE, g_cmdline_tick_interval);
}
