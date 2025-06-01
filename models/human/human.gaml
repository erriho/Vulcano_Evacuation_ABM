/**
* Name: sociallinks
* Based on the internal empty template. 
* Author: irenesilvestro
* Tags: 
*/


model sociallinks

/* Insert your model definition here */




global {
    // Global variables related to the Management units 
    
    
	file island_shp <- file("../../includes/Shapefiles/Island/Vulcano_Island.shp");
	file road_shp <- file("../../includes/Shapefiles/Roads/Vulcano_Roads_and_Paths_United_Cleaned.shp");
	file Milazzo_route_shp <- file("../../includes/Shapefiles/Ferry_Routes/Vulcano_Milazzo.shp");
	file buildings_shp <- file("../../includes/Shapefiles/Buildings/Vulcano_Buildings.shp");
	
    //file island_shp <- file("/Users/irenesilvestro/Desktop/quinto anno uni/econofisica/Vulcano_Evacuation_ABM/includes/Shapefiles/Island/Vulcano_Island.shp");
    
	//file island_shp <- file("../includes/Shapefiles/Island/Vulcano_Island.shp");
	//file road_shp <- file("/Users/irenesilvestro/Desktop/quinto anno uni/econofisica/Vulcano_Evacuation_ABM/includes/Shapefiles/Roads/Vulcano_Roads.shp");
	//file Milazzo_route_shp <- file("/Users/irenesilvestro/Desktop/quinto anno uni/econofisica/Vulcano_Evacuation_ABM/includes/Shapefiles/Ferry_Routes/Vulcano_Milazzo.shp");
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
	        
	    create Island from: island_shp;
	    	
	    create Roads from: road_shp where (each != nil);
	    
	    create Ferry_Route from: Milazzo_route_shp where (each != nil);
	    
	    create Buildings from: buildings_shp;
	    
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

    	create people number: 200 {
    	
     
			location <- any_location_in(one_of(Roads));
			
     	 	do add_desire(at_target);//gli aggiunge desiderio di raggiungere target 
			//la priorità di quella sopra non sembrerebbe esser fissata
			
			
			target <- one_of(shelter).location;
			//target <- shared_target;
      		//target <- any_location_in(one_of(Roads)); // inizializzazione diretta del target
	
    	}
    	
    	
      	road_network <- as_edge_graph(Roads); 
    }
    
    
	reflex display_social_links  when: every(1#cycle) {
		//tempPeople è l'agente che sta guardando i suoi legami sociali 
		loop tempPeople over: people{
			//tempDestination sarebbe l'agente a cui è legato che infatti sta nellla sua base sociale 
				loop tempDestination over: tempPeople.social_link_base{
					//social_link_base dovrebbe essere qualcosa di automatico dell'archietettura sociale dell'agete che infatti deve essere attivata
					if (tempDestination !=nil){
						bool exists<-false; //variabile per indicare che collegamento è gia stato creato 
						//se esiste gia un link allora metti exist su true
						loop tempLink over: socialLinkRepresentation{
							if((tempLink.origin=tempPeople) and (tempLink.destination=tempDestination.agent)){
								exists<-true;
							}
						}
						//se non esiste il link tra agente di origine e agente di destinzaione 
						if(not exists){
							create socialLinkRepresentation number: 1{
								origin <- tempPeople;
								destination <- tempDestination.agent;
								if(get_liking(tempDestination)>0){
									color <- #blue;
								} else {
									color <- #red;
								}
								//il link è rosso o blu in base al sentimento sociale di get_link 
								//CAPIRE MEGLIO 
							}
						}
					}
				}
			}
	}

	
    
	//ogni 10 cicli aggiorna il peso delle strade tenendo conto della densità di persone su di esse 
	//o forse in base alla loro lunghezza e alla velocità degli agenti 
	/* 
	reflex update_speeds when: every(10#cycle){
		current_weights <- road as_map (each::each.shape.perimeter / each.speed_coeff);
		road_network <- road_network with_weights current_weights;
	}
	* 
	*/
	//ferma la stimulazione quando non ci sono piu persone (o scappate o morte)
	reflex stop_sim when: empty(people) {
		do pause;
	}
    
}
    

