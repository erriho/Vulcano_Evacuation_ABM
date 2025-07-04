/**
* Name: humanluglio
* Based on the internal empty template. 
* Author: irenesilvestro
* Tags: 
*/


model human_whole


global {
	//global variables needed to represent the world
	graph road_network;
	graph ferry_network;
	 
	/*
	 * LOADING DATA
	 */
	 //island geodata
	file island_shp <- file("../../includes/Shapefiles/Island/Vulcano_Island.shp");
 	file lafossa_crater_shp <- file("../../includes/Shapefiles/Craters/LaFossaCrater.shp");
	file roads_shp <- file("../../includes/Shapefiles/Roads/Vulcano_Roads_and_Paths_United_Cleaned.shp");
 	file Milazzo_route_shp <- file("../../includes/Shapefiles/Ferry_Routes/FerryRoutes.shp");
 	file buildings_shp <- file("../../includes/Shapefiles/Buildings/Vulcano_Buildings.shp");
 	file waiting_areas_shp <- file("../../includes/Shapefiles/WaitingAreas/AreeAttesa.shp");
    geometry shape <- envelope(island_shp);
    //ports and heliports data
	file ports_shp <- file("../../includes/Shapefiles/Ports/Ports.shp");
	file ports_data <- csv_file("../../includes/csv/Ports.csv");
	matrix ports_data_matrix <- matrix(ports_data);
	file heliports_shp <- file("../../includes/Shapefiles/Heliports/Heliports.shp");
	file heliports_data <- csv_file("../../includes/csv/Heliports.csv");
	matrix heliports_data_matrix <- matrix(heliports_data);
	//TODO: add ferry and heli data
	/* 
	 * PARAMETER INITIALIZIATION
	 */
	 	//volcano
	map glob_eruption_engine_params_map <- [
		"RoaringSoundEmission" :: roaring_sound_emission_map
	];
	map roaring_sound_emission_map <- [
		"lambda" :: 1000
	];
		//people
	float catastrophe_distance <- 100.0; //distanza alla quale agente puo percepire la catastrofe 
	float proba_detect_sound <- 0.7; //probabilità che agente rilevi il pericolo 
	float proba_detect_other_escape <- 0.01; //prob che agente rilevi un'altra fuga di emergenza 
	float other_distance <- 10.0; //distanza  a cui l'agente puo percepire le altre persone 
	point shared_target;
	/*
	 * ASPECT CUSTOMIZATION
	 */
	string font_name <- "Arial";
	
	/*
	 * SIMULATION INITIALIZATION
	 */
	init {
		/*
		 * CREATING THE ISLAND OF VULCANO
		 */
	    create Island from: island_shp;
	    create Crater from: lafossa_crater_shp;
	    create Roads from: roads_shp where (each != nil);
	    create Ferry_Route from: Milazzo_route_shp where (each != nil);
	    create Buildings from: buildings_shp;
	    create Waiting_Areas from: waiting_areas_shp;
		create Port from: ports_shp;
		create Heliport from: heliports_shp;
		// matching ports and heliports to data
		loop port over: Port {
			loop row_index over: range(length(rows_list(ports_data_matrix))-1) {
				if port.name = string(ports_data_matrix[0, row_index]) {
					port.max_EvacuationVehicles_capacity <- int(ports_data_matrix[1, row_index]); 
					port.actual_EvacuationVehicles_capacity <- port.max_EvacuationVehicles_capacity;
					port.max_people_capacity <- int(ports_data_matrix[2, row_index]);
					port.actual_people_capacity <- port.max_people_capacity;
					//write port.name + " - " + port.max_EvacuationVehicles_capacity + " - " + port.max_people_capacity + " - " + port.location; 
				}
			}
			//if port.name = 'Molo di protezione civile di Gelso' {ask port {do die;}}
			//else if port.name = 'Molo di protezione civile di Ponente' {ask port {do die;}}	
		}
		loop heliport over: Heliport {
			loop row_index over: range(length(rows_list(heliports_data_matrix))-1) {
				if heliport.name = string(heliports_data_matrix[0, row_index]) {
					heliport.max_EvacuationVehicles_capacity <- int(heliports_data_matrix[1, row_index]); 
					heliport.actual_EvacuationVehicles_capacity <- heliport.max_EvacuationVehicles_capacity;
					heliport.max_people_capacity <- int(heliports_data_matrix[2, row_index]);
					heliport.actual_people_capacity <- heliport.max_people_capacity;
					//write heliport.name + "-" + heliport.max_EvacuationVehicles_capacity + "-" + heliport.max_people_capacity;
				}
			}
			if heliport.name = 'ZAE Cratere' {ask heliport {do die;}}
		}
	    ferry_network <- as_edge_graph(Ferry_Route);
		road_network <- as_edge_graph(Roads);
		/*
		 * TODO: CREATING PROTEZIONE CIVILE
		 */
		/*
		 * CREATING THE VOLCANO AGENT
		 */
 		create Volcano number: 1{
			name <- "LaFossa";
			location <- any_location_in(one_of(Crater)); //location <- {2206.0655580625753,3096.5251492224634};
			activity_level <- 1;
			eruption_type <- "test";
			new_activity_level <- 2;
			eruption_engine_params_map <- glob_eruption_engine_params_map;
		}
		 /*
		  * TODO: CREATING PEOPLE
		  */
		create People number: 50 {
			//speed <- 30 #km/#h;
			speed <- 3 #km/#h;
			location <- any_location_in(one_of(Roads));
     	 	do add_desire(at_target_port);
    	}
		 /*
		  * TODO: CREATING FORZE ORDINE
		  */
		 /*
		  * CREATING FERRIES AND HELICOPTERS
		  */
		create Ferry number: 1 {
			evacuation_mode <- true;
			ready_to_evacuate <- true;
			safe <- true;
			cruising_speed <- 20 #km/#h;
			speed <- cruising_speed;
			approach_distance <- 1 #km;
			max_waiting_time <- 3000 #s;
			//people_on_board <- 1;
			capacity <- 20;
			location <- any_location_in(one_of(ferry_network.edges));
			loop port over: Port {
				write port.name;
				if port.name = "Porto di Milazzo" {
					hub <- port;
					hub_location <- port.location;
					//target_destination <- port.location;
					write string(self.hub_location) + "-" + port.location;
				}
				if port.name = "Porto di Levante" {	
					target_infrastructure_agent <- port;
					self.target_destination <- port.location;
					//write string(self.target_destination) + "-" + port.location;
				}
			}
		}
	}
}

