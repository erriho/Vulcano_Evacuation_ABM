model TestModel

global {
	//gloal variables
	int evacuated_people;
	
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
		 * CREATING CIVIL DEFENSE
		 */
		 create CivilDefense number: 1{
		 	name <- "Protezione Civile";
		 	ITallert <- true;
		 }
		 /*
		  * TODO: CREATING PEOPLE
		  */
		create People number: 50 {
			speed <- 30 #km/#h;
			location <- any_location_in(one_of(Roads));
    	}
    	//create social links
    	bool there_are_people_left <- true;
    	int people_with_assigned_friends <- 0;
   		list<People> People_copy <- shuffle(People);
    	loop while: !empty(People_copy) {
    		int new_group_of_friend_size<-rnd(5,15);
    		people_with_assigned_friends <- people_with_assigned_friends + new_group_of_friend_size;
    		if people_with_assigned_friends >= length(People){
    			//DEBUG: int temp_new_group_of_friend_size <- new_group_of_friend_size; 
    			new_group_of_friend_size <- new_group_of_friend_size - (people_with_assigned_friends - length(People));
	    		//DEBUG: people_with_assigned_friends <- people_with_assigned_friends-temp_new_group_of_friend_size+new_group_of_friend_size;
    		}
    		list<People> new_friends_circle;
    		loop i over: range(new_group_of_friend_size-1){
    			People new_friend <- one_of(People_copy);
    			new_friends_circle <+ new_friend;
    			People_copy >- new_friend;
    		}
  			list<People> new_friends_circle_copy;
    		loop person over: new_friends_circle {
    			new_friends_circle_copy <+ person;
    		}
    		loop person over: new_friends_circle {
    			loop my_friend over: new_friends_circle_copy {
    				ask person {
    					social_link sl <- new_social_link(my_friend);
    					do add_social_link(sl);
    					sl <- set_liking(get_social_link(new_social_link(my_friend)),rnd(0.0,1.0,0.1));
    					sl <- set_dominance(get_social_link(new_social_link(my_friend)),rnd(0.0,1.0,0.1)); 
    					sl <- set_solidarity(get_social_link(new_social_link(my_friend)),rnd(0.0,1.0,0.1));
    					sl <- set_familiarity(get_social_link(new_social_link(my_friend)),rnd(0.0,1.0,0.1)); 
    					sl <- set_trust(get_social_link(new_social_link(my_friend)),rnd(0.0,1.0,0.1));
    				}
    				ask my_friend{
    					social_link sl <- new_social_link(person);
    					do add_social_link(sl);
    					sl <- set_liking(get_social_link(new_social_link(person)),rnd(0.0,1.0,0.1));
    					sl <- set_dominance(get_social_link(new_social_link(person)),rnd(0.0,1.0,0.1)); 
    					sl <- set_solidarity(get_social_link(new_social_link(person)),rnd(0.0,1.0,0.1));
    					sl <- set_familiarity(get_social_link(new_social_link(person)),rnd(0.0,1.0,0.1)); 
    					sl <- set_trust(get_social_link(new_social_link(person)),rnd(0.0,1.0,0.1));
    				}
    			}
    			new_friends_circle_copy >- person;
    		}
    	}
		 /*
		  * TODO: CREATING FORZE ORDINE
		  */
		 /*
		  * CREATING FERRIES AND HELICOPTERS
		  */
		create Ferry number: 2 {
			//DEBUG: evacuation_mode <- true;
			//DEBUG: ready_to_evacuate <- true;
			safe <- true;
			cruising_speed <- 20 #km/#h;
			speed <- cruising_speed;
			approach_distance <- 1 #km;
			boarding_speed <- 1/(15#s);
			unboarding_speed <- 1/(15#s);
			max_waiting_time <- 3000 #s;
			capacity <- 20;
			location <- any_location_in(one_of(ferry_network.vertices));
			loop port over: Port {
				//DEBUG:write port.name;
				if port.name = "Porto di Milazzo" {
					hub <- port;
					hub_location <- port.location;
					//write "DEBUG: " + string(self.hub_location) + "-" + port.location;
				}
			}
			if flip(1/2) {
				Port port <- Port first_with(each.name = "Porto di Milazzo");
				target_infrastructure_agent <- port;
				self.target_destination <- port.location;
			}
			else {
				Port port <- Port first_with(each.name = "Porto di Levante");
				target_infrastructure_agent <- port;
				self.target_destination <- port.location;				
			}
		}
		create Helicopter number: 2 {
			//DEBUG: evacuation_mode <- true;
			//DEBUG: ready_to_evacuate <- true;
			safe <- true;
			cruising_speed <- 150 #km/#h;
			speed <- 0 #km/#h;
			approach_distance <- 100 #m;
			boarding_speed <- 1/(15#s);
			unboarding_speed <- 1/(15#s);
			max_waiting_time <- 1200 #s;
			capacity <- 5;
			Heliport base_heliport <- Heliport first_with(each.name = "Nave 1");
			hub <- base_heliport;
			hub_location <- hub.location;
			location <- hub.location;
			target_destination <- hub_location; 
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
	int people_with_no_assigned_vehicle;
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
		if max_nb_of_people_to_board < 1 {max_nb_of_people_to_board <- rnd_choice([(1-boarding_speed*step),boarding_speed*step]);}
		//write "DEBUG: trying to board" + max_nb_of_people_to_board; 
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
			evacuated_people <- evacuated_people + 1;
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
	init {
		color <- #blue;
		std_color <- #blue;		
	}
	aspect default {
		draw circle(20) color: rgb(color, 0.9);
		if self.name != "Porto di Milazzo" {draw string(string(people_waiting_nb) + "/" + string(actual_people_capacity)) font: font(font_name, 5) color: color;}
	}
}
	//HELIPORT AGENT
species Heliport parent: EvacuationInfrastructure {
	bool lights;
	init {
		color <- #orange;
		std_color <- #orange;		
	}
	
	aspect default {
		draw circle(20) color: rgb(color, 0.9);
	}
}

	//WAITING AREAS
species Waiting_Areas parent: EvacuationInfrastructure {
    init {
    	color <- rgb(153, 153, 153);
    	std_color <- rgb(153, 153, 153);
    }
    aspect default{    	
    	draw shape color: rgb(color, 0.9);
    }
}
/*
 * CivilDefense
 */
 species CivilDefense {
 	// VOLCANO MONITORING
 	int LaFossa_activity_level;
 	Volcano LaFossa;
 	bool monitor_la_fossa <- false;
 	init {
 		if Volcano first_with(each.name = "LaFossa") != nil {
	 		LaFossa <- Volcano first_with(each.name = "LaFossa"); 
	 		monitor_la_fossa <- true;			
 		}
 	}
 	reflex monitor_volcano when: monitor_la_fossa {
 		float evac_order_issuance_time;
 		LaFossa_activity_level <- LaFossa.activity_level;	
 		if LaFossa_activity_level = 2 and issue_evacuation_order = false{
 			evac_order_issuance_time <- evac_order_issuance_time + step; 
  			if evac_order_issuance_time >= time_needed_to_issue_evac_order {
  				write self.name + ": evacuation order issued.";
 				issue_evacuation_order <- true;
 			}
		}
 	}
 	// TODO: EVACUATION ORDER (missing forze dell'ordine)
 	bool issue_evacuation_order <- false;
 	float time_needed_to_issue_evac_order <- 0 #s;
 		//ferries and helicopers
 	list<Ferry> alerted_ferries;
 	reflex alert_ferries when: !empty(Ferry - alerted_ferries) and issue_evacuation_order = true{
 		ask Ferry {evacuation_mode <- true;}
 		alerted_ferries <- list(Ferry);
 	}
 	list<Helicopter> alerted_helicopters;
 	reflex alert_helicopters when: !empty(Helicopter - alerted_helicopters) and issue_evacuation_order = true{
 		ask Helicopter {evacuation_mode <- true;}
 		alerted_helicopters <- list(Helicopter);
 	}
	 	//people
 	list<People> alerted_people <- [];
 	bool ITallert <- false; 
 	float ITallert_issuance_time <- 0 #s;
 	float time_needed_to_issue_ITallert <- 0 #s;
 	reflex alert_people_with_ITallert when: !empty(People - alerted_people) and issue_evacuation_order = true and ITallert = true {	
 		ITallert_issuance_time <- ITallert_issuance_time + step; 
 		if ITallert_issuance_time >= time_needed_to_issue_ITallert {
 			write "(" + time + ")" + self.name + ": issued ITallert message.";
 			loop person over: People {
 				ask person {
 					do add_belief(evacuation_order);	 					
 				}
	 		} 			
	 		alerted_people <- list(People);
 		}
 	}
 	// TODO: MANAGING EVACUATION INFRASTRUCTURES (missing heli)
	list<Port> ports_to_evacuate;
	float decision_time <- 600 #s;
	map<string,float> port_decision_time_map;
	map<string,map> port_statuses;
 	reflex check_port_status {
 		/*
 		 //this piece of code was commented out as it is not needed at the moment
 		map<string,map> old_port_statuses <- port_statuses;
 		map<string,map> new_port_statuses;
 		port_statuses <- [];
 		loop port over: Port {
 			map<string, unknown> status_map;
 			status_map <+ [	//"agent" :: port, 
 							//"location" :: port.location,
 							//"people_waiting" :: port.people_waiting_nb
 							"viability" :: port.viability
 							];
 			new_port_statuses <+ [port.name :: status_map];
 		}
 		port_statuses <- new_port_statuses;
 		*/
 		loop port over: Port {
  			if (port.people_with_no_assigned_vehicle > 0 and port.viability = true) and not (ports_to_evacuate contains port){
  				port_decision_time_map[port.name] <- port_decision_time_map[port.name] + step; 
  				if port_decision_time_map[port.name] > decision_time {
 					ports_to_evacuate <+ Port(port); 				
 				//string debug_name <- port.name; as much as it is weird, this line prevents a bug (not actually passing port), even though it is commented out 				
 				}
 			}
 		}
 	}

	list<Heliport> heliports_to_evacuate;
	map<string,float> heliport_decision_time_map;
	reflex check_heliport_status{
		loop heliport over: Heliport {
  			if (heliport.people_with_no_assigned_vehicle > 0 and heliport.viability = true) and not (heliports_to_evacuate contains heliport){
  				heliport_decision_time_map[heliport.name] <- heliport_decision_time_map[heliport.name] + step; 
  				if heliport_decision_time_map[heliport.name] > decision_time {
 					heliports_to_evacuate <+ Heliport(heliport); 				
 				//string debug_name <- heliport.name; as much as it is weird, this line prevents a bug (not actually passing port), even though it is commented out 				
 				}
 			}
 		}
	}
 	
 	action update_infrstructure_viability {}
 	// TODO: MANAGING EVACUATION VEHICLES
 	list<Ferry> ferries_ready_to_go;
 	list<Helicopter> helicopters_ready_to_go;
 	
 	reflex tell_ferry_where_to_go when: !empty(ferries_ready_to_go) {
 		if !empty(ports_to_evacuate) {
		 	list<Port> emptied_ports <- [];
	 		loop port over: ports_to_evacuate {
	 			int people_still_waiting <- port.people_with_no_assigned_vehicle;
	 			loop while: people_still_waiting > 0 and !empty(ferries_ready_to_go){
	 				Ferry selected_ferry <- ferries_ready_to_go with_max_of(each.capacity);
			 		ask selected_ferry {
			 			self.target_infrastructure_agent <- port;
			 			self.target_destination <- port.location;
			 		}
			 		ferries_ready_to_go >- selected_ferry;
			 		people_still_waiting <- people_still_waiting - selected_ferry.capacity;	
			 		//write "DEBUG: " + string(time) + " - " + people_still_waiting;
			 		port.people_with_no_assigned_vehicle <- people_still_waiting; 			
	 			}
	 			if people_still_waiting <= 0 {
	 				emptied_ports <+ Port(port);
	 				
	 			} 			
	 		}
	 		loop port over: emptied_ports {
				ports_to_evacuate >- Port(port);
			}
		}
		else {
			loop ferry over: ferries_ready_to_go {
				ask ferry {
		 			self.target_infrastructure_agent <- hub;
		 			self.target_destination <- hub.location;
				}	
			}
		}
 	}
 	
 	reflex tell_helicopters_where_to_go when: !empty(helicopters_ready_to_go) {
	if !empty(heliports_to_evacuate) {
	 	list<Heliport> emptied_heliports <- [];
 		loop heliport over: heliports_to_evacuate {
 			int people_still_waiting <- heliport.people_with_no_assigned_vehicle;
 			loop while: people_still_waiting > 0 and !empty(helicopters_ready_to_go){
 				Helicopter selected_helicopter <- helicopters_ready_to_go with_max_of(each.capacity);
		 		ask selected_helicopter {
		 			self.target_infrastructure_agent <- heliport;
		 			self.target_destination <- heliport.location;
		 		}
		 		helicopters_ready_to_go >- selected_helicopter;
		 		people_still_waiting <- people_still_waiting - selected_helicopter.capacity;	
		 		//write "DEBUG: " + string(time) + " - " + people_still_waiting;
		 		heliport.people_with_no_assigned_vehicle <- people_still_waiting; 			
 			}
 			if people_still_waiting <= 0 {
 				emptied_heliports <+ Heliport(heliport);
 			} 			
 		}
 		loop heliport over: emptied_heliports {
			heliports_to_evacuate >- Heliport(heliport);
		}
	}
	else {
		loop helicopter over: helicopters_ready_to_go {
			ask helicopter {
	 			self.target_infrastructure_agent <- hub;
	 			self.target_destination <- hub.location;
			}	
		}
	}
}
 	
 	
 }
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
	bool use_emotions_architecture <- true; //per attivare processo emozionale automatico 
	bool use_social_architecture <- true;
	//boarding-related variables
	Port port_to_evacuate_from;
	bool decided_to_board;
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
				port_to_evacuate_from.people_with_no_assigned_vehicle <- port_to_evacuate_from.people_with_no_assigned_vehicle + 1;
				//write "DEBUG: " + port_to_evacuate_from.name + "-" + port_to_evacuate_from.people_waiting_list;
			}
		}
	} 
	bool choose_whether_to_board {	
		return flip(0.99);	
	}
	
	reflex on_board when: boarded = true { 
		//speed <- boarded_vehicle.speed; 
		//location <- boarded_vehicle.location; 
		do goto target: boarded_vehicle.location speed: boarded_vehicle.speed on:ferry_network; //computed much faster
	}
 }
/*
 * PEOPLE
 */
 species People parent: Human{
	float view_dist<-30.0;
	
	//volcano-related variables 
	int boom_intensity;
	
	//customiaztion variables	
	rgb color <- #blue;
	
	//init
	init {
		do add_desire(enjoying_my_time);
	}
	
	//TODO: MOVEMENT and EVACUATION
	predicate enjoying_my_time <- new_predicate("enjoying my time");
		
	plan lets_wander intention: enjoying_my_time {
		do wander on: road_network;
	}
	
	predicate evacuation_order <- new_predicate("evacuation order");
	predicate need_evac_decision <- new_predicate("need to take a decision on whether to evacuate");
	predicate going_to_port <- new_predicate("decided to go to port"); 
	predicate going_rescue_someone <- new_predicate("decided to go rescue someone");
	predicate waiting_for_someone <- new_predicate("decided to wait for someone");
	rule belief: evacuation_order remove_desire: enjoying_my_time new_desire: need_evac_decision;
	rule belief: going_to_port remove_intention: need_evac_decision remove_desire: need_evac_decision new_desire: at_target_port;
	
	plan choose_whether_to_evacuate intention: need_evac_decision {
		//decision process
		if flip(1) {
			do add_belief(going_to_port);
		} 
	}
	  
	//TODO: SOCIAL LINKS

	//TODO: EMOTIONAL RESPONSE TO VOLCANIC ACTIVITIES

	//TODO: EMOTIONAL CONTAGION

	aspect default {
		draw triangle(5) rotate: heading + 90 color: color border: #black;
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
	bool free_info_transmitted <- false;
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
		//write "DEBUG: " + self.name + "- WAITING!"; //debug line
		waiting_time <- waiting_time + step;
		if waiting_time > max_waiting_time {
			write self.name + "- waited for too long. Going back to hub.";
			ready_to_evacuate <- false;
			free_to_go <- false;
			should_board <- false;
			waiting_people_to_board <- false;
			waiting_time <- 0.0 #s;
			waited_for_too_long <- true;
			ask target_infrastructure_agent {
				self.occupied_evacuation_spots <- self.occupied_evacuation_spots -1;
			}
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
			ask target_infrastructure_agent {
				self.occupied_evacuation_spots <- self.occupied_evacuation_spots -1;
				self.people_with_no_assigned_vehicle <- self.people_with_no_assigned_vehicle + myself.capacity - myself.people_on_board;
			}
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
			free_info_transmitted <- false;
			should_unboard <- false;
		}
	}
}
	//FERRY AGENT
species Ferry parent: EvacuationVehicle {
	
	image_file ferry_icon;
	
	reflex ferry_update {
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
					free_info_transmitted <- false;
					ready_to_evacuate <- true;
					if location = hub_location {
					}
					
				}
			}
			else if people_on_board >= 0 and ready_to_evacuate = true {
				if people_on_board = 0 and free_info_transmitted = false{
					ask CivilDefense {
						if not (self.ferries_ready_to_go contains myself) {
							//DEBUG write "Ready to evacuate people!";
							self.ferries_ready_to_go <+ myself;
						}
					}
					free_info_transmitted <- true;
				}
				if location != target_destination and target_destination != hub_location {
					if location = hub_location {speed<-cruising_speed;}
					do goto target: target_destination speed: speed on: ferry_network;
					if location distance_to target_destination < approach_distance and free_to_go = false {
						//ask port whether it is free or not
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
	//HELICOPTER
species Helicopter parent: EvacuationVehicle {
	
	image_file helicopter_icon;
	
	reflex helicopter_update {
		if evacuation_mode = true {
			if people_on_board > 0 and ready_to_evacuate = false {
				if location != hub_location {
					if flying = false {should_take_off <- true;} 
					else{
						do goto target: hub_location speed: cruising_speed;
						if target_destination != hub_location {target_destination <- hub_location;}					
					}
				}
				else {
					if flying = true {should_land <- true;}
					else {if should_unboard = false {should_unboard <- true;}}
				}
			}
			else if people_on_board = 0 and ready_to_evacuate = false {
				if safe = true and waited_for_too_long = false{
					ready_to_evacuate <- true;
					free_to_go <- false;
				}
				else if safe = false and waited_for_too_long = false{
					if flying = false {should_take_off <- true;} 
					else{do goto target: hub_location speed: cruising_speed;}
				}
				else if waited_for_too_long = true {
					if flying = false {should_take_off <- true;} 
					else{do goto target: hub_location speed: cruising_speed;}
					free_info_transmitted <- false;
					ready_to_evacuate <- true;
				}
			}
			else if people_on_board >= 0 and ready_to_evacuate = true {
				if people_on_board = 0 and free_info_transmitted = false{
					ask CivilDefense {
						if not (self.helicopters_ready_to_go contains myself) {
							//DEBUG write "Ready to evacuate people!";
							self.helicopters_ready_to_go <+ myself;
						}
					}
					free_info_transmitted <- true;
				}
				if location != target_destination and target_destination != hub_location {
					if flying = false {should_take_off <- true;} 
					else{
						do goto target: target_destination speed: speed;
						if location distance_to target_destination < approach_distance and free_to_go = false {
							//ask heliport whether it is free or not
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
				}
				else if location = target_destination and target_destination != hub_location {
					if flying = true {should_land <- true;}
					else {
						should_board <- true;
						speed <- 0.0;						
					}
				}
				else if target_destination = hub_location {
					/*wait for PC to tell where to go, in the meanwhile go to hub*/
					if flying = false and self.location != hub_location{
						should_take_off <- true;
					}
					else if flying = false and self.location = hub_location {}
					else {
						do goto target: target_destination speed: speed;
						if location = hub_location {speed <- 0.0;}
						else {if speed != cruising_speed {speed <- cruising_speed;}}					
					}
				}
			}
		}
		else {do goto target: target_destination speed: speed;}
	}
	bool should_take_off <- false;
	bool should_land <- false;
	bool flying <- false;
	float takeoff_avg_speed <- 5 #m/#s;
	float landing_avg_speed <- 3 #m/#s;
	float altitude <- 0.0 #m;
	float cruising_altitude <- 150 #m; 
	reflex taking_off when: should_take_off = true {
		altitude <- altitude + takeoff_avg_speed*step;
		//write "DEBUG: taking_off";
		if altitude >= cruising_altitude {
			altitude <- cruising_altitude;
			speed <- cruising_speed;
			flying <- true;
			should_take_off <- false;
		}
	}
	reflex landing when: should_land = true {
		altitude <- altitude - takeoff_avg_speed*step;
		//write "DEBUG: landing";
		if altitude <= 0.0 #m {
			altitude <- 0.0 #m;
			speed <- 0.0 #km/#h;
			flying<-false;
			should_land <- false;
		}
	}
	
	reflex helicopter_safety_check {}
	
	aspect base {
		draw triangle(300) rotate: heading + 90 color: #yellow;
	}
	aspect icon {
		draw helicopter_icon size: 1;
	}
}

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
	       species Helicopter aspect: base;
   	       species Volcano;
	       species RoaringSoundEmission;
	       species People;
	    }
	}
}

experiment "show simulation_with_charts" type: gui {     
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
	       species Helicopter aspect: base;
   	       species Volcano;
	       species RoaringSoundEmission;
	       species People;
	    }
		display Evacuation_Info refresh: every(120 #cycles) {
	       //TODO: add a data series for people on board, update the people still to evacuate accordingly (also add something that counts the people at the beginning of the evacuation)
	       chart "People evacuated successfully" type: series size: {1,0.5}{
		       	data "People successfully evacuated" value: evacuated_people color: #blue;
		       	data "People still to evacuate" value: (length(People)-evacuated_people) color: #red;
	       }			
		}	       
	}
}


