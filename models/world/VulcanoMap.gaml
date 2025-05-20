model VulcanoMap

global {
    // Global variables related to the Management units 
	file island_shp <- file("../includes/Shapefiles/Island/Vulcano_Island.shp");
	file road_shp <- file("../includes/Shapefiles/Roads/Vulcano_Roads.shp");
	file Milazzo_route_shp <- file("../includes/Shapefiles/Ferry_Routes/Vulcano_Milazzo.shp");
 	/* file shapefile_buildings <- file("../includes/Shapefiles/Buildings/Vulcano_Buildings.shp"); */

    //definition of the environment size from the shapefile. 
    //Note that is possible to define it from several files by using: geometry shape <- envelope(envelope(file1) + envelope(file2) + ...);
    geometry shape <- envelope(island_shp);
    	/* - the operator envelope(...) takes a geometry or spatial entity as input and returns its minimum bounding box (envelope) as a geometry of type rectangle
    	 * - geometry shape <- ...: This assigns the resulting rectangular geometry (the envelope) to a variable named shape of type geometry.
    	*/
    
    init {
	    //Creation of Buildings agents from the shapefile (and reading some of the shapefile attributes)
	        
	    create Island from: island_shp;
	    	
	    create Roads from: road_shp where (each != nil);
	    
	    create Ferry_Route from: Milazzo_route_shp where (each != nil);

	    /*create Buildings from: shapefile_buildings
	    	with: [elementId::int(read('full_id')), elementHeight::int(read('Height')), elementColor::string(read('attrForGam'))] ;
		*/
    }
}
    

species Island {
	
	aspect default {
		draw shape color: #grey;
	}
} 

species Roads {
	
	aspect default {
		draw shape color: #black width: 2#meter;
	}
}

species Ferry_Route {
	
	aspect default {
		draw shape color: #blue width: 2#meter;
	}
}

species Buildings {
    int elementId;
    int elementHeight;
    string elementColor;
    
    aspect default{
    draw shape color: (elementColor = "blue") ? #blue : ( (elementColor = "red") ? #red : #yellow) depth: elementHeight;
    }
}
 