/*
 * ISLAND AGENTIFICATION
 */
 	//ISLAND
species Island {
	aspect default {
		draw shape color: #grey;
	}
} 
	//CRATER
species Crater {
	aspect default{
		draw triangle(25) color: #black;
	}
}
	//ROADS
species Roads {
	aspect default {
		draw shape color: #black width: 2#meter;
	}
}
	//FERRY ROUTES
species Ferry_Route {
	aspect default {
		draw shape color: #blue width: 2#meter;
	}
}
	//BUILDINGS
species Buildings {
    /*int elementId;
    int elementHeight;
    string elementColor;*/
    aspect default{
    /*draw shape color: (elementColor = "blue") ? #blue : ( (elementColor = "red") ? #red : #yellow) depth: elementHeight;*/
    draw shape color: rgb(53, 53, 53);
    }
}
	//WAITING AREAS
species Waiting_Areas {
    aspect default{
    draw shape color: rgb(153, 153, 153);
    }
}

/*
 * EVACUATION INFRASTRUCTURES: ports, heliports
 */
species EvacuationInfrastructure {
	//fixed infrustructure characteristics
	int max_EvacuationVehicles_capacity;
	int max_people_capacity;
	//dynamic infrustructure characteristics
	int actual_EvacuationVehicles_capacity; //in case the infrastructure suffers a reductions in functionality
	int actual_people_capacity;
	int occupied_evacuation_spots; 
	int people_waiting_nb;
	list<Human> people_waiting_list;
	bool full <- false;
	bool viability <- true;
	//aspect customization
	rgb color;
	rgb std_color;
	rgb full_color <- #red;
	rgb unviable_color <- #black;
	
	reflex check_occupancy {
		//vehicles
		if occupied_evacuation_spots >= actual_EvacuationVehicles_capacity {full <- true; color <- full_color;}
		else if occupied_evacuation_spots < actual_EvacuationVehicles_capacity {full <- false; color <- std_color;}
		//
		people_waiting_nb <- length(people_waiting_list);
	}
	
	action board_people (float boarding_speed, int people_on_board, agent vehicle, list<Human> people_on_board_list){
		/*
		 * OVERVIEW:
		 * The agent Infrastructure is given by the agent Vehicle its boarding speed and the nb of people that are currently on board.
		 * These are used to compute how many people (at maximum) can be boarded in the simulation step.
		 * So, the Infrastructure takes up to the max # of people out of the elemnts in the list people_waiting_list.
		 * It asks each of them if they want to board, if so boarded_people gets increased, the people location is set to mirror the vehicle's one, and their evacuation status is updated. 
		 * 
		 */
		int boarded_people <- 0;
		list<Human> boarded_people_list <- [];
		bool boarding_successful <- false;
		int max_nb_of_people_to_board <- round(boarding_speed*step);
		//if max_nb_of_people_to_board < 1 {max_nb_of_people_to_board <- rnd_choice([(1-boarding_speed*step),boarding_speed*step]);}
		if max_nb_of_people_to_board < 1 {max_nb_of_people_to_board<-1;}
		/* If the number of people to board in a simulation step is less than 0.5 (meaning it would round down to zero), we don't just stop. 
		 * Instead, we board one person with a probability equal to that fractional value. This ensures continuous progression even with small boarding numbers.
		 */
		if empty(people_waiting_list) = false and max_nb_of_people_to_board != 0{
			loop person over: people_waiting_list {
				boarding_successful <- false;
				/* person chooses whether to board*/
				ask person {
					bool decision <- bool(self.choose_whether_to_board());
					boarding_successful <- decision;
				}
				if boarding_successful = true {
					add person to: boarded_people_list;
					boarded_people <- boarded_people + 1;
				}				
				if boarded_people = max_nb_of_people_to_board {break;}
				if (length(people_waiting_list)-boarded_people=0) = true {break;}
			}
			loop person over: boarded_people_list{
				people_waiting_list >- person;
				add item: person to: people_on_board_list;
				ask person {
					self.boarded_vehicle <- EvacuationVehicle(vehicle); 
					self.boarded <- true; //this will activate a reflex in the person agent that make it follow the vehicle
				}
		}
		}
		people_on_board <- people_on_board + boarded_people;
		return people_on_board;
	}
	
	action unboard_people (float unboarding_speed, int people_on_board, list<Human> people_on_board_list){
		int unboarded_people <- 0;
		list<Human> unboarded_people_list <- [];
		int max_nb_of_people_to_unboard <- round(unboarding_speed*step);
		if max_nb_of_people_to_unboard < 1 {max_nb_of_people_to_unboard <- rnd_choice([(1-unboarding_speed*step),unboarding_speed*step]);}
		loop person over: people_on_board_list {
			add person to: unboarded_people_list;
			unboarded_people <- unboarded_people + 1;
			if unboarded_people = max_nb_of_people_to_unboard {break;}
			if (length(people_on_board_list)-unboarded_people=0) = true {break;}
		}
		loop person over: unboarded_people_list{
			remove item: person from: people_on_board_list;
			//TODO: update a global varable containg the number of evacuees
			ask person {do die;}
		}
		people_on_board <- people_on_board - unboarded_people;
		return people_on_board;
	}
	
	action update_viability_status {
		if viability = true {
			actual_EvacuationVehicles_capacity <- max_EvacuationVehicles_capacity;
			actual_people_capacity <- max_people_capacity;
			color <- std_color;
		}
		if viability = false {
			actual_EvacuationVehicles_capacity <- 0;
			actual_people_capacity <- 0;
			color <- unviable_color;
		}
	}
}
	// PORT AGENT
