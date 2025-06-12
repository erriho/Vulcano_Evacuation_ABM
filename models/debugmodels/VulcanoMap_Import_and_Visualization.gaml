model MapCreator

import "../world/VulcanoMap.gaml"
 
experiment main type: gui {     
    output {
	    display vulcano_map type: 3d{
	       species Island refresh: false;
	       species Roads refresh: false;
	       species Ferry_Route refresh: false;
	       species Buildings refresh: false; 
	    }
	}
}
