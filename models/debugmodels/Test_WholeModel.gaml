model TestModel

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
		create Port from: ports_shp;
		create Heliport from: heliports_shp;
		// matching ports and heliports to data
		loop port over: Port {
			loop row_index over: range(length(rows_list(ports_data_matrix))-1) {
				if port.name = string(ports_data_matrix[0, row_index]) {
					port.max_evacuation_vehicles_capacity <- int(ports_data_matrix[1, row_index]); 
					port.actual_evacuation_vehicles_capacity <- port.max_evacuation_vehicles_capacity;
					port.max_people_capacity <- int(ports_data_matrix[2, row_index]);
					port.actual_people_capacity <- port.max_people_capacity;
					//write port.name + " - " + port.max_evacuation_vehicles_capacity + " - " + port.max_people_capacity + " - " + port.location; 
				}
			}
			//if port.name = 'Molo di protezione civile di Gelso' {ask port {do die;}}
			//else if port.name = 'Molo di protezione civile di Ponente' {ask port {do die;}}	
		}
		loop heliport over: Heliport {
			loop row_index over: range(length(rows_list(heliports_data_matrix))-1) {
				if heliport.name = string(heliports_data_matrix[0, row_index]) {
					heliport.max_evacuation_vehicles_capacity <- int(heliports_data_matrix[1, row_index]); 
					heliport.actual_evacuation_vehicles_capacity <- heliport.max_evacuation_vehicles_capacity;
					heliport.max_people_capacity <- int(heliports_data_matrix[2, row_index]);
					heliport.actual_people_capacity <- heliport.max_people_capacity;
					//write heliport.name + "-" + heliport.max_evacuation_vehicles_capacity + "-" + heliport.max_people_capacity;
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
		 /*
		  * TODO: CREATING FORZE ORDINE
		  */
		 /*
		  * CREATING FERRIES AND HELICOPTERS
		  */
		create ferry number: 1 {
			evacuation_mode <- true;
			ready_to_evacuate <- true;
			safe <- true;
			cruising_speed <- 20 #km/#h;
			speed <- cruising_speed;
			approach_distance <- 1 #km;
			max_waiting_time <- 3000 #s;
			//people_on_board <- 1;
			capacity <- 1;
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
	//CRATER
species Crater {
	aspect default{
		draw triangle(25) color: #black;
	}
}
/*
 * EVACUATION INFRASTRUCTURES: ports, heliports
 */
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
 *  EVACUTION VEHICLES: ferries, helicopters
 */
species evacuation_vehicle skills: [moving] {
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
	list <agent> people_on_board_list;
	float cruising_speed;	
	
	reflex waiting when: waiting_people_to_board = true{
		write self.name + "- WAITING!"; //debug line
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
species ferry parent: evacuation_vehicle {
	
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
	list<people> unexposed_people;
	string exposition_model <- "squared";
	//reflexes
	reflex initialize when: should_initialize = true {
		unexposed_people <- agents of_species(species(people));
		size <- 0.0;
		intensity <- rnd_choice(intensity_distribution);
		write "Boom!" + " - Intensity: " + string(intensity);
		should_initialize <- false;
	}
	reflex execute {
		if empty(unexposed_people) = false {
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
					remove item: person from: unexposed_people;
				}		
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
* TODO: PEOPLE
*/
species people {
	int boom_intensity;
}
/*
* TODO: FORZE ORDINE
*/
/*
 * CREATING FERRIES AND HELICOPTERS
 */

experiment "show simulation" type: gui {     
    output {
	    display vulcano_map type: 3d{
	       species Island refresh: false;
	       species Roads refresh: false;
	       species Ferry_Route refresh: false;
	       species Buildings refresh: false; 
	       species Port;
	       species Heliport;
	       species ferry aspect: base;
   	       species Volcano;
	       species RoaringSoundEmission;
	    }
	}
}