species Port parent: EvacuationInfrastructure {
	rgb color <- #blue;
	rgb std_color <- #blue;
	
	aspect default {
		draw circle(20) color: rgb(color, 0.9);
		if self.name != "Porto di Milazzo" {draw string(string(people_waiting_nb) + "/" + string(actual_people_capacity)) font: font(font_name, 5) color: color;}
	}
}
	//HELIPORT AGENT
species Heliport parent: EvacuationInfrastructure {
	bool lights;
	rgb color <- #orange;
	rgb std_color <- #orange;
	
	aspect default {
		draw circle(20) color: rgb(color, 0.9);
	}
}
/*
 * TODO: PROTEZIONE CIVILE
 */
/*
 * VOLCANO AGENT
 */
 species Volcano {
    //initialization variables
    int activity_level; // 0: dormant, 1: unrest, 2: eruption
    string eruption_type; //test: test, 0: phreatic, 1a: effusive, 1b: strombolian, 2a: vulcanian PDC absence, 2b: vulcanian effusive, 3: short-lived sustained explosive, 4: phreatomagmatic
	//optional variables
	map eruption_engine_params_map <- nil;
	//control variables
	bool correct_initialization <- false;
	//update ausiliary variables
    int new_activity_level;
    //aspect variables
    rgb color;
    /*
     * REFLEXES: initialization, check activity 
     */
	    //INITIALIZATION
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
    	else {if RoaringSoundEmissionManager != nil or RoaringSoundEmissionManager != [] {ask RoaringSoundEmissionManager {do die;}}}
		correct_initialization <- true;
		write "Initialization completed.";
    }
    	//CHECK ACTIVITY
    reflex check_activity_level {
    	if self.new_activity_level != self.activity_level{do update_eruption_status;}
    }
    /* 
     * ACTIONS: update status, create internal structure agents
     */
		//UPDATE STATUS
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
		//CREATE INTERNAL STRUCTURE AGENTS - NOT IMPLEMENTED
    action create_magma_chamber {}
	/* 
	 * ASPECT CUSTOMIZATION
	 */
	aspect default{
		draw triangle(50) color: color;
	}
}
	//INTERNAL STRUCTURE AGENTS
