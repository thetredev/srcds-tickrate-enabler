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
    float tickinterval = DEFAULT_TICK_INTERVAL;

    if ( CommandLine()->CheckParm( "-tickrate" ) )
    {
        float tickrate = CommandLine()->ParmValue( "-tickrate", 0 );
        if ( tickrate > 10 )
            tickinterval = 1.0f / tickrate;
    }

    RETURN_META_VALUE(MRES_SUPERCEDE, tickinterval );
}
