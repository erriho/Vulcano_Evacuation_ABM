/**
* Name: humanvolcano
* Based on the internal empty template. 
* Author: irenesilvestro
* Tags: 
*/


model humanvolcano


global {
    // Global variables related to the Management units 
    
    
	file island_shp <- file("../../includes/Shapefiles/Island/Vulcano_Island.shp");
	file road_shp <- file("../../includes/Shapefiles/Roads/Vulcano_Roads_and_Paths_United_Cleaned.shp");
	file Milazzo_route_shp <- file("../../includes/Shapefiles/Ferry_Routes/Vulcano_Milazzo.shp");
	file buildings_shp <- file("../../includes/Shapefiles/Buildings/Vulcano_Buildings.shp");
	file waiting_areas_shp <- file("../../includes/Shapefiles/WaitingAreas/AreeAttesa.shp");
 	file lafossa_crater_shp <- file("../../includes/Shapefiles/Craters/LaFossaCrater.shp");

 	/* file shapefile_buildings <- file("../includes/Shapefiles/Buildings/Vulcano_Buildings.shp"); */

    //definition of the environment size from the shapefile. 
    //Note that is possible to define it from several files by using: geometry shape <- envelope(envelope(file1) + envelope(file2) + ...);
    geometry shape <- envelope(island_shp);
    graph road_network;
    
    //float hazard_distance <- 400.0; //distanza alla quale un agente puo percepire il pericolo 
	float size <- 0.0 #m;
	float catastrophe_distance <- 100.0; //distanza alla quale agente puo percepire la catastrofe 
	float proba_detect_sound <- 0.7; //probabilità che agente rilevi il pericolo 
	float proba_detect_other_escape <- 0.01; //prob che agente rilevi un'altra fuga di emergenza 
	float other_distance <- 10.0; //distanza  a cui l'agente puo percepire le altre persone 
	point shared_target;
	
	
	
	map roaring_sound_emission_map <- [
		"lambda" :: 1000
	];

	map glob_eruption_engine_params_map <- [
		"RoaringSoundEmission" :: roaring_sound_emission_map
	];
	
    
   
    
    init {
	        
	    create Island from: island_shp;
	    	
	    create Roads from: road_shp where (each != nil);
	    
	    create Ferry_Route from: Milazzo_route_shp where (each != nil);
	    
	    create Buildings from: buildings_shp;
	    
	    create Waiting_Areas from: waiting_areas_shp;
		
		
		
		//shared_target <- one_of(shelter).location;
		//waiting_area_target <-_ any_location_in(one_of(Waiting_Areas));


	        
	    create Crater from: lafossa_crater_shp;
	    
		create Volcano number: 1{
			name <- "LaFossa";
			location <- any_location_in(one_of(Crater)); //location <- {2206.0655580625753,3096.5251492224634};
			activity_level <- 1;
			new_activity_level <- 2;
			eruption_engine_params_map <- glob_eruption_engine_params_map;
		}

    	create people number: 50 {
    	
     
			location <- any_location_in(one_of(Roads));
			
     	 	do add_desire(at_target);
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

	//ferma la stimulazione quando non ci sono piu persone (o scappate o morte)
	reflex stop_sim when: empty(people) {
		do pause;
	}
	
	/* 
	reflex print when: add_emotion(fearConfirmed) {
		write "yee";
	}
	* 
	*/
    
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



/* 
 * species Roads {
	float capacity <- 1 + shape.perimeter/50; //capacita della strada proporzionale a sua lunghezza
	int nb_people <- 0 update: length(people at_distance 1); //numero persone vicine a strada se distanza minore di 1 ??
	float speed_coeff <- 1.0 update:  exp(-nb_people/capacity) min: 0.1; //diminuisce coeff velocita all'aumentare della densita 
	
	aspect default {
		draw shape color: #black;
	}
}

*/

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




species Crater {
	aspect default{
		draw triangle(25) color: #black;
	}
}

species Volcano {
    //initialization variables
    int activity_level; // 0: dormant, 1: unrest, 2: eruption
    string eruption_type; //test: test, 0: phreatic, 1a: effusive, 1b: strombolian, 2a: vulcanian PDC absence, 2b: vulcanian effusive, 3: short-lived sustained explosive, 4: phreatomagmatic
	//optional
	map eruption_engine_params_map <- nil;
	//control
	bool correct_initialization <- false;
	//update ausiliary variables
    int new_activity_level;
    //aspect variables
    rgb color;
    
    reflex check_correct_initialization when: correct_initialization = false {
    	if eruption_engine_params_map = nil {
			if eruption_type in ['0', '1a', '1b', '2a', '2b', '3', '4'] {
				string load_path <- "../includes/json/eruption_default_params/eruption" + eruption_type + ".json";
				//TODO: learn how to load from .json files
				write "Loaded eruption_parameters_map from " + load_path;
			}
			else{
				write "InitializationError: eruption_type missing/not supported. If you want a custom eruption setting, remember to initialize the eruption_engine_params map.";
			}
    	}
    	if eruption_engine_params_map contains_key "RoaringSoundEmission"{
    		create RoaringSoundEmissionManager{
    			name <- "RoaringSoundEmission Manager";
    			self.activity_level <- myself.activity_level;
    			if myself.eruption_engine_params_map["RoaringSoundEmission"] contains_key "location" {myself.location <- myself.eruption_engine_params_map["RoaringSoundEmission"]["location"];}
				else {self.location <- myself.location;}
    			if myself.eruption_engine_params_map["RoaringSoundEmission"] contains_key "delay" {self.delay <- float(myself.eruption_engine_params_map["RoaringSoundEmission"]["delay"]);}
				else {self.delay <- 0.0 #s;}
				if myself.eruption_engine_params_map["RoaringSoundEmission"] contains_key "speed_of_sound" {self.speed_of_sound <- float(myself.eruption_engine_params_map["RoaringSoundEmission"]["speed_of_sound"]);}
				else {speed_of_sound <- 343.3 #m/#s;}
				if myself.eruption_engine_params_map["RoaringSoundEmission"] contains_key "max_duration" {self.max_duration <- float(myself.eruption_engine_params_map["RoaringSoundEmission"]["max_duration"]);}
				else {self.max_duration <- 20.0 #s;}
				if myself.eruption_engine_params_map["RoaringSoundEmission"] contains_key "intensity_distribution" {self.intensity_distribution <- myself.eruption_engine_params_map["RoaringSoundEmission"]["intensity_distribution"];}
				else {self.intensity_distribution <- [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1];}
				if myself.eruption_engine_params_map["RoaringSoundEmission"] contains_key "lambda" {self.lambda <- float(myself.eruption_engine_params_map["RoaringSoundEmission"]["lambda"]);}
				//else if myself.eruption_engine_params_map["RoaringSoundEmission"] contains_key "avg_time" {self.lambda <- 1/float(myself.eruption_engine_params_map["RoaringSoundEmission"]["avg_time"]);}
				else {self.lambda <- 180.0;}
    		}
    	}
		correct_initialization <- true;
		write "Initialization completed.";
    }
    
    reflex check_activity_level {
    	if self.new_activity_level != self.activity_level{do update_eruption_status;}
    }

    action update_eruption_status {
    	if self.new_activity_level = 0 {
    		write "Volcano " + self.name + " is dormant.";
    		self.activity_level <- self.new_activity_level;
    		color <- #green;
    		ask EruptivePhenomenonManager {self.activity_level<-myself.activity_level;}
		}
    	else if self.new_activity_level = 1 {
    		write "Volcano " + self.name + " is unrest.";
    		self.activity_level <- self.new_activity_level;
    		color <- #yellow;
    		ask EruptivePhenomenonManager {self.activity_level<-myself.activity_level;}
		}
    	else if self.new_activity_level = 2 {
    		write "Volcano " + self.name + " is erupting!";
    		self.activity_level <- self.new_activity_level;
    		color <- #red;
        	ask EruptivePhenomenonManager {self.activity_level<-myself.activity_level;}
    	}
	}

    action create_magma_chamber {}

	aspect default{
		draw triangle(50) color: color;
	}
}

species MagmaChamber {}


species EruptivePhenomenonManager {
	float delay;
	bool terminated_delay <- false;
	int activity_level;
	
	reflex manage_delay when: terminated_delay = false {
		if delay = 0.0 {terminated_delay <- true;}
		else {
			delay <- delay - step;
			if delay <= 0.0 {terminated_delay <- true;}
		}
	}
}


species RoaringSoundEmissionManager parent: EruptivePhenomenonManager{
	//generation variables
	float lambda;
	float time_waited <- 0.0 #s;
	float waiting_time <- 0.0 #s;
	bool can_create <- false;
	//phenomenon variables 
	float speed_of_sound;
	float max_duration;
	list intensity_distribution;
	
	reflex pause when: time_waited < waiting_time{
		time_waited <- time_waited + step;
	}
	
	reflex manager when: terminated_delay = true {
		if waiting_time = 0.0 #s {waiting_time <- exp_rnd(lambda) #s;}
		if time_waited >= waiting_time {can_create <- true; waiting_time <- 0.0 #s;}
		if can_create = true {
			create RoaringSoundEmission {
				location <- myself.location;
				activity_level <- myself.activity_level;
				speed_of_sound <- myself.speed_of_sound;
				max_duration <- myself.max_duration;
				intensity_distribution <- myself.intensity_distribution;
				self.should_initialize <- true;
			}
			can_create <- false;
			time_waited <- 0.0 #s;
		}
	}
}

species EruptivePhenomenon {
	int activity_level;
	float duration <- 0.0 #s;
	float max_duration;
	bool should_initialize <-false;
	reflex initialize when: should_initialize = true {should_initialize <- false;}
	
	reflex execute {do update_duration;}
	action update_duration {
		duration <- duration + step;
		if duration > max_duration {do die;}
	}
}


species RoaringSoundEmission parent: EruptivePhenomenon {
	int intensity;
	//float size <- 0.0 #m;
	float speed_of_sound;
	list intensity_distribution;
	
	reflex initialize when: should_initialize = true {
		size <- 0.0;
		intensity <- rnd_choice(intensity_distribution);
		write "Boom!" + " - Intensity: " + string(intensity);
		should_initialize <- false;
	}
	
	reflex execute {
		do update_duration;
		size <- size + speed_of_sound * step;
	}
	
	aspect default{	
		draw circle(size) color: rgb(#blue, 0.1);
	}
}
 


species people skills: [moving] control: simple_bdi{
	point target;
	float speed <- 30 #km/#h; //velocita iniziale
	rgb color <- #blue;
	bool escape_mode <- false; //attivo se l'agente sta scappamdo 
	bool elimination <- false; 
	bool fearful <- true; //vero se l'agente reagisce con paura 
	bool fearful2 <- false;
	bool in_Waiting_Area <- false;
	list decision_ferry_distribution <- [0.01, 0.99];
	bool decided_to_board;
	evacuation_vehicle boarded_vehicle;
	bool boarded <- false;
	int boom_intensity;
	
	float view_dist<-30.0;
	
	int gold_sold;
	
	
    //point waiting_area;
	//waiting_area <- one_of(Waiting_Areas).location;

	//in order to simplify the model we define  4 desires as variables
	//quattro desideri definiti come predicati 
	//andare verso il target o averlo , andare verso rifugio o averlo
	predicate at_target <- new_predicate("at_target"); 
	predicate in_waiting_area <- new_predicate("waiting_area");
	predicate has_target <- new_predicate("has target");
	predicate has_waiting_area <- new_predicate("has waiting area");
	predicate share_information <- new_predicate("share information") ;
	
	
	//we give them as well 2 beliefs as variables
    //due credenze ocme predicati catastrofe o non catastrofe
    //che poi dovrebbe essere un uncertainty 
	predicate catastropheP <- new_predicate("catastrophe");
	predicate nonCatastrophe <- new_predicate("catastrophe",false);
	predicate boomP <- new_predicate("boom");

	//at last we define 2 emotion linked to the knowledge of the catastrophe
	//emotion fearConfirmed <- new_emotion("fear_confirmed",catastropheP);
	
	emotion fearConfirmed <- new_emotion("fear_confirmed");
	//attenzione fear_comfirmed è una emozione effettivametne 
	//vedi che accando alle emozion ici mette la credenza a cui sono associate
	emotion fear <- new_emotion("fear",boomP); //all'emozione ci collega una credenza!!
	//emotion fear <- nil; //all'emozione ci collega una credenza!!
	
	
	bool noTarget<-true; //serve a controllare se il target è impostato che comunque è regolato in normal_move
	
	bool use_emotions_architecture <- true; //per attivare processo emozionale automatico 
	bool use_social_architecture <- true;
  // Piano di movimento lungo il grafo stradale
  //if the agent perceive that their is something that is not normal (a hazard), it has a probability proba_detect_hazard to suppose (add to its unertainty base) that there is a catastrophe occuring
	//quindi quello che percepisce è hazard e non catastrofe e poi non una certa probabilita aggiunge al suo knowledge base la info , mi sa sotto forma di uncertainty 

	perceive target:RoaringSoundEmission in: size when: not escape_mode and flip(proba_detect_sound){
	//perceive target:hazard in: hazard_distance {
		//quindi percepisce hazard quando non è in modalita scappo e estrae anche una prob per capire se vera incamerata nel knowledge base 
		focus id:"boom" ;//mette il uncertainty a vero attenzione è incertezza , potrebbe esserci una catastrofe 
		//poi se è nella modalità fearful allora entra nella modalita fuga che è quella dove si switcha anche il valore di escape_mode 
		ask myself {
			if(fearful){
				do add_desire(predicate:share_information, strength: 5.0);
				do to_escape_mode;
				write self.name + " fear from hazard"; //perche si dovrebbe essere attivata l'emozione con quella credeza
			}else{
				color<-#green;
				do add_desire(predicate:share_information, strength: 5.0);
				//si mette in un colore verde  perche comunque ha percepito pericolo ma non ha paura 
			}
		}
	}

	//CONTAGIO EMOTIVO 
	//if the agent perceives other people agents in their neighborhood that have fear, it can be contaminate by this emotion
	//containati quando percepiscono altre persone nel cerchio e non sono in escape_mode 
	perceive target:people in: other_distance {
		//agente prcepito ha fearConfirmed, quando lui ha fear allora acquisisce fearConfirmed
		//emotional_contagion emotion_detected:fearConfirmed when: fearful;
		//io non ho paura ma l'agente percepito ha un certo charisma e io ho una certa receptivity, simula il contagio della paura semplice 
		//dovrebe essere automatico
		//emotional_contagion emotion_detected:new_emotion("fear") charisma: charisma receptivity:receptivity;
		//agente percepisce fearConfirmed , ma sviluppa solo fear (non era gia impaurito)
		//emotional_contagion emotion_detected:fearConfirmed emotion_created:fear;
		
		emotional_contagion emotion_detected:fear emotion_created:fearConfirmed when: fearful;
		
		/* 
		ask myself{
			write "i";
		}
		* 
		*/

		if (has_emotion(fear)) {
				write self.name + " is joyous";
			}
		
	}
	//la formula del contagio con carisma e recettivita dovrebbe esserci in ben 
	
	//ci prepariamo al secondo contagio emotivo 
	emotion joy <- nil; //emozione sganciata da un predicato, per ora vuota
	
	//quindi questa si attiverà quando è anche in escape mode
	perceive target:people in: other_distance{
		emotional_contagion emotion_detected: joy;
		//ATTENZIONE si tenta un contagio su emozione joy ma non produce effetto perche è nil pero è pronto per estensioni future 
		//emotional_contagion emotion_detected:fearConfirmed emotion_created:fear;
		ask myself {
			if (has_emotion(fear)) {
				write self.name + " fear from contagion 2";
				}
				
				}
	}
	
	
	perceive target: people in: view_dist {
		socialize liking: 1 -  point(color.red, color.green, color.blue) distance_to point(myself.color.red, myself.color.green, myself.color.blue) / 255;
	}
		
	//queste regole mandano l'agente al rifugio anziche al target quando paura o paura conf o credenza di catastrofe 
	
	//if the agent has a fear confirmed, it has the desire to go to a shelter
	
	rule emotion:fearConfirmed remove_intention: at_target new_desire:in_waiting_area strength:5.0;
	
	//if the agent has the belief that there is a a catastrophe,  it has the desire to go to a shelter
	
	rule belief:new_predicate("boom") remove_intention:at_target new_desire:in_waiting_area strength:5.0;
	
	rule emotion:new_emotion("fear" ,new_predicate("boom")) new_desire:in_waiting_area remove_intention:at_target when: fearful strength:5.0;
	
	//rule emotion:new_emotion("fear" ,new_predicate("catastrophe")) new_desire:in_shelter remove_intention:at_target when: fearful strength:5.0;
	
	
	
	//bool noTarget<-true; //serve a controllare se il target è impostato che comunque è regolato in normal_move
	

	
	
		action to_escape_mode {
		escape_mode <- true;
		//color <- #darkred;
		target <- nil;	
		noTarget <- true;
		do remove_intention(at_target, true);
	}
	
	
	
		action decision_to_board {
			
			decided_to_board <-  flip(0.99);
			
	}
	
	reflex on_board when: boarded = true { 
		speed <- boarded_vehicle.speed; 
		location <- boarded_vehicle.location; 
		
	}
	
	
	
		action to_elimination {
		
		elimination <- true;
		do die;
	}
	
	
	
	plan lets_wander intention: at_target {
		do wander on: road_network ;
	}
	
	
	
	
	plan evacuation intention: in_waiting_area {
		
		color <-#darkred;
		if (target = nil or noTarget) {
			target <- (Waiting_Areas with_min_of (each.location distance_to location)).location;
			noTarget <- false;
		}
		else  {
			do goto target: target on: road_network  recompute_path: true;
			if (target = location)  {
				//do die;
				in_Waiting_Area <- true;
				ask EvacuationInfrastructure closest_to(self){
					add item: myself to: people_waiting_list;
			}
				
			}		
		}
	}
	
	

//se ho hazard dico a tutti quelli che precedentemente ho incontrato che c'è il pericolo (in qualche modo implicito)
//l'intention di share information si attiva con una certa forza in ogni caso qunado io percepisco hazard sia che io sia spaventato che no
	plan share_information_to_friends intention: share_information instantaneous: true {
		list<people> my_friends <- list<people>((social_link_base where (each.liking > 0)) collect each.agent);
		loop known_hazard over: get_beliefs_with_name("boom") {
			ask my_friends {
				do add_directly_belief(known_hazard);
				write self.name + " comunicated hazard to :"  ;
			}
		}
		
		do remove_intention(share_information, true); 
	}
	
	
	
	
	
	
	aspect default {
	  draw circle(5) color: color border: #black depth: gold_sold;
	  draw circle(view_dist) color: color border: #black depth: gold_sold wireframe: true;
	}
	
	

		}
		
 

 

species Waiting_Areas {
    /*int elementId;
    int elementHeight;
    string elementColor;*/
    
    aspect default{
    /*draw shape color: (elementColor = "blue") ? #blue : ( (elementColor = "red") ? #red : #yellow) depth: elementHeight;*/
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


species evacuation_vehicle skills: [moving] {
	
}



species EvacuationInfrastructure {
	//fixed infrustructure characteristics
	int max_evacuation_vehicles_capacity;
	int max_people_capacity;
	//dynamic infrustructure characteristics
	int actual_evacuation_vehicles_capacity; //in case the infrastructure suffers a reductions in functionality
	int actual_people_capacity;
	int occupied_evacuation_spots; 
	int people_waiting_nb;
	list<agent> people_waiting_list;
	bool full <- false;
	bool viability <- true;
	//aspect customization
	rgb color;
	rgb std_color;
	rgb full_color <- #red;
	rgb unviable_color <- #black;
	
	reflex check_occupancy {
		if occupied_evacuation_spots >= actual_evacuation_vehicles_capacity {full <- true; color <- full_color;}
		else if occupied_evacuation_spots < actual_evacuation_vehicles_capacity {full <- false; color <- std_color;}
	}
	
	action board_people (float boarding_speed, int people_on_board, agent vehicle, list people_on_board_list){
		/*
		 * OVERVIEW:
		 * The agent Infrastructure is given by the agent Vehicle its boarding speed and the nb of people that are currently on board.
		 * These are used to compute how many people (at maximum) can be boarded in the simulation step.
		 * So, the Infrastructure takes up to the max # of people out of the elemnts in the list people_waiting_list.
		 * It asks each of them if they want to board, if so boarded_people gets increased, the people location is set to mirror the vehicle's one, and their evacuation status is updated. 
		 * 
		 */
		int boarded_people <- 0;
		bool boarding_successful <- false;
		int max_nb_of_people_to_board <- round(boarding_speed*step);
		if max_nb_of_people_to_board < 1 {max_nb_of_people_to_board <- rnd_choice([(1-boarding_speed*step),boarding_speed*step]);}
		/* If the number of people to board in a simulation step is less than 0.5 (meaning it would round down to zero), we don't just stop. 
		 * Instead, we board one person with a probability equal to that fractional value. This ensures continuous progression even with small boarding numbers.
		 */
		if empty(people_waiting_list) = false {
			loop person over: people_waiting_list {
				boarding_successful <- false;
				ask person {
					/* person chooses whether to board*/
					//boarding_successful <- choose_whether_to_board();
					boarding_successful <- true;
				}
				if boarding_successful = true {
					remove item: person from: people_waiting_list; 
					add item: person to: people_on_board_list;
					ask person {
						//self.vehicle_boarded <- vehicle; 
						//self.boarded <- true; //this will activate a reflex in the person agent that make it follow the vehicle
					}
					boarded_people <- boarded_people + 1;
				}				
				if boarded_people = max_nb_of_people_to_board {break;}
				if empty(people_waiting_list) = true {break;}
			}
		}
		people_on_board <- people_on_board + boarded_people;
		return people_on_board;
	}
	
	action unboard_people (float unboarding_speed, int people_on_board, list<agent> people_on_board_list){
		int unboarded_people <- 0;
		int max_nb_of_people_to_unboard <- round(unboarding_speed*step);
		if max_nb_of_people_to_unboard < 1 {max_nb_of_people_to_unboard <- rnd_choice([(1-unboarding_speed*step),unboarding_speed*step]);}
		loop person over: people_on_board_list {
			//TODO: update a global varable containg the number of evacuees
			remove item: person from: people_waiting_list;
			ask person {do die;}
			unboarded_people <- unboarded_people + 1;
			if unboarded_people = max_nb_of_people_to_unboard {break;}
			if empty(people_waiting_list) = true {break;}
		}
		people_on_board <- people_on_board - unboarded_people;
		return people_on_board;
	}
	
	action update_viability_status {
		if viability = true {
			actual_evacuation_vehicles_capacity <- max_evacuation_vehicles_capacity;
			actual_people_capacity <- max_people_capacity;
			color <- std_color;
		}
		if viability = false {
			actual_evacuation_vehicles_capacity <- 0;
			actual_people_capacity <- 0;
			color <- unviable_color;
		}
	}
}

	
 
 
experiment show_map type: gui {     
	float minimum_cycle_duration <- 0.02; //tempo minimo per ciclo per renderlo fluido ???
	
    output {
	    display vulcano_map type: 2d{
	       species Island refresh: false;
	       species Roads refresh: false;
	       species Ferry_Route refresh: false; 
	       species Buildings refresh: false;
	       species Waiting_Areas refresh: false;
	       species people;
	       species Volcano;
	       species RoaringSoundEmission;
	      
	       
	    }
	     
		display socialLinks type: 3d{
			species socialLinkRepresentation aspect: base;
		}
	}
}
	
	
	
	
	

 