species MagmaChamber {}
	//ERUPTION ENGINE
		//ERUPTIVE PHENOMENA MANAGERS
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
			//ROARING SOUND 
species RoaringSoundEmissionManager parent: EruptivePhenomenonManager{
	//generation variables
	float lambda;
	float time_waited <- 0.0 #s;
	float waiting_time <- 0.0 #s;
	bool can_create <- false;
	//phenomenon variables 
	float speed_of_sound;
	float max_duration;
	list<float> intensity_distribution;
	//reflexes
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
				self.intensity_distribution <- myself.intensity_distribution;
				self.should_initialize <- true;
			}
			can_create <- false;
			time_waited <- 0.0 #s;
		}
	}
}
		//ERUPTIVE PHENOMENA
species EruptivePhenomenon {
	int activity_level;
	float duration <- 0.0 #s;
	float max_duration;
	bool should_initialize <-false;
	//reflexes
	reflex initialize when: should_initialize = true {should_initialize <- false;}
	reflex execute {do update_duration;}
	//actions
	action update_duration {
		duration <- duration + step;
		if duration > max_duration {do die;}
	}
}
			//ROARING SOUND
species RoaringSoundEmission parent: EruptivePhenomenon {
	int intensity;
	float size <- 0.0 #m;
	float speed_of_sound;
	list<float> intensity_distribution;
	list<People> unexposed_people;
	string exposition_model <- "squared";
	//reflexes
	reflex initialize when: should_initialize = true {
		unexposed_people <- agents of_species(species(People));
		size <- 0.0;
		intensity <- rnd_choice(intensity_distribution);
		write "Boom!" + " - Intensity: " + string(intensity);
		should_initialize <- false;
	}
	reflex execute {
		if empty(unexposed_people) = false {
			list<People> exposed_people_temp;
			loop person over: unexposed_people{
				if self distance_to person <= self.size {
					if exposition_model = "squared" {
						if flip(float(intensity^2) / ((length(intensity_distribution))^2)) {
							ask person {
								self.boom_intensity <- myself.intensity;
							}
						}
					}
					//can expand to other exposition models
					add item: person to: exposed_people_temp;
				}		
			}
			loop person over: exposed_people_temp {
				remove item: person from: unexposed_people;
			}
		}
		do update_duration;
		size <- size + speed_of_sound * step;
	}
	//aspect customization
	aspect default{	
		draw circle(size) color: rgb(#blue, 0.1);
	}
}
/*
 * HUMAN SPECIES
 */
 species Human skills: [moving] control: simple_bdi{
	//boarding-related variables
	Port port_to_evacuate_from;
	bool decided_to_board;
	bool waiting_at_port <- false;
	EvacuationVehicle boarded_vehicle <- nil;
	bool boarded <- false;
 	// ISLAND EVACUATION
	predicate at_target_port <- new_predicate("at target port"); 
	predicate in_target_port <- new_predicate("in target port");

	perceive target: port_to_evacuate_from in: 10 #m {
		ask myself{
			do remove_intention(at_target_port, true);
			do add_desire(in_target_port);
		}
	}
	plan go_to_nearest_port intention: at_target_port {
		port_to_evacuate_from <- Port closest_to(self);
		do goto target: port_to_evacuate_from on: road_network;
	}
	
	plan wait_to_board intention: in_target_port {
		if location != port_to_evacuate_from.location {
			do goto target: port_to_evacuate_from on: road_network;
		}
		else {
			if self in port_to_evacuate_from.people_waiting_list = false and boarded_vehicle = nil{
				add self to: port_to_evacuate_from.people_waiting_list;
				write port_to_evacuate_from.name + "-" + port_to_evacuate_from.people_waiting_list;
				waiting_at_port <- true;
			}
		}
	} 
	bool choose_whether_to_board {	
		return flip(0.99);	
	}
	
	reflex on_board when: boarded = true { 
		speed <- boarded_vehicle.speed; 
		location <- boarded_vehicle.location; 
	}
 }