species Island {
	
	aspect default {
		draw shape color: #grey;
	}
} 
/* 

species Roads {
	
	aspect default {
		draw shape color: #black width: 2#meter;
	}
}
* 
*/



species Roads {
	float capacity <- 1 + shape.perimeter/50; //capacita della strada proporzionale a sua lunghezza
	int nb_people <- 0 update: length(people at_distance 1); //numero persone vicine a strada se distanza minore di 1 ??
	float speed_coeff <- 1.0 update:  exp(-nb_people/capacity) min: 0.1; //diminuisce coeff velocita all'aumentare della densita 
	
	aspect default {
		draw shape color: #black;
	}
}

species Ferry_Route {
	
	aspect default {
		draw shape color: #blue width: 2#meter;
	}
}

species Buildings {
    /*int elementId;
    int elementHeight;
    string elementColor;*/
    
    aspect default{
    /*draw shape color: (elementColor = "blue") ? #blue : ( (elementColor = "red") ? #red : #yellow) depth: elementHeight;*/
    draw shape color: rgb(53, 53, 53);
    }
}



species people skills: [moving] control: simple_bdi{
	point target;
	float speed <- 100 #km/#h; //velocita iniziale
	rgb color <- #blue;
	bool escape_mode <- false; //attivo se l'agente sta scappamdo 
	bool fearful; //vero se l'agente reagisce con paura 
	
	float view_dist<-30.0;
	
	int gold_sold;

	//in order to simplify the model we define  4 desires as variables
	//quattro desideri definiti come predicati 
	//andare verso il target o averlo , andare verso rifugio o averlo
	predicate at_target <- new_predicate("at_target"); 
	predicate in_shelter <- new_predicate("shelter");
	predicate has_target <- new_predicate("has target");
	predicate has_shelter <- new_predicate("has shelter");
	
	//we give them as well 2 beliefs as variables
    //due credenze ocme predicati catastrofe o non catastrofe
    //che poi dovrebbe essere un uncertainty 
	predicate catastropheP <- new_predicate("catastrophe");
	predicate nonCatastrophe <- new_predicate("catastrophe",false);
	

	//at last we define 2 emotion linked to the knowledge of the catastrophe
	emotion fearConfirmed <- new_emotion("fear_confirmed",catastropheP);
	//attenzione fear_comfirmed è una emozione effettivametne 
	//vedi che accando alle emozion ici mette la credenza a cui sono associate
	emotion fear <- new_emotion("fear",catastropheP); //all'emozione ci collega una credenza!!
	
	bool noTarget<-true; //serve a controllare se il target è impostato che comunque è regolato in normal_move
	
	bool use_emotions_architecture <- true; //per attivare processo emozionale automatico 
	bool use_social_architecture <- true;
  // Piano di movimento lungo il grafo stradale
  //if the agent perceive that their is something that is not normal (a hazard), it has a probability proba_detect_hazard to suppose (add to its unertainty base) that there is a catastrophe occuring
	//quindi quello che percepisce è hazard e non catastrofe e poi non una certa probabilita aggiunge al suo knowledge base la info , mi sa sotto forma di uncertainty 
	perceive target:hazard in: hazard_distance when: not escape_mode and flip(proba_detect_hazard){
		//quindi percepisce hazard quando non è in modalita scappo e estrae anche una prob per capire se vera incamerata nel knowledge base 
		focus id:"catastrophe" is_uncertain: true; //mette il uncertainty a vero attenzione è incertezza , potrebbe esserci una catastrofe 
		//poi se è nella modalità fearful allora entra nella modalita fuga che è quella dove si switcha anche il valore di escape_mode 
		ask myself {
			if(fearful){
				do to_escape_mode;
			}else{
				color<-#green;
				//si mette in un colore verde  perche comunque ha percepito pericolo ma non ha paura 
			}
		}
	}
	//if the agent perceive the catastrophe, it adds a belief about it and pass in escape mode
	//attenzione percezione della catastrofe che avviene sempre se nel cerchio senza una condizione 
	//qunado percepisce la catastrofe attiva subito la modatita escape_mode 
	//quindi percepire la catastrofe è piu potente di hazard
	perceive target:catastrophe in:catastrophe_distance{
		focus id:"catastrophe"; //qui a differenza di prima sta aggiungendo un belief con prob 1 
		ask myself{
			if(not escape_mode){
				do to_escape_mode;
			}
		}
	}
	

	//CONTAGIO EMOTIVO 
	//if the agent perceives other people agents in their neighborhood that have fear, it can be contaminate by this emotion
	//containati quando percepiscono altre persone nel cerchio e non sono in escape_mode 
	perceive target:people in: other_distance when: not escape_mode {
		//agente prcepito ha fearConfirmed, quando lui ha fear allora acquisisce fearConfirmed
		emotional_contagion emotion_detected:fearConfirmed when: fearful;
		//io non ho paura ma l'agente percepito ha un certo charisma e io ho una certa receptivity, simula il contagio della paura semplice 
		//dovrebe essere automatico
		emotional_contagion emotion_detected:new_emotion("fear") charisma: charisma receptivity:receptivity;
		//agente percepisce fearConfirmed , ma sviluppa solo fear (non era gia impaurito)
		emotional_contagion emotion_detected:fearConfirmed emotion_created:fear;
	}
	//la formula del contagio con carisma e recettivita dovrebbe esserci in ben 
	
	//ci prepariamo al secondo contagio emotivo 
	emotion joy <- nil; //emozione sganciata da un predicato, per ora vuota
	
	//quindi questa si attiverà quando è anche in escape mode
	perceive target:people in: other_distance{
		emotional_contagion emotion_detected: joy;
		//ATTENZIONE si tenta un contagio su emozione joy ma non produce effetto perche è nil pero è pronto per estensioni future 
		emotional_contagion emotion_detected:fearConfirmed emotion_created:fear;
	}
	
	
	perceive target: people in: view_dist {
		socialize liking: 1 -  point(color.red, color.green, color.blue) distance_to point(myself.color.red, myself.color.green, myself.color.blue) / 255;
	}
		
	//queste regole mandano l'agente al rifugio anziche al target quando paura o paura conf o credenza di catastrofe 
	
	//if the agent has a fear confirmed, it has the desire to go to a shelter
	rule emotion:fearConfirmed remove_intention: at_target new_desire:in_shelter strength:5.0;
	
	//if the agent has the belief that there is a a catastrophe,  it has the desire to go to a shelter
	rule belief:new_predicate("catastrophe") remove_intention:at_target new_desire:in_shelter strength:5.0;
	
	rule emotion:new_emotion("fear" ,new_predicate("catastrophe")) new_desire:in_shelter remove_intention:at_target when: fearful strength:5.0;
	
	
	
	//bool noTarget<-true; //serve a controllare se il target è impostato che comunque è regolato in normal_move
	
	plan lets_wander intention: at_target {
		do wander on: road_network ;
	}
	
		action to_escape_mode {
		escape_mode <- true;
		color <- #darkred;
		target <- nil;	
		noTarget <- true;
		do remove_intention(at_target, true);
	}
	
	
	aspect default {
	  draw circle(5) color: color border: #black depth: gold_sold;
	  draw circle(view_dist) color: color border: #black depth: gold_sold wireframe: true;
	}
	
	

		}
		
	
	
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


	
species socialLinkRepresentation{
	people origin; //agente di partenza 
	agent destination; //agente di arrivo 
	rgb color; //colore della linea 
	
	aspect base{
		draw line([origin,destination],50.0) color: color;
	}
}
	
 
 
experiment show_map type: gui {     
	float minimum_cycle_duration <- 0.02; //tempo minimo per ciclo per renderlo fluido ???
	
    output {
	    display vulcano_map type: 3d{
	       species Island refresh: false;
	       species Roads refresh: false;
	       species Ferry_Route refresh: false; 
	       species Buildings refresh: false;
	       species people;
	       species hazard;
	       species catastrophe;
	       species shelter refresh: false;
	      
	       
	    }
	     
		display socialLinks type: 3d{
			species socialLinkRepresentation aspect: base;
		}
	}
}
	
	
	
	
	

 



