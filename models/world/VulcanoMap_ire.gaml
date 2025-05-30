model VulcanoMap_ire

global {
    // Global variables related to the Management units 
    file island_shp <- file("/Users/irenesilvestro/Desktop/quinto anno uni/econofisica/Vulcano_Evacuation_ABM/includes/Shapefiles/Island/Vulcano_Island.shp");
    
	//file island_shp <- file("../includes/Shapefiles/Island/Vulcano_Island.shp");
	file road_shp <- file("/Users/irenesilvestro/Desktop/quinto anno uni/econofisica/Vulcano_Evacuation_ABM/includes/Shapefiles/Roads/Vulcano_Roads.shp");
	file Milazzo_route_shp <- file("/Users/irenesilvestro/Desktop/quinto anno uni/econofisica/Vulcano_Evacuation_ABM/includes/Shapefiles/Ferry_Routes/Vulcano_Milazzo.shp");
 	/* file shapefile_buildings <- file("../includes/Shapefiles/Buildings/Vulcano_Buildings.shp"); */

    //definition of the environment size from the shapefile. 
    //Note that is possible to define it from several files by using: geometry shape <- envelope(envelope(file1) + envelope(file2) + ...);
    geometry shape <- envelope(island_shp);
    graph road_network;
    
    float hazard_distance <- 400.0; //distanza alla quale un agente puo percepire il pericolo 
	float catastrophe_distance <- 100.0; //distanza alla quale agente puo percepire la catastrofe 
	float proba_detect_hazard <- 0.2; //probabilità che agente rilevi il pericolo 
	float proba_detect_other_escape <- 0.01; //prob che agente rilevi un'altra fuga di emergenza 
	float other_distance <- 10.0; //distanza  a cui l'agente puo percepire le altre persone 
	point shared_target;
    
    
    	/* - the operator envelope(...) takes a geometry or spatial entity as input and returns its minimum bounding box (envelope) as a geometry of type rectangle
    	 * - geometry shape <- ...: This assigns the resulting rectangular geometry (the envelope) to a variable named shape of type geometry.
    	*/
    
    init {
	    //Creation of Buildings agents from the shapefile (and reading some of the shapefile attributes)
	        
	    create Island from: island_shp;
	    	
	    create Roads from: road_shp where (each != nil);
	    
	    create Ferry_Route from: Milazzo_route_shp where (each != nil);
	    
	    create hazard number: 1 {
			location <- any_location_in(one_of(Roads)); // o un punto fisso se vuoi
    		//radius <- 10.0; // raggio iniziale in metri
		}
		
		

		create catastrophe;
		
		
		create shelter number: 5 {
   			location <- any_location_in(one_of(Roads));
		}
		
		
		/*
		create shelter{
  			location <- {1500.0, 2200.0};
			}
			
			*/
		 
        // Crea il target condiviso come punto casuale su una delle strade
        //shared_target <- any_location_in(one_of(Roads));
        
		// Assegna il target condiviso a un rifugio scelto a caso
		shared_target <- one_of(shelter).location;
		
		//shared_target <- first(shelter).location;
        
		
//quindi la catastrofe pure è un agente

	    /*create Buildings from: shapefile_buildings
	    	with: [elementId::int(read('full_id')), elementHeight::int(read('Height')), elementColor::string(read('attrForGam'))] ;
		*/
		road_network <- as_edge_graph(Roads); //crea un grafo a partire dagli oggetti della specie road
      	
/* 
    	create people number: 200 {
    	
     
			location <- any_location_in(one_of(Roads));
			
			target <- one_of(shelter).location;
			//target <- shared_target;
      		//target <- any_location_in(one_of(Roads)); // inizializzazione diretta del target
	
     	 	do add_desire(at_target);//gli aggiunge desiderio di raggiungere target 
			//la priorità di quella sopra non sembrerebbe esser fissata
			
			
    	}
    	
    	* 
    	*/
    	
    	
      	road_network <- as_edge_graph(Roads); 
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


/* 
species people skills: [moving] control: simple_bdi{
	point target;
	
	rgb color <- #blue;
	predicate at_target <- new_predicate("at_target"); 
	
	bool noTarget<-true; //serve a controllare se il target è impostato che comunque è regolato in normal_move
	
	bool escape_mode <- false; //attivo se l'agente sta scappamdo 
	
  // Piano di movimento lungo il grafo stradale
  
	
	//bool noTarget<-true; //serve a controllare se il target è impostato che comunque è regolato in normal_move
	

    plan normal_move intention: at_target {
        // Usa il target condiviso
        
        if (target = nil) {
            target <- shared_target;  // Assegna il target condiviso se non è ancora impostato
        } else {
            do goto target: target on: road_network recompute_path: false;
            if (target = location) {
                target <- nil;  // Reset del target quando l'agente arriva
                
            }
        }
    }

    
	
	
	
		action to_escape_mode {
		escape_mode <- true;
		color <- #darkred;
		target <- nil;	
		noTarget <- true;
		do remove_intention(at_target, true);
	}
	
	
	

		}
		
		* 
		*/

	
species hazard {
    


    reflex expand {
        hazard_distance <- hazard_distance + 10.0; // espansione graduale ogni tick
    }

    aspect default {
        draw circle(hazard_distance) color: rgb(#gamaorange,0.3) border:#gamaorange depth:5;
    }
}



species catastrophe{
	init{
		location <- first(hazard).location;
	}
	
    reflex expand {
        catastrophe_distance <- catastrophe_distance + 2.0; // espansione graduale ogni tick
    }
	aspect default{
		draw circle(catastrophe_distance) color: rgb(#gamared,0.4) border:#gamared depth:10;
	}
}
 

 
species shelter {
	aspect default {
		draw circle(30) color: rgb(#gamablue,0.8) border: #gamablue depth:10;
	}
}
 
 /* 
 
experiment show_map type: gui {    
	float minimum_cycle_duration <- 0.02; //tempo minimo per ciclo per renderlo fluido ???
	 
    output {
	    display vulcano_map type: 3d{
	       species Island refresh: false;
	       species Roads refresh: false;
	       species Ferry_Route refresh: false; 
	       species people;
	       species hazard;
	       species catastrophe;
	       species shelter refresh: false;
	    }
	}
}
	
	
	
	*/
	

 