/*
 * PEOPLE
 */
 species People parent: Human{
	point target;
	rgb color <- #blue;
	//bool escape_mode <- false;
	bool fearful <- false; 
	bool in_Waiting_Area <- false;
	float view_dist<-30.0;
	bool high_intensity <- false;
	
	EvacuationInfrastructure evacuation_infrastructure_to_evacuate_from;

	
	
	//volcano-related variables 
	int boom_intensity;
	
	
	predicate share_information <- new_predicate("share information") ;
	
	
	//we give them as well 2 beliefs as variables
    //due credenze ocme predicati catastrofe o non catastrofe
    //che poi dovrebbe essere un uncertainty 
	predicate catastropheP <- new_predicate("catastrophe");
	predicate nonCatastrophe <- new_predicate("catastrophe",false);
	predicate boomP <- new_predicate("boom");
	
	predicate at_nearest_evacuation_infrastructure <- new_predicate("at nearest evacuation infrastructure");
	predicate in_target_evacuation_infrastructure<- new_predicate("in target evacuation infrastructure");


	//at last we define 2 emotion linked to the knowledge of the catastrophe
	//emotion fearConfirmed <- new_emotion("fear_confirmed",catastropheP);
	
	//emotion fearConfirmed <- new_emotion("fear_confirmed");
	//attenzione fear_comfirmed è una emozione effettivametne 
	//vedi che accando alle emozion ici mette la credenza a cui sono associate
	//emotion fear <- new_emotion("fear",boomP); //all'emozione ci collega una credenza!!
	//emotion fear <- nil; //all'emozione ci collega una credenza!!
	
	
	bool noTarget<-true; //serve a controllare se il target è impostato che comunque è regolato in normal_move
	
	bool use_emotions_architecture <- true; //per attivare processo emozionale automatico 
	bool use_social_architecture <- true;
  // Piano di movimento lungo il grafo stradale
  //if the agent perceive that their is something that is not normal (a hazard), it has a probability proba_detect_hazard to suppose (add to its unertainty base) that there is a catastrophe occuring
	//quindi quello che percepisce è hazard e non catastrofe e poi non una certa probabilita aggiunge al suo knowledge base la info , mi sa sotto forma di uncertainty 

	/*
	* perceive target:RoaringSoundEmission in: size when: not escape_mode and flip(proba_detect_sound){
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
	

	//TODO: EMOTIONAL CONTAGION
	perceive target:People in: other_distance {
		emotional_contagion emotion_detected:fear emotion_created:fear when: fearful = false;
		if (has_emotion(fear)) {
				write self.name + " is FEARFUL";
		}
	}
	//emotion joy <- nil; //emozione sganciata da un predicato, per ora vuota
	perceive target:People in: other_distance{
		emotional_contagion emotion_detected: joy;
		ask myself {
			if (has_emotion(fear)) {
				write self.name + " fear from contagion 2";
			}
		}
	}
	* 
	*/


	//TODO: MOVEMENT
	predicate enjoying_my_time <- new_predicate("enjoying my time");
	predicate evacuation_order <- new_predicate("evacuation order");

	rule begin_evacuation when: self.has_belief(evacuation_order){
		do remove_intention(enjoying_my_time, true);
	}
		
	plan lets_wander intention: enjoying_my_time {
		do wander on: road_network;
	}
	
	
	//queste regole mandano l'agente al rifugio anziche al target quando paura o paura conf o credenza di catastrofe 
	
	//if the agent has a fear confirmed, it has the desire to go to a shelter
	
//	rule emotion:fearConfirmed remove_intention: at_target new_desire:in_waiting_area strength:5.0;
	
	//if the agent has the belief that there is a a catastrophe,  it has the desire to go to a shelter
	
//	rule belief:new_predicate("boom") remove_intention:at_target new_desire:in_waiting_area strength:5.0;
	
//	rule emotion:new_emotion("fear" ,new_predicate("boom")) new_desire:in_waiting_area remove_intention:at_target when: fearful strength:5.0;
	
	//rule emotion:new_emotion("fear" ,new_predicate("catastrophe")) new_desire:in_shelter remove_intention:at_target when: fearful strength:5.0;
	
	
	//bool noTarget<-true; //serve a controllare se il target è impostato che comunque è regolato in normal_move
	

/*	
	
	action to_escape_mode {
		escape_mode <- true;
		//color <- #darkred;
		target <- nil;	
		noTarget <- true;
		do remove_intention(at_target_port, true);
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
*/
	

//se ho hazard dico a tutti quelli che precedentemente ho incontrato che c'è il pericolo (in qualche modo implicito)
//l'intention di share information si attiva con una certa forza in ogni caso qunado io percepisco hazard sia che io sia spaventato che no
	plan share_information_to_friends intention: share_information instantaneous: true {
		list<People> my_friends <- list<People>((social_link_base where (each.liking > 0)) collect each.agent);
		loop known_hazard over: get_beliefs_with_name("boom") {
			ask my_friends {
				do add_directly_belief(known_hazard);
				write self.name + " comunicated hazard to :"  ;
			}
		}
		
		do remove_intention(share_information, true); 
	}
	
	
	
	reflex set_high_intensity {
		//vehicles
			if boom_intensity >= 7 {high_intensity <- true;} //da cambiare il valore a piacere
	}
	
	
	emotion fear <- new_emotion("fear");
	emotion joy <- new_emotion("joy");
	
	
	//rule emotion: new_emotion(fear) new_desire:at_nearest_evacuation_infrastructure remove_intention:at_target_port when: high_intensity=true and boarded=false and fearful = false;
	
	//rule emotion: new_emotion(joy) remove_emotion:fear when: has_belief(in_target_port);
	
	reflex creating_fear when: high_intensity=true and boarded=false and fearful = false{
		do add_emotion(fear) ;
		write self.name + " has fear";
		do add_desire(at_nearest_evacuation_infrastructure);
		do remove_intention(at_target_port);
		fearful <- true;
		
	}
	
	reflex creating_joy when: waiting_at_port = true{
		do add_emotion(fear) ;
		//write self.name + " has joy";
		do remove_emotion(fear);

	}
	
	
	//TODO: EMOTIONAL CONTAGION
	//CONTAGIO EMOOTIVO NON SO SE NON FUNZIONA PERCHE NON CI SONO ABBASTANZA PERSONE NON GIA FEARFUL OPPURE PERCHE NON VA IL COMANDO 
	perceive target:People in: other_distance {
		emotional_contagion emotion_detected:fear emotion_created:fear when: fearful = false;
		
		 if (has_emotion(fear)) and fearful = false{ //stampa effettivamente se c'è la condizione per il contagio e ha paura
				write self.name + " is elicited";
		}
	}
	
	
	
	//plan vai alla evacuation piu vicina:
	
	
	perceive target: evacuation_infrastructure_to_evacuate_from in: 10 #m {
		ask myself{
			do remove_intention(at_nearest_evacuation_infrastructure, true);
			do add_desire(in_target_evacuation_infrastructure);
		}
	}
	
	plan go_to_nearest_evacuation_infrastructure intention: at_nearest_evacuation_infrastructure {
		evacuation_infrastructure_to_evacuate_from <- EvacuationInfrastructure closest_to(self);
		do goto target: evacuation_infrastructure_to_evacuate_from on: road_network;
	}
	
	
	plan wait_failing intention: in_target_evacuation_infrastructure {
		if location != Port closest_to(self) {
			do add_desire (in_target_port);//cosi torna nel piano standard di human
		}
		else {
				//ASPETTA DI ESSERE CAZZIATO DA PROT CIVILE , CHE MI METTERA DI NUOVO IL DESIDERIO DEL PORTO
			}
		}
	
	
	//ADESSO POSSO FARE CONTAGIO EMOTIVO , OSSIA MAGARI NON HO SENTITO IL BOOM E QUIDNI NON HO PAURA MA SE PERCEPISCO QUALCUNO CHE LA HA MI CONTAGIO
	//METTICI EMOZIONE GIOIA QUANDO ARRIVI A GIOIA CHE RIMUOVE FEAR remove_emotion
	//elimina parti di emozioni superflue
	
	
	
	aspect default {
	  draw circle(5) color: color border: #black;
	  draw circle(view_dist) color: color border: #black wireframe: true;
	}
	
	

}
/*
 * TODO: FORZE ORDINE
 */
