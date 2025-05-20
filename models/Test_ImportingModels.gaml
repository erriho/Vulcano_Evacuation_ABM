model TestImportingModels

/*
 * This model is intended to show how to import existing code 
 * 
 */

import "world/VulcanoMap.gaml"

experiment show_map type: gui {     
    output {
	    display vulcano_map type: 3d{
	       species Island refresh: false;
	       species Roads refresh: false;
	       species Ferry_Route refresh: false;
	    }
	}
}