/*
 *  EVACUTION VEHICLES: ferries, helicopters
 */
species EvacuationVehicle skills: [moving] {
	//hub variables
	EvacuationInfrastructure hub;
	point hub_location;
	//target variables
	EvacuationInfrastructure target_infrastructure_agent;
	point target_destination;
	//evacuation variables
	bool evacuation_mode <- false; //TRUE if an evacuation has been ordered
	bool ready_to_evacuate <- false;
	bool safe <- true; //TRUE if the agent feel safe in its location
	//boarding variables
	bool free_to_go <- false;
	bool should_board <- false;
	float boarding_speed;
	float approach_distance;
	bool waiting_people_to_board <- false;
	bool waited_for_too_long <- false;
	float waiting_time <- 0.0 #s; 
	float max_waiting_time;
	//unboarding variables
	bool should_unboard <- false;
	float unboarding_speed;
	//other vehichle characteristics
	int capacity; //the vehicle capacity
	int people_on_board; //it reflects how many people are on board
	list<Human> people_on_board_list;
	float cruising_speed;	
	
	reflex waiting when: waiting_people_to_board = true{
		//write self.name + "- WAITING!"; //debug line
		waiting_time <- waiting_time + step;
		if waiting_time > max_waiting_time {
			write self.name + "- waited for too long. Going back to hub.";
			ready_to_evacuate <- false;
			free_to_go <- false;
			should_board <- false;
			waiting_people_to_board <- false;
			waiting_time <- 0.0 #s;
			waited_for_too_long <- true;
			ask target_infrastructure_agent {self.occupied_evacuation_spots <- self.occupied_evacuation_spots -1;}
		}
	}
	
	reflex boarding when: should_board = true {
		if waiting_people_to_board = false {waiting_people_to_board <- true;}
		ask target_infrastructure_agent {
			myself.people_on_board <- int(board_people(myself.boarding_speed, myself.people_on_board, myself, myself.people_on_board_list));
		}
		if people_on_board = capacity {
			write self.name + " - Boarding complete.";
			ready_to_evacuate <- false;
			free_to_go <- false;
			should_board <- false;
			waiting_people_to_board <- false;
			waiting_time <- 0.0 #s;
			ask target_infrastructure_agent {self.occupied_evacuation_spots <- self.occupied_evacuation_spots -1;}
		}	
	}
	
	reflex unboarding when: should_unboard = true{
		ask target_infrastructure_agent {
			myself.people_on_board <- int(unboard_people(myself.unboarding_speed, myself.people_on_board, myself.people_on_board_list));
		}
		if people_on_board = 0 {
			write self.name + " - Unboarding complete.";
			ready_to_evacuate <- true;
			free_to_go <- false;
			should_unboard <- false;
		}
	}
}
	//FERRY AGENT
species Ferry parent: EvacuationVehicle {
	
	image_file ferry_icon;
	
	reflex ferry_update {
		//TODO: add comunication from Protezione Civile
		if evacuation_mode = true {
			if people_on_board > 0 and ready_to_evacuate = false {
				if location != hub_location {
					do goto target: hub_location speed: cruising_speed on: ferry_network;
					if target_destination != hub_location {target_destination <- hub_location;}
				}
				else {
					if should_unboard = false {should_unboard <- true;}
				}
			}
			else if people_on_board = 0 and ready_to_evacuate = false {
				if safe = true and waited_for_too_long = false{
					ready_to_evacuate <- true;
					free_to_go <- false;
				}
				else if safe = false and waited_for_too_long = false{
					do goto target: hub_location speed: cruising_speed on: ferry_network;
				}
				else if waited_for_too_long = true {
					do goto target: hub_location speed: cruising_speed on: ferry_network;
					if location = hub_location {
						ready_to_evacuate <- true;
					}
					
				}
			}
			else if people_on_board >= 0 and ready_to_evacuate = true {
				//TODO: communicate to PC that he is ready to go Vulcano
				if location != target_destination and target_destination != hub_location {
					do goto target: target_destination speed: speed on: ferry_network;
					if location distance_to target_destination < approach_distance and free_to_go = false {
						//Chiede al porto se è libero
						speed <- 0.0;
						ask target_infrastructure_agent {
							if self.full = false {
								myself.free_to_go <- true;
								self.occupied_evacuation_spots <- self.occupied_evacuation_spots +1;
							}
							else if self.full = true {/*do nothing*/}
						}
						if safe = false {ready_to_evacuate <- false;}
					}
					if location distance_to target_destination < approach_distance and free_to_go = true {
						speed <- cruising_speed;
					}
				}
				else if location = target_destination and target_destination != hub_location {
					should_board <- true;
					speed <- 0.0;
				}
				else if target_destination = hub_location {
					/*wait for PC to tell where to go, in the meanwhile go to hub*/
					do goto target: target_destination speed: speed on: ferry_network;
					if location = hub_location {speed <- 0.0;}
					else {if speed != cruising_speed {speed <- cruising_speed;}}
				}
			}
		}
		else {do goto target: target_destination speed: speed on: ferry_network;}
	}
	
	reflex ferry_safety_check {}
	
	aspect base {
		draw triangle(300) rotate: heading + 90 color: #darkblue;
	}
	aspect icon {
		draw ferry_icon size: 1;
	}
}
	//TODO: HELICOPTER

experiment "show simulation" type: gui {     
    output {
	    display vulcano_map type: 3d{
	       species Island refresh: false;
	       species Roads refresh: false;
	       species Ferry_Route refresh: false;
	       species Buildings refresh: false; 
	       species Waiting_Areas refresh: false;
	       species Port;
	       species Heliport;
	       species Ferry aspect: base;
   	       species Volcano;
	       species RoaringSoundEmission;
	       species People;
	    }
	}
}


