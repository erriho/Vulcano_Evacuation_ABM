model TestModel

global {
		//gloal variables for results
	bool save_data <- false;
	int save_series_every <- 15 #cycles;
	bool should_kill_simulation <- false;
	bool simulation_ended <- false;
	string saving_folder <- "../../results/" + seed + "/";
	string temporal_series_recorder_filename <- "temporal_series_recorder.csv";
	string volcanic_recorder_filename <- "volcanic_recorder.csv";
	string simulation_recorder_filename <- "simulation_recorder.csv";
		//evacuation variables
	int nb_humans_on_island;
	int nb_people_on_island;
	int nb_LEAs_on_island;
	int nb_humans_on_board; 
	int nb_people_on_board; 
	int nb_LEAs_on_board; 
	int nb_evacuated_humans;
	int nb_evacuated_people;
	int nb_evacuated_LEAs;
		//people status variables
	int nb_people_warned; 
	int nb_people_prepared;
	int nb_people_enjoying_their_time;
	int nb_people_making_a_decision;
	int nb_people_going_to_port;
	int nb_people_rescuing_others;
	int nb_people_waiting;
	int nb_people_going_to_safe_area;
	int nb_people_at_port;
	int nb_people_who_left_the_island;
		//people emotional status variable
	int nb_joyous_people;
	int nb_fearful_people;
	int nb_alright_people;
	
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
		//ferry data (helicopter data not supported yet)
	file ferries_data <- csv_file("../../includes/csv/Ferries_Bonadonna.csv");
	matrix ferries_data_matrix <- matrix(ferries_data);
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
	
		//civil defense
	bool ITalert_glob <- true;
	map glob_manage_LEAs_map <- [
		"give evacuation order" :: 20,
		"backup" :: manage_LEAs_backups_map 
	];
	map manage_LEAs_backups_map <- [
		"should create backups" :: true,
		"location":: "any_port",
		"number":: 20,
		"arrival time":: 60 #s
	];
	
		//people
	float preparing_time_avg <- 600 #s;
	float preparing_time_std <- 300 #s;
		
	/*
	 * ASPECT CUSTOMIZATION
	 */
	string font_name <- "Arial";
	
	/*
	 * SAVING SIMULATION OUTPUTS
	 */
		//recorder lists and usage (i.e. how they must be filled)
	list<map> volcanic_activity_recorder; //it contains object like ["time" :: time, "activity name" :: "Boom Emission", "activity params" :: ["intensity" :: 9]]
	list<map> simulation_events_recorder; //it contains object like ["time" :: time, "name" :: "Evacuation Order", "notes" :: ""]
		//saving temporal series (every n=save_series_every cycles)
	reflex save_temporal_series when: save_data = true and mod(cycle, save_series_every) = 0{
		string save_path <- saving_folder + temporal_series_recorder_filename;
		save [time, 
			nb_humans_on_island, nb_people_on_island, nb_LEAs_on_island,
			nb_humans_on_board, nb_people_on_board, nb_LEAs_on_board,
			nb_evacuated_humans, nb_evacuated_people, nb_evacuated_LEAs,
			nb_people_warned, nb_people_prepared, nb_people_enjoying_their_time, nb_people_making_a_decision, nb_people_going_to_port, nb_people_rescuing_others, nb_people_waiting, nb_people_going_to_safe_area, nb_people_at_port, nb_people_who_left_the_island,
			nb_joyous_people, nb_fearful_people, nb_alright_people
		] to: save_path format: "csv" header: true rewrite: false;
	}
		//saving the completion of civil evacuation (no more People left in the simulation)
	bool civil_evacuation_completion_was_saved <- false;
	reflex save_civil_evacuation_completion when: save_data and !civil_evacuation_completion_was_saved and empty(People){
		map event_map <- [
			"time" :: time,
			"name" :: "Civil Evacuation Completed",
			"notes" :: "The evacuation of civil population was completed."
		];
		simulation_events_recorder <+ event_map;
		civil_evacuation_completion_was_saved <- true;
	}
		//saving recorders
	reflex save_recorders when: empty(People) and empty(LawEnforcement) and save_data {
			//volcanic activity recorder
 		string save_path <- saving_folder + volcanic_recorder_filename;
		loop volcanic_event over: volcanic_activity_recorder {
			int event_time <- int(volcanic_event["time"]);
			string activity_name <- string(volcanic_event["activity name"]);
			int activity_intensity_value;
			if activity_name = "Boom Emission" {activity_intensity_value <- int(volcanic_event["activity params"]["intensity"]);}
			save [event_time, activity_name, activity_intensity_value] to: save_path format: "csv" header: true rewrite: false;	
		}
		//saving the completion of evacuation (no more People and LAEs left in the simulation)
		map event_map <- [
			"time" :: time,
			"name" :: "Evacuation Completed",
			"notes" :: "Evacuation was completed."
		];
		simulation_events_recorder <+ event_map;
			//simulation events recorder
		save_path <- saving_folder + simulation_recorder_filename;
		loop simulation_event over: simulation_events_recorder {
			int event_time <- int(simulation_event["time"]);
			string event_name <- string(simulation_event["name"]);
			string notes <- string(simulation_event["notes"]);
			save [event_time, event_name, notes] to: save_path format: "csv" header: true rewrite: false;	
		}
		do pause;
		simulation_ended <- true;
		if should_kill_simulation {ask host {do die;}}
	}
	
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
		 	ITalert <- ITalert_glob;
		 }
		 /*
		  * CREATING PEOPLE
		  */
		create People number: 1 {
			walking_speed <- 30 #km/#h;
			//walking_speed <- rnd(3.0,6.0,0.1) #km/#h;
			view_dist <- 30 #m;
			if flip(1/2) {location <- any_location_in(one_of(Buildings));}
			else {location <- any_location_in(one_of(Roads));}
			total_preparing_time <- 0 #s;
			//total_preparing_time <- truncated_gauss({preparing_time_avg, preparing_time_std})#s;
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
    				if my_friend.name != person.name { 					
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
    			}
    			new_friends_circle_copy >- person;
    		}
    	}
    	//adding information about friends
    	loop person over: People {
    		person.my_friends <- list<People>((person.social_link_base where (each.liking >= 0)) collect each.agent);
    		loop friend over: person.my_friends {
	    		map<string,unknown> my_friend_status <- ["name":: friend.name, "location"::friend.location, "status":: "unknown"];
	    		ask person {
	    			do add_belief(new_predicate("friend status", my_friend_status));	    			
	    		}
    		}
    	}
		 /*
		  * CREATING LAW ENFORCEMENT AGENTS
		  */
		create LawEnforcement number: 20 {
			view_dist <- 30 #m;
			float location_extraction <- rnd(1.0);
			if location_extraction <= 0.80 {
				float port_location_extraction <- rnd(1.0);
				if port_location_extraction <= 0.80 {location <- (first_with(Port,each.name = "Porto di Levante")).location;}
				else if port_location_extraction <= 0.80 + 0.15 {location <- (first_with(Port,each.name = "Molo di protezione civile di Gelso")).location;}
				else {location <- (first_with(Port,each.name = "Molo di protezione civile di Ponente")).location;}
			}
			else if location_extraction <= 0.80 + 0.0 {/*caserma dei carabinieri (not supported yet)*/}
			else {location <- any_location_in(one_of(road_network.vertices));}
			walking_speed <- rnd(3.0,6.0,0.1) #km/#h;
			vehicle_speed <- 25 #km/#h;
			//area_to_presidiate_location <- one_of(Waiting_Areas).location;
			//do add_desire(block_access); 		
			do add_desire(on_duty_regular);
		}
		 /*
		  * CREATING FERRIES AND HELICOPTERS
		  */
		list<string> ferry_names_list <- ['ferry - 1', 'ferry - 2', 'ferry - 3', 'ferry - 4'];
		create Ferry number: length(ferry_names_list) {
			//DEBUG: evacuation_mode <- true;
			//DEBUG: ready_to_evacuate <- true;
			safe <- true;
			approach_distance <- 1 #km;
			boarding_speed <- 1/(15#s);
			unboarding_speed <- 1/(15#s);
			max_waiting_time <- 3000 #s;
			location <- any_location_in(one_of(ferry_network.vertices));
			if location = {26638.627501384763,23758.905291362666,0.0} {
				location <- {26638.627501384763,23758.905291362666,0.0};
			}
			loop port over: Port {
				//DEBUG: write port.name;
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
		loop ferry over: Ferry {
			string extracted_name <- one_of(ferry_names_list);
			ferry.name <- extracted_name;
			ferry_names_list >- extracted_name;
		}
		loop ferry over: Ferry {
			loop row_index over: range(length(rows_list(ferries_data_matrix))-1) {
				if ferry.name = string(ferries_data_matrix[0, row_index]) {
					ferry.capacity <- int(ferries_data_matrix[1, row_index]);
					ferry.cruising_speed <- float(ferries_data_matrix[2, row_index]);
					ferry.speed <- ferry.cruising_speed;
					//write port.name + " - " + port.max_EvacuationVehicles_capacity + " - " + port.max_people_capacity + " - " + port.location; 
				}
			}
		}
		create Helicopter number: 2 {
			//DEBUG: evacuation_mode <- true;
			//DEBUG: ready_to_evacuate <- true;
			safe <- true;
			cruising_speed <- 200 #km/#h;
			speed <- 0 #km/#h;
			approach_distance <- 100 #m;
			boarding_speed <- 1/(15#s);
			unboarding_speed <- 1/(15#s);
			max_waiting_time <- 1200 #s;
			capacity <- 8;
			Heliport base_heliport <- Heliport first_with(each.name = "Nave 1");
			hub <- base_heliport;
			hub_location <- hub.location;
			location <- hub.location;
			target_destination <- hub_location; 
		}
	nb_humans_on_island <-length(People)+length(LawEnforcement);
	nb_people_on_island <-length(People);	
	nb_LEAs_on_island <- length(LawEnforcement);
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
					bool decision <- bool(self.want_to_board());
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
					do add_belief(left_the_island);
					if !(last(self.my_communicated_statuses) = "on board") {
						do add_subintention(get_current_intention(), communicate_status, true);		
						do current_intention_on_hold();							
			}
				}
				if People contains person {
					nb_people_on_board <- nb_people_on_board +1;
					nb_people_on_island <- nb_people_on_island - 1; 						
				}
				if LawEnforcement contains person{
					nb_LEAs_on_board <- nb_LEAs_on_board +1;
					nb_LEAs_on_island <- nb_LEAs_on_island - 1;
				}
				nb_humans_on_board <- nb_humans_on_board + 1;
				nb_humans_on_island <- nb_humans_on_island - 1;
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
			if People contains person {				
				nb_people_on_board <- nb_people_on_board - 1;
				nb_evacuated_people <- nb_evacuated_people + 1;
			}
			if LawEnforcement contains person {				
				nb_LEAs_on_board <- nb_LEAs_on_board - 1;
				nb_evacuated_LEAs <- nb_evacuated_LEAs + 1;
			}
			nb_humans_on_board <- nb_humans_on_board - 1;
			nb_evacuated_humans <- nb_evacuated_humans + 1;
			ask person {	
				do die;
			}
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
 			if evac_order_issuance_time > time_needed_to_issue_LEA_order {
 				write self.name + ": evacuation order issued to LEAs.";
 				issue_LEAs_order <- true;
 			} 
  			if evac_order_issuance_time >= time_needed_to_issue_evac_order {
  				write self.name + ": evacuation order issued.";
 				issue_evacuation_order <- true;
 			}
		}
 	}
 	// EVACUATION ORDER 
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
 	bool ITalert <- false; 
 	float ITalert_issuance_time <- 0 #s;
 	float time_needed_to_issue_ITalert <- 0 #s;
 	reflex alert_people_with_ITalert when: !empty(People - alerted_people) and issue_evacuation_order = true and ITalert = true {	
 		ITalert_issuance_time <- ITalert_issuance_time + step; 
 		if ITalert_issuance_time >= time_needed_to_issue_ITalert {
 			write "(" + time + ")" + self.name + ": issued ITalert message.";
 			loop person over: People {
 				ask person {
 					do add_belief(evacuation_order);	 					
 				}
	 		} 			
	 		alerted_people <- list(People);
 		}
 		if save_data {
 			map event_map <- [
				"time" :: time,
				"name" :: "Population Evacuation Order - IT Alert issued",
				"notes" :: "Civil defense ordered evacuation of civil population using IT Alert."
			];
			simulation_events_recorder <+ event_map;
 		}
 	}
 		//law enforcement 	
 	list<LawEnforcement> alerted_law_enforcement <- []; 
 	reflex evacuate_law_enforcement when: nb_people_on_island = 0 and !empty(LawEnforcement - alerted_law_enforcement) {
 		write self.name + ": LEAs must evacuate now."; 
 		loop person over: LawEnforcement {
 			ask person {
 				//list<predicate> current_person_believes <- get_beliefs collect (predicate(get_predicate(mental_state (each))));
 				predicate current_person_intention <- predicate(get_predicate(get_current_intention()));
 				do remove_intention(current_person_intention , true);
 				do remove_all_beliefs;
				do add_belief(evacuation_order);
 			}
 			//write "DEBUG: " + person.name + person.belief_base + person.intention_base;
 		}
 		alerted_law_enforcement <- list(LawEnforcement);
 		if save_data {
 			map event_map <- [
				"time" :: time,
				"name" :: "LEAs Evacuation Order",
				"notes" :: "Civil defense ordered evacuation of Law Enforcement Agents."
			];
			simulation_events_recorder <+ event_map;
 		}
 	}
	//LAW ENFORCEMENT AGENTS MANAGEMENT
	bool issue_LEAs_order <- false;
 	float time_needed_to_issue_LEA_order <- 0 #s;
 	map<string,unknown> manage_LEAs_map <- glob_manage_LEAs_map;
 	int ordering_evac_LEAs_nb;
 	bool should_create_backups;
 	unknown backup_init_location;
 	int backup_init_nb;
 	float backup_waiting_time <- 0.0 #s;
 	float backup_arrival_time;
 	init {
	 	if ITalert = false {ordering_evac_LEAs_nb <- int(manage_LEAs_map["give evacuation order"]);}
 		should_create_backups <- bool(manage_LEAs_map["backup"]["should create backups"]); 	
 		if should_create_backups {
 			backup_init_location <- string(manage_LEAs_map["backup"]["location"]);
 			backup_init_nb <- int(manage_LEAs_map["backup"]["number"]);
 			backup_arrival_time <- float(manage_LEAs_map["backup"]["arrival time"]);
 		}
 	} 
 	reflex create_backups when: should_create_backups {
 		backup_waiting_time <- backup_waiting_time + step;
 		if backup_waiting_time >= backup_arrival_time {
 			LEAs_order_was_fulfilled <- false;
 			if backup_init_nb > 0 {
	 			create LawEnforcement number: backup_init_nb {
					if flip(0.8) {location <- (first_with(Port,each.name = "Porto di Levante")).location;}
					else {location <- (first_with(Port,each.name = "Molo di protezione civile di Gelso")).location;}
	 			} 				
	 			nb_humans_on_island <- nb_humans_on_island + backup_init_nb;
	 			write "DEBUG: backups created.";
 			}
 			nb_LEAs_on_island <- nb_LEAs_on_island + backup_init_nb;
 			should_create_backups <- false;
 			if save_data {
	 			map event_map <- [
					"time" :: time,
					"name" :: "Backups Reached Vulcano",
					"notes" :: string(backup_init_nb) + " backup LEAs arrived on the Island. Ordered by Civil Defense at " + (time-backup_arrival_time+1)
				];
				simulation_events_recorder <+ event_map;
		 	}
 		}
 	}
 	
 	list<LawEnforcement> patroling_LEAs;
 	list<LawEnforcement> ordering_evac_LEAs;
 	list<agent> covered_areas <- [];
 	list<agent> ports_on_island <- Port where(each.name != "Porto di Milazzo");
 	list<agent> heliports_on_island <- Heliport where(!contains(["Nave 1", "Ospedale di Milazzo", "ZAE Cratere"], each.name));
 	list<agent> areas_to_cover <- ports_on_island + list(Waiting_Areas) + heliports_on_island;
 	bool LEAs_order_was_fulfilled <- false;
 	reflex order_LEAs_to_patrol_designated_areas when: issue_LEAs_order and LEAs_order_was_fulfilled = false {
 		list<LawEnforcement> available_LEAs <- LawEnforcement - patroling_LEAs - ordering_evac_LEAs;
 		list<LawEnforcement> available_LEAs_copy; 
 		loop while: LEAs_order_was_fulfilled = false {
 			//Assign LEAs to patrol areas 
	 		if !empty(areas_to_cover - covered_areas) {
	 			list<agent> covered_areas_temp;
		 		loop area_to_patrol over: (list(areas_to_cover) - covered_areas) {
		 			list<LawEnforcement> LEAs_to_dispatch;
		 			if length(available_LEAs) > 2*length(list(areas_to_cover)) {LEAs_to_dispatch <- available_LEAs closest_to(area_to_patrol, 2);}
		 			else {LEAs_to_dispatch <- available_LEAs closest_to(area_to_patrol, 1);}
		 			loop LEA over: LEAs_to_dispatch {	 				
		 				ask LEA {
			 				predicate current_person_intention <- predicate(get_predicate(get_current_intention()));
			 				do remove_intention(current_person_intention, true);
		 					area_to_presidiate_location <- area_to_patrol.location;
		 					do add_desire(block_access);
		 				}
		 				available_LEAs >- LEA;
		 				patroling_LEAs <+ LEA;
		 			}
		 			covered_areas_temp <+ area_to_patrol;
		 			if empty(available_LEAs) {
		 				LEAs_order_was_fulfilled <- true;
		 				break;
		 			}
		 		}
		 		loop area over: covered_areas_temp {covered_areas <+ area;}
	 		}
	 		//Assign LEAs to patrol areas if there are LEAs remaining
	 		else {
	 			if length(ordering_evac_LEAs)>=ordering_evac_LEAs_nb or ITalert = true {
		 			available_LEAs <- LawEnforcement - patroling_LEAs - ordering_evac_LEAs;
		 			available_LEAs_copy <- [];
		 			loop LEA over: available_LEAs{available_LEAs_copy <+ LEA;}
		 			loop LEA over: available_LEAs_copy {
		 				agent area_to_patrol <- one_of(areas_to_cover);  
		 				ask LEA {
			 				predicate current_person_intention <- predicate(get_predicate(get_current_intention()));
			 				do remove_intention(current_person_intention, true);
		 					area_to_presidiate_location <- area_to_patrol.location;
		 					do add_desire(block_access);
			 			}
		 				available_LEAs >- LEA;
		 				patroling_LEAs <+ LEA;
		 			}
	 				LEAs_order_was_fulfilled <- true;
 				}
	 		}
 			available_LEAs <- LawEnforcement - patroling_LEAs - ordering_evac_LEAs;
			available_LEAs_copy <- [];
			loop LEA over: available_LEAs{available_LEAs_copy <+ LEA;}
			//Assign LEAs to issue evacuation order
	 		if ITalert = false and length(ordering_evac_LEAs)<ordering_evac_LEAs_nb {
		 		if save_data {
		 			map event_map <- [
						"time" :: time,
						"name" :: "Population Evacuation Order - LEAs issued",
						"notes" :: "Civil defense ordered LEAs to issue evacuation order of civil population."
					];
					simulation_events_recorder <+ event_map;
			 	}
	 			loop LEA over: available_LEAs_copy {
		 			ask LEA {
		 				predicate current_person_intention <- predicate(get_predicate(get_current_intention()));
		 				do remove_intention(current_person_intention, true);
						do add_desire(alert_population);
		 			}	 				
	 				available_LEAs >- LEA;
	 				ordering_evac_LEAs <+ LEA;
		 			if length(ordering_evac_LEAs)=ordering_evac_LEAs_nb {break;}
	 			}
	 			if empty(available_LEAs) {
	 				LEAs_order_was_fulfilled <- true;
	 				break;
	 			}
	 		}
	 		
 		}	
 	}
 	bool everybody_is_alerted <- false;
 	reflex switch_from_evac_order_to_patrol when: ITalert = false and !everybody_is_alerted and nb_people_warned = length(People) {
		write self.name + ": LEAs who were issuing evacuation order must go patroling.";
		loop LEA over: ordering_evac_LEAs{
			ask LEA {
 				predicate current_person_intention <- predicate(get_predicate(get_current_intention()));
 				do remove_intention(current_person_intention, true);
				area_to_presidiate_location <- (myself.areas_to_cover closest_to self).location;
				do add_desire(block_access);
 			}
		}
		if save_data {
 			map event_map <- [
				"time" :: time,
				"name" :: "Population Evacuation Order - LEAs fulfilled",
				"notes" :: "The evacuation order of civil population issuing was fulfilled by LEAs."
			];
			simulation_events_recorder <+ event_map;
	 	}
 		everybody_is_alerted <- true;
 	}
 	
 	reflex monitor_evacuation_status when: issue_evacuation_order {
 		nb_people_warned <- length(People where (each.has_belief(predicate(each.evacuation_order))));
		nb_people_prepared <- length(People where (each.has_belief(predicate(each.prepared_to_evacuate))));
		nb_people_enjoying_their_time <- length(People where (each.has_desire(predicate(each.enjoying_my_time))));
		nb_people_making_a_decision <- length(People where (each.has_desire(predicate(each.need_evac_decision))));
		nb_people_going_to_port <- length(People where (each.has_belief(predicate(each.going_to_port))));
		nb_people_rescuing_others <- length(People where (each.has_belief(predicate(each.going_rescue_someone))));
		nb_people_waiting <- length(People where (each.has_belief(predicate(each.waiting_for_someone))));
		nb_people_going_to_safe_area <- length(People where (each.has_belief(predicate(each.going_to_safe_area))));
		nb_people_at_port <- length(People where (each.has_belief(predicate(each.in_target_port))));
		nb_people_who_left_the_island <- length(People where (each.has_belief(predicate(each.left_the_island))));
 	} 
 	reflex monitor_emotional_status {
 		nb_fearful_people <- 0;
 		nb_joyous_people <- 0;
 		nb_alright_people <- 0;
 		float fear_threshold <- 0.6;
 		float joy_threshold <- 0.3;
 		loop person over: People {
 			bool is_fearful <- false;
 			bool is_joyous <- false;
 			ask person {
	 			if person.has_emotion(fearEruption) {
					float fear_intensity <- get_intensity(get_emotion(fearEruption));
					if fear_intensity >= fear_threshold {is_fearful <- true;}
				}
				if person.has_emotion(joyPort) {
					float joy_intensity <- get_intensity(get_emotion(joyPort));
					if joy_intensity >= joy_threshold {is_joyous <- true;}
				}
 			}
 			if is_fearful {nb_fearful_people <- nb_fearful_people + 1;}
 			if is_joyous {nb_joyous_people <- nb_joyous_people + 1;}
 			if !is_fearful and !is_joyous {nb_alright_people <- nb_alright_people + 1;}
 		}
 	}
 	
 	// MANAGING EVACUATION INFRASTRUCTURES 
	list<Port> ports_to_evacuate;
	float send_ferry_decision_time <- 600 #s;
	float send_helicopter_decision_time <- 600 #s;
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
  				if port_decision_time_map[port.name] > send_ferry_decision_time {
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
  				if heliport_decision_time_map[heliport.name] > send_helicopter_decision_time {
 					heliports_to_evacuate <+ Heliport(heliport); 				
 				//string debug_name <- heliport.name; as much as it is weird, this line prevents a bug (not actually passing port), even though it is commented out 				
 				}
 			}
 		}
	}
 	action update_infrstructure_viability {}
 	// MANAGING EVACUATION VEHICLES
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
				//(not supported yet) add support to load from .json files 
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
    	int old_activity_level <- self.activity_level;
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
    	if save_data {
    		map event_map <- [
    			"time" :: time,
    			"name" :: "Volcanic Activity Update",
    			"notes" :: "Volcano " + self.name + "went from activity level " + old_activity_level + " to " + self.activity_level
    		];
    		simulation_events_recorder <+ event_map;
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
		if save_data {
			map boom_recorder <- [
				"time" :: time, 
				"activity name" :: "Boom Emission", 
				"activity params" :: ["intensity" :: intensity]
			];
			volcanic_activity_recorder <+ boom_recorder;
		}
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
								//can expand to insert personality in (belief) lifetime 
								int lifetime <- int((600 #s)*(myself.intensity+1)/step);
								do add_belief(new_predicate("Boom", ["intensity" :: myself.intensity]), 1.0, lifetime);
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
	init {
		use_emotions_architecture <- true; 
		use_social_architecture <- true;	
		use_personality <- true;	
	}
	//enviornment-related variables
	float view_dist <- 30 #m;
	float walking_speed <- 5 #km/#h;
	float vehicle_speed <- 25 #km/#h;
	//boarding-related variables
	EvacuationInfrastructure place_to_evacuate_from;
	Port port_to_evacuate_from;
	bool decided_to_board;
	EvacuationVehicle boarded_vehicle <- nil;
	bool boarded <- false;
 	// ISLAND EVACUATION
	predicate evacuation_order <- new_predicate("evacuation order");
	predicate at_target_port <- new_predicate("at target port"); 
	predicate in_target_port <- new_predicate("in target port");
	predicate left_the_island <- new_predicate("left the island");
	list<string> my_communicated_statuses <- [];
	predicate communicate_status <- new_predicate("communicate status");
	predicate need_boarding_decision <- new_predicate("need to take a decision on whether to board");

	perceive target: port_to_evacuate_from in: 10 #m {
		ask myself{
			do remove_intention(predicate(get_predicate(get_current_intention())), true);
			do add_desire(in_target_port);
		}
	}
	
	plan go_to_nearest_port intention: at_target_port {
		if !(last(self.my_communicated_statuses) = "going to port") {
			do add_subintention(get_current_intention(), communicate_status, true);	
			do current_intention_on_hold();				
		}
		port_to_evacuate_from <- Port closest_to(self);
		do goto target: port_to_evacuate_from on: road_network speed: walking_speed;
	}
	
	plan wait_to_board intention: in_target_port {
		if location != port_to_evacuate_from.location {
			do goto target: port_to_evacuate_from on: road_network speed: walking_speed;
		}
		else {
			if !(self.has_belief(in_target_port)) {do add_belief(in_target_port);}
			if self in port_to_evacuate_from.people_waiting_list = false and boarded_vehicle = nil{
				add self to: port_to_evacuate_from.people_waiting_list;
				port_to_evacuate_from.people_with_no_assigned_vehicle <- port_to_evacuate_from.people_with_no_assigned_vehicle + 1;
				//write "DEBUG: " + port_to_evacuate_from.name + "-" + port_to_evacuate_from.people_waiting_list;
			}
		}
		if location = port_to_evacuate_from.location and People contains self {
			if !(last(self.my_communicated_statuses) = "at port") {
				do add_subintention(get_current_intention(), communicate_status, true);		
				do current_intention_on_hold();							
			}
		} 
	} 
	
	bool want_to_board {
		bool boarding_decision;
		//people	
		if People contains self {
			People me <- People(self);
			list<People> friends_I_worry_about <- list<People>((self.social_link_base where (each.liking > 0.5)) collect each.agent);
			if !empty(friends_I_worry_about) {
				list<predicate> my_friend_statuses <- get_beliefs_with_name("friend status") collect (predicate(get_predicate(mental_state (each))));
				list<predicate> my_close_friends_statuses <- [];
				loop close_friend over: friends_I_worry_about {
					predicate close_friend_status <- my_friend_statuses first_with ((each).values["name"] = close_friend.name);
					my_close_friends_statuses <+ close_friend_status; 
				}			
				int nb_cf_safe <- my_close_friends_statuses count (each.values["status"] = 'at port' or each.values["status"] = 'on board');
				float perc_cf_safe <- nb_cf_safe /length(friends_I_worry_about);
				float joy_intensity <- 0.0;
				if has_emotion(joyPort) {joy_intensity <- get_intensity(get_emotion(joyPort));}
				write self.name + "has: " + perc_cf_safe + "% close friends safe and has joy equal to " + joy_intensity;
				if joy_intensity >= 0.7 {boarding_decision <- true;}
				else if joy_intensity >= 0.3 and joy_intensity < 0.7{
					if perc_cf_safe >= 0.5 {boarding_decision <- true;}
					else {boarding_decision <- false;}
				}
				else {
					if perc_cf_safe >= 0.7 {boarding_decision <- true;}
					else {boarding_decision <- false;}
				}
			}
			else {
				boarding_decision <- true;
			}		
		}
		//LawEnforcement
		else {
			boarding_decision <- true;
		}
		return boarding_decision;	
	}
	
	reflex on_board when: boarded = true { 
		if People contains self and !(last(self.my_communicated_statuses) = "on board"){
			do add_subintention(get_current_intention(), communicate_status, true);		
			do current_intention_on_hold();							
		}
		//speed <- boarded_vehicle.speed; 
		//location <- boarded_vehicle.location; 
		do goto target: boarded_vehicle.location speed: boarded_vehicle.speed on:ferry_network; //computes much faster
	}
	
	//EMOTIONs
	emotion joyPort <- new_emotion("joy", in_target_port);

}
/*
 * PEOPLE
 */
 species People parent: Human{
	
	//customiaztion variables	
	rgb color <- #blue;
	
	//init
	init {
		do add_desire(enjoying_my_time);
		do add_desire(noEruption, 1.0);
		
		openness <- /*1.0;*/gauss(0.5,0.12);	
		conscientiousness <- /*1.0;*/gauss(0.5,0.12); 
		extroversion <- /*1.0;*/gauss(0.5,0.12);
		agreeableness <- /*1.0;*/gauss(0.5,0.12);
		neurotism <- /*1.0;*/gauss(0.5,0.12);
	}
	
	//MOVEMENT and EVACUATION
		//before evacuation
	predicate enjoying_my_time <- new_predicate("enjoying my time");
	plan lets_wander intention: enjoying_my_time {
		do wander on: road_network speed: walking_speed;
	}
		//PREDICATES
		//decision process
	predicate need_evac_decision <- new_predicate("need to take a decision on whether to evacuate");
	predicate took_evac_decision <- new_predicate("took an evacuation decision");
		//preparing
	predicate preparing <- new_predicate("preparing to evacuate");
	predicate prepared_to_evacuate <- new_predicate("prepared to evacuate");
	float time_spent_preparing <- 0 #s;
	float total_preparing_time <- 600 #s;
		//evacuation
	predicate going_to_port <- new_predicate("decided to go to port"); 
	predicate going_rescue_someone <- new_predicate("decided to go rescue someone");
	predicate rescue_someone <- new_predicate("rescue someone");
	predicate waiting_for_someone <- new_predicate("decided to wait for someone");
	predicate wait_someone <- new_predicate("wait for someone to come here");
	predicate going_to_safe_area <- new_predicate("decided to go to nearest evacuation infrastructure");
	predicate at_safe_area <- new_predicate("going to nearest evacuation infrastructure");
		//RULES and ACTIONS
		// 1) prende una prima decisione 
	rule belief: evacuation_order remove_desire: enjoying_my_time new_desire: need_evac_decision when: self.has_desire(enjoying_my_time) and !(self.has_belief(took_evac_decision));
	rule emotion: fearEruption remove_desire: enjoying_my_time new_desire: need_evac_decision when: self.has_desire(enjoying_my_time) and !(self.has_belief(took_evac_decision)) and (get_intensity(get_emotion(fearEruption)) >= 0.6);
		// 2) si deve preparare
	rule belief: one_of([going_to_port, going_rescue_someone, waiting_for_someone, going_to_safe_area]) remove_intention: need_evac_decision remove_desire: need_evac_decision new_desire: preparing when: !(self.has_belief(prepared_to_evacuate));
		// 3) deve fare ciò che ha scelto
	rule belief: prepared_to_evacuate remove_intention: preparing remove_desire: preparing;
	rule belief: going_to_port new_desire: at_target_port when: self.has_belief(prepared_to_evacuate) and !(self.has_desire(at_target_port));
	rule belief: going_rescue_someone new_desire: rescue_someone when: self.has_belief(prepared_to_evacuate) and !(self.has_desire(rescue_someone));
	rule belief: waiting_for_someone new_desire: wait_someone when: self.has_belief(prepared_to_evacuate) and !(self.has_desire(wait_someone));
	rule belief: going_to_safe_area new_desire: at_safe_area when: self.has_belief(prepared_to_evacuate) and !(self.has_desire(wait_someone));
	rule belief: one_of([going_to_port, going_rescue_someone, waiting_for_someone, going_to_safe_area]) remove_intention: need_evac_decision remove_desire: need_evac_decision when: self.has_belief(prepared_to_evacuate);
		// 4) deve poter decidere di nuovo se la decisione è scaduta se è al porto deve aspettare e basta
	rule new_desire: need_evac_decision remove_intention: predicate(get_predicate(get_current_intention())) remove_desire: predicate(get_predicate(get_current_intention())) remove_beliefs: [going_to_port, going_rescue_someone, waiting_for_someone] when: !(self.has_desire(enjoying_my_time)) and !(self.has_belief(took_evac_decision)) and !(self.has_desire(in_target_port));
	rule remove_beliefs: [going_to_port, going_to_safe_area, waiting_for_someone, going_rescue_someone] when: self.has_belief(in_target_port);
	rule remove_beliefs: [going_to_safe_area, waiting_for_someone, going_rescue_someone] when: self.has_belief(going_to_port); 
	action get_to_port{
		predicate my_current_intention <- predicate(get_predicate(get_current_intention()));
		do remove_intention(my_current_intention, true);
		do add_belief(going_to_port);		
	}
		//PLANS
		//decision process
	plan choose_whether_to_evacuate intention: need_evac_decision when: !(self.has_belief(took_evac_decision)){
		//TODO: MANCA DA FARE IL DEBUG IF THE PLAN IS CORRECTLY EXECUTED
		//setting decision lifetime
		int decision_lifetime;
		if empty(my_communicated_statuses){
			decision_lifetime <- int(max([300#s/step,1800#s/step*conscientiousness]) + total_preparing_time);
		}
		else {			
			decision_lifetime <- int(max([300#s/step,1800#s/step*conscientiousness]));
		}
		//choosing next plan
		if flip(0){
			//rational
			if extroversion >= 0.8 and empty(my_communicated_statuses) {
				do add_belief(waiting_for_someone, 1.0, -1);
			}
			else if self.has_emotion(fearEruption) {
				float fear_intensity <- get_intensity(get_emotion(fearEruption));
				if fear_intensity >= 0.6 {
					do add_belief(going_to_safe_area, 1.0, decision_lifetime);
				}
				else{
					if agreeableness >= 0.6 {do add_belief(going_rescue_someone, 1.0, decision_lifetime);}
					else {do add_belief(going_to_port, 1.0, decision_lifetime);}
				}
			}
			else {
				if agreeableness >= 0.6 {do add_belief(going_rescue_someone, 1.0, decision_lifetime);}
				else {do add_belief(going_to_port, 1.0, decision_lifetime);}
			}
		}
		else{
			//irrational
			string chosen_plan;
			if empty(my_communicated_statuses){
				chosen_plan <- rnd_choice(["port"::0.0, "rescue"::0.0, "waiting area"::1.0, "wait someone"::0.0]);
				//chosen_plan <- rnd_choice(["port"::0.25, "rescue"::0.25, "waiting area"::0.25, "wait someone"::0.25]);
			}
			else {
				chosen_plan <- rnd_choice(["port"::0.0, "rescue"::0.0, "waiting area"::1.0]);
				//chosen_plan <- rnd_choice(["port"::0.34, "rescue"::0.33, "waiting area"::0.33]);
			}
			// write "DEBUG: " + self.name + " acted irrationally by chosing " + chosen_plan;
			if chosen_plan = "port" {do add_belief(going_to_port, 1.0, decision_lifetime);
				write "DEBUG: " + self.name + " chose " + chosen_plan;
			}
			else if chosen_plan = "rescue" {do add_belief(going_rescue_someone, 1.0, decision_lifetime);
				write "DEBUG: " + self.name + " chose " + chosen_plan;
			}
			else if chosen_plan = "waiting area" {do add_belief(going_to_safe_area, 1.0, decision_lifetime);
				write "DEBUG: " + self.name + " chose " + chosen_plan;
			}
			else if chosen_plan = "wait someone" {do add_belief(waiting_for_someone, 1.0, -1);
				write "DEBUG: " + self.name + " chose " + chosen_plan;
			}
			else {write "ERROR: Error in decision process of " + self.name;}
		}
		do add_belief(took_evac_decision, 1.0, decision_lifetime);
		if has_belief(took_evac_decision){
			write self.name + " - " + belief_base;
		}
	}
	
	reflex ciaone {
		//write name + " check - " + belief_base;
	}
		
		//preparing 
	plan prepare intention: preparing {
		time_spent_preparing <- time_spent_preparing + step;
		if time_spent_preparing >= total_preparing_time {
			if self.has_belief(going_to_port) {
				do remove_intention(preparing, true);
				do add_desire(at_target_port);
				do add_belief(prepared_to_evacuate);	
			}
			else if self.has_belief(going_rescue_someone) {
				do add_desire(rescue_someone);
				do add_belief(prepared_to_evacuate);
			}
			else if self.has_belief(waiting_for_someone) {
				do add_desire(wait_someone);
				do add_belief(prepared_to_evacuate);
			}
			else if self.has_belief(going_to_safe_area) {
				do add_desire(at_safe_area);
				do add_belief(prepared_to_evacuate);
			}
		}
	}
		//rescuing friends
	predicate no_friend_needs_help <- new_predicate("no friend needs help");
	predicate friend_is_here <- new_predicate("my friend is here");
	predicate nobody_came <- new_predicate("no friend showed up");
	People friend_to_rescue;
	list<People> attempted_rescue_friends <- [];
	action select_friend_to_help {
		list<string> help_statuses <- ["unknown", "waiting"];
		list<People> friends_that_might_need_help;
		list<predicate> my_friends_statuses <- get_beliefs_with_name("friend status") collect (predicate(get_predicate(mental_state (each))));
		loop fr_stat over: my_friends_statuses {
			if help_statuses contains fr_stat.values["status"] {
				friends_that_might_need_help <+ my_friends first_with(each.name = fr_stat.values["name"]);
			}
		}
		if !empty(attempted_rescue_friends) {
			loop friend over: friends_that_might_need_help {
				if attempted_rescue_friends contains friend {friends_that_might_need_help >- friend;}
			}
		}
		if !empty(friends_that_might_need_help) {
			list<social_link> friends_that_need_help_links <- self.social_link_base where (friends_that_might_need_help contains each.agent);
			social_link closest_friend_link <- friends_that_need_help_links first_with ((each.liking+each.familiarity) >= friends_that_need_help_links max_of(each.liking+each.familiarity));
			friend_to_rescue <- People(closest_friend_link.agent);			
		}
		else {do add_belief(no_friend_needs_help);}
	}
	plan go_rescue intention: rescue_someone {
		if !(last(self.my_communicated_statuses) = "rescuing") {
			do add_subintention(get_current_intention(), communicate_status, true);	
			do current_intention_on_hold();				
		}
		if !empty(my_friends) and friend_to_rescue = nil {
			do select_friend_to_help;
		}
		else if friend_to_rescue != nil and !(dead(friend_to_rescue)) {
			list<predicate> my_friends_statuses <- get_beliefs_with_name("friend status") collect (predicate(get_predicate(mental_state (each))));
			point friend_location <- (my_friends_statuses first_with ((each).values["name"] = friend_to_rescue.name)).values["location"];
			if self.location != friend_location {
				do goto target: friend_location on: road_network speed: walking_speed*1.5;
			}
			else{
				if self distance_to(friend_to_rescue) < 10 #m {
					bool friend_is_scared <- false;
					float fear_intensity;
					ask friend_to_rescue{
						if self.has_emotion(fearEruption) {
							fear_intensity <- get_intensity(get_emotion(fearEruption));
						}
						else{fear_intensity <- 0.0;}
					}
					if fear_intensity >= 0.5 {friend_is_scared <- true;}
					if !friend_is_scared {
						ask friend_to_rescue {do get_to_port;}	
						do get_to_port;
						//it would be cool to change speed so that they follow each other (e.g set speed to the minumum of their walking speed)
					}
					else{
						ask friend_to_rescue{
							social_link sl_with_rescuer <- first(self.social_link_base where (each.agent = myself));
							float dominance <- get_dominance(sl_with_rescuer);
							float fear_reduction_factor <- 0.001 * max(0.1, dominance);
							//TODO: debug this
							emotion fear_to_reduce <- get_emotion(fearEruption);
							fear_intensity <- fear_intensity * (1-fear_reduction_factor); 
							fear_to_reduce <- set_intensity(fear_to_reduce, fear_intensity); 
						}
					}	
				}		
				else{
					attempted_rescue_friends <+ friend_to_rescue;
					do get_to_port;
					//can be expanded to emotions (e.g. fear of my friend not being safe)
				}
			}
			if self distance_to(friend_to_rescue) < 150 #m and !(friend_to_rescue.has_belief(friend_is_here)){
				ask friend_to_rescue {
					do add_belief(new_predicate("my friend is here", ["person"::myself])); 
				}
			}
		}
		else if friend_to_rescue != nil and (dead(friend_to_rescue)) {
			attempted_rescue_friends <+ friend_to_rescue;
			do get_to_port;
		}
		else if empty(my_friends) and !self.has_belief(no_friend_needs_help) {do add_belief(no_friend_needs_help);}
		else if self.has_belief(no_friend_needs_help){do get_to_port;}	
	}
		//waiting for friends
	float maximum_waiting_time <- (rnd(int(4800*(0.5 + conscientiousness)), 18000, 600)) #s;
	float time_spent_waiting_for_someone_to_come <- 0 #s;
	plan wait_for_someone intention: wait_someone {
		if !(last(self.my_communicated_statuses) = "waiting") {
			do add_subintention(get_current_intention(), communicate_status, true);	
			do current_intention_on_hold();				
		}
		time_spent_waiting_for_someone_to_come <- time_spent_waiting_for_someone_to_come + step;
		if !self.has_belief(friend_is_here) and time_spent_waiting_for_someone_to_come > maximum_waiting_time {
			do add_belief(nobody_came);
			do get_to_port;
		}
	}
		//go to waiting areas
	plan go_to_safe_area intention: at_safe_area {
		EvacuationInfrastructure safe_area <- closest_to(Waiting_Areas+Port+Heliport,self);
		do goto target: safe_area.location on: road_network speed: walking_speed;
		if contains(Port,safe_area) {port_to_evacuate_from <- Port(safe_area);}
	}
	
	//SOCIAL LINKS
	list<People> my_friends;
	predicate friend_status;
	
	plan update_friends intention: communicate_status instantaneous: true {
		if self.has_belief(in_target_port) {do update_status_to_my_friends("at port");}
		else if self.has_belief(left_the_island) {do update_status_to_my_friends("on board");}
		else if self.has_desire(at_target_port) {do update_status_to_my_friends("going to port");}
		else if self.has_desire(rescue_someone) {do update_status_to_my_friends("rescuing");}
		else if self.has_desire(wait_someone) {do update_status_to_my_friends("waiting");}
		do remove_intention(communicate_status, true);
	}
	
	action update_status_to_my_friends(string status) {
		if status != last(my_communicated_statuses) {
			loop friend over: my_friends {
				ask friend {
					list<predicate> my_friend_statuses <- get_beliefs_with_name("friend status") collect (predicate(get_predicate(mental_state (each))));
					//write "DEBUG: " + my_friend_statuses;
					predicate my_friend_status_about_me <- my_friend_statuses first_with ((each).values["name"] = myself.name);
					//write "DEBUG: " + my_friend_status_about_me;
					do remove_belief(my_friend_status_about_me);
					map<string,unknown> my_status <- ["name":: myself.name, "location"::myself.location, "status":: status];
					do add_belief(new_predicate("friend status", my_status));
				}
			}
			self.my_communicated_statuses <+ status;			
			//write "DEBUG: " + self.name + " has updated belief base of " + my_friends;
		}
		else{}//No need to update status
	}

	//EMOTIONs

	//EMOTIONAL RESPONSE TO VOLCANIC ACTIVITIES
	predicate noEruption <- new_predicate("Eruption",false);
	predicate Eruption <- new_predicate("Eruption");
	emotion fearEruption <- new_emotion("fear", Eruption);
	rule emotion:fearEruption new_desire: need_evac_decision remove_intention:enjoying_my_time remove_desire:enjoying_my_time when: (self.is_current_intention(enjoying_my_time) and !(self.has_belief(took_evac_decision)) and get_intensity(self.get_emotion(fearEruption)) > 0.3);
		//response to boom sounds
	int max_perceived_boom_intensity <- int(18*(0.5 + neurotism));
	float perceived_boom_coefficient <- 0.0;
	predicate boomHeard <- new_predicate("Boom");
	//DEPRECATED: rule belief: boomHeard new_uncertainty:Eruption strength: perceived_boom_coefficient when: not has_belief(Eruption);
	
	reflex update_intensity when: self.has_belief(boomHeard) {
		int perceived_boom_intensity <- 0;
		perceived_boom_coefficient <- 0.0;
		list<predicate> boom_bf_list <- get_beliefs_with_name("Boom") collect (predicate(get_predicate(mental_state (each))));
		loop belief over: boom_bf_list {
			int single_intensity <- int(belief.values["intensity"]);
			//write "DEBUG: " + get_lifetime(one_of(get_belief_with_name("Boom")));
			perceived_boom_intensity <- perceived_boom_intensity + single_intensity; 
			if perceived_boom_intensity >= max_perceived_boom_intensity {
				perceived_boom_intensity <- max_perceived_boom_intensity;
				break;
			}
			perceived_boom_coefficient <- perceived_boom_intensity/max_perceived_boom_intensity;
		}
		//write "DEBUG: " + perceived_boom_intensity;
		if self.has_uncertainty(Eruption){
			mental_state current_uncertainty <- get_uncertainty_op(self, Eruption);
			float current_uncertainty_strength <- current_uncertainty.strength; 
			if current_uncertainty_strength = perceived_boom_coefficient{
				//write "DEBUG: NO need to update uncertainty for " + self.name;
			}
			else{
				do remove_uncertainty(Eruption);
				do remove_emotion(fearEruption);
				do add_uncertainty(Eruption, perceived_boom_coefficient);
				current_uncertainty <- get_uncertainty_op(self, Eruption);
				//write "DEBUG: Removed uncertainty of strength " + current_uncertainty_strength + " to update with " + current_uncertainty.strength + self.name;	
			}
		}
		else {
			do add_uncertainty(Eruption, perceived_boom_coefficient);
			//write "DEBUG: Added uncertainty of strength " + perceived_boom_coefficient + self.name;
		}
	}
	
	//EMOTIONAL CONTAGION 	

	float FearContagionThreshold <- 0.5;
	float JoyContagionThreshold <- 0.3;

	perceive target:People where each.has_emotion(fearEruption) in:view_dist {
		emotional_contagion emotion_detected:fearEruption threshold:FearContagionThreshold;
	}
	
	perceive target:People where each.has_emotion(joyPort) in: view_dist {
		emotional_contagion emotion_detected: joyPort threshold: JoyContagionThreshold;
	}	

	/* 
	 * //POSSIBLE EXPANSION IN THE EVENT OF IMPLEMENTING ACTUAL ERUPTIONS.
	 * float uncertaintyConversion <- 0.25;
	 * perceive target:People in:view_dist{
	 * 		if(has_belief(Eruption) and not myself.has_belief(Eruption)){
	 * 			focus id:"Eruption" strength: uncertaintyConversion is_uncertain:true;
	 * 		}
	 * }
	 */

	//ASPECT CUSTOMIZATION
	aspect default {
		draw triangle(5) rotate: heading + 90 color: color border: #black;
		draw circle(view_dist) color: color border: #black wireframe: true;
	}
}

/*
 * LAW ENFORCEMENT AGENT (LEA)
 */
 
species LawEnforcement parent: Human{
	rgb color <- #green;
	point area_to_presidiate_location;
	
	predicate on_duty_regular <- new_predicate("on duty regular");
	predicate block_access <- new_predicate("block access");
	predicate reached_patrol_area <- new_predicate("reached patrol area");
	predicate patrol <- new_predicate("patrol assigned area"); 
	predicate see_person <- new_predicate("see person");
	predicate warn_person <- new_predicate("warn person");
	
	rule belief: reached_patrol_area new_desire: patrol when: !(self.has_belief(evacuation_order));
	
	perceive target: People in: view_dist {
		focus id: "person seen" agent_cause: self;
		People person_seen <- self; 
		ask myself{
			do add_belief(new_predicate("see person", ["person"::person_seen]));
		}
	}
	
	plan block_paths intention: block_access {
        do goto target: area_to_presidiate_location on: road_network speed: vehicle_speed;
        if (self distance_to(area_to_presidiate_location) < 10 #m) { 
            do add_belief(new_predicate("reached patrol area", ["location_value"::area_to_presidiate_location]));
            do remove_intention(block_access, true);            
        }
    }
	
	plan patrol_area intention: patrol {
		if self.has_belief(see_person){
			do add_subintention(get_current_intention(), warn_person, true);
			do current_intention_on_hold();
		}
	}
	
	plan warn_people intention: warn_person {
		predicate person_seen <- predicate(get_predicate(get_belief_with_name("see person")));
		People person_to_warn <- person_seen.values["person"];
		ask person_to_warn {
			predicate current_person_intention <- predicate(get_predicate(get_current_intention()));
			if has_emotion(fearEruption){
				emotion fear_to_reduce <- get_emotion(fearEruption);
				//mental_state current_uncertainty <- get_uncertainty_op(self, Eruption);
				// write "DEBUG: uncertainty" + string(current_uncertainty) + " - strength: " + current_uncertainty.strength;
				//mental_state eruption_des <- get_desire_op(self, noEruption);
				//write "DEBUG: desire" + string(eruption_des) + " - strength: " + eruption_des.strength;
				float fear_intensity <- get_intensity(get_emotion(fearEruption));
				// write "DEBUG: " + myself.name + " - " + self.name + " Fear intensity 1: " + fear_intensity;
				if fear_intensity > 0.4 {
					float fear_reduction_factor <- 0.001 * max(0.1, neurotism);
					fear_intensity <- fear_intensity * (1 - fear_reduction_factor); 
					fear_to_reduce <- set_intensity(fear_to_reduce, fear_intensity); 
					// float fear_intensity_2 <- get_intensity(get_emotion(fearEruption));
					// write "DEBUG: " + myself.name + " - " + self.name + "Fear intensity 2: " + fear_intensity_2;
				}
				else{
					if current_person_intention != at_target_port and current_person_intention != in_target_port{
						//write "DEBUG:" + myself.name + " - " + person_seen;
						do get_to_port;
					}
				}
			}
			else{
				if current_person_intention != at_target_port and current_person_intention != in_target_port{
					//write "DEBUG:" + myself.name + " - " + person_seen;
					do get_to_port;
				}				
			}
		}
		do remove_intention(warn_person, true);
	}
	
	//alert people of evacuation 
	float alert_destination_min_distance <- 500 #m;
	float alert_population_radius <- 150 #m;
	predicate alert_population <- new_predicate("alert population");
	predicate perceived_person_to_alert <- new_predicate("perceived person to alert");
	predicate alert_person <- new_predicate("alert person");
	predicate already_alerted_person <- new_predicate("already alerted person");
	
	plan alert_population_of_evacuation_order intention: alert_population {
		predicate current_target <- new_predicate("current target");

		if !(self.has_belief(current_target)) { 
			point target; 
			loop while: target = nil or target distance_to(self) < alert_destination_min_distance {
				target <- any(road_network.vertices);
			}
			do add_belief(new_predicate("current target", ["destination"::target]));							
			}
		
		predicate target_belief <- predicate(get_predicate(get_belief_with_name("current target")));
		point target_location <- target_belief.values["destination"];
		do goto target: target_location on: road_network speed: vehicle_speed;

		if self.has_belief(perceived_person_to_alert) {
			do add_subintention(get_current_intention(), alert_person, true);
			do current_intention_on_hold();
		}
		
		if (self.location = target_location) {
			do remove_belief(current_target);
		}
	}
	
		perceive target: People in: alert_population_radius  {
			list<predicate> already_alerted_person_people_beliefs_list <- myself.get_beliefs_with_name("already alerted person") collect (predicate(get_predicate(mental_state (each))));
			list<predicate> perceived_people_beliefs_list <- myself.get_beliefs_with_name("perceived person to alert") collect (predicate(get_predicate(mental_state (each))));
			focus id: "peson perceived" agent_cause: self;
			People perceived_person <- self; 
			bool person_already_alerted_by_someone <- false;
			if empty(already_alerted_person_people_beliefs_list where (each.values["person"]=perceived_person)) {
				if perceived_person.has_belief(evacuation_order){
					//write "DEBUG: " + self.name + "was already alerted.";
					person_already_alerted_by_someone <- true;	
					ask myself {
						predicate to_alert_perceived_person_belief <- perceived_people_beliefs_list first_with (each.values["person"] = perceived_person);
						do remove_belief(to_alert_perceived_person_belief);
						do add_belief(new_predicate("already alerted person", ["person"::perceived_person]));
					}
				}
				if person_already_alerted_by_someone = false {
					ask myself{
						do add_belief(new_predicate("perceived person to alert", ["person"::perceived_person]));
					}			
				}
			}
	}	

	plan must_alert_person intention: alert_person {
		list<predicate> perceived_people_beliefs_list <- get_beliefs_with_name("perceived person to alert") collect (predicate(get_predicate(mental_state (each))));
		loop belief over: perceived_people_beliefs_list {
			predicate person_to_alert_belief <- belief;
			People person_to_alert <- person_to_alert_belief.values["person"];
			ask person_to_alert {do add_belief(evacuation_order);}
		}
		do remove_intention(alert_person, true);
	}
	
	//EVACUATION
	predicate evacuate <- new_predicate("evacuate");
	predicate lets_leave <- new_predicate("lets_leave");
	
	perceive target: place_to_evacuate_from in: 10 #m {
		ask myself{
			do remove_intention(evacuate, true);
			do add_desire(lets_leave);
		}
	}
	rule belief: evacuation_order new_desire: evacuate;
	
	plan evacuate intention: evacuate {
		//write "DEBUG: " + self.name + "Leaving Island.";
		list<EvacuationInfrastructure> PortsHeliports <- list(Port) + list(Heliport);
		place_to_evacuate_from <- PortsHeliports closest_to(self);
		do goto target: place_to_evacuate_from on: road_network speed: vehicle_speed;
	}
	
	plan wait_to_leave_island intention: lets_leave {
		if location != place_to_evacuate_from.location {
			do goto target: place_to_evacuate_from on: road_network speed: walking_speed;
		}
		else {
			if self in place_to_evacuate_from.people_waiting_list = false and boarded_vehicle = nil{
				add self to: place_to_evacuate_from.people_waiting_list;
				place_to_evacuate_from.people_with_no_assigned_vehicle <- place_to_evacuate_from.people_with_no_assigned_vehicle + 1;
			}
		}	
	}
	
	
    aspect default {
    	
		if has_intention_op(self, predicate("patrol assigned area")) {			
			draw circle(5) rotate: heading + 90 color: #yellow;
			draw circle(view_dist) color: #yellow border: #yellow wireframe: true;
		}
		else if has_intention_op(self, predicate("alert population")) {
			draw triangle(5) rotate: heading + 90 color: #orange;
			draw circle(alert_population_radius) color: rgb(1,0,0,0.3);
		} 
    	else {
    		draw triangle(5) rotate: heading + 90 color: color;
    		draw circle(view_dist) color: color border: color wireframe: true;
    	}
    }
    
}
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
				self.people_with_no_assigned_vehicle <- self.people_with_no_assigned_vehicle + myself.capacity - myself.people_on_board;
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
	       species LawEnforcement;
	    }
	}
}

experiment "show simulation_with_charts" type: gui {    
	int refresh_rate <- 120 #cycles; 
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
   	       species LawEnforcement;
	    }
		display "Evacuation Info" refresh: every(refresh_rate) {
	       chart "Humans evacuated successfully" type: series size: {1,0.5} position: {0,0}{
		       	data "Humans successfully evacuated" value: nb_evacuated_humans color: #green;
		       	data "Humans on board" value: nb_humans_on_board color: #blue;
		       	data "Humans still to evacuate" value: nb_humans_on_island color: #red;
	       }
	       chart "People evacuated successfully" type: series size: {0.5,0.5} position: {0,0.5} {
		       	data "People successfully evacuated" value: nb_evacuated_people color: #green;
		       	data "People on board" value: nb_people_on_board color: #blue;
		       	data "People still to evacuate" value: nb_people_on_island color: #red;
	       }
	       chart "LawEnforcement evacuated successfully" type: series size: {0.5,0.5} position: {0.5,0.5} {
	       		data "LEAs successfully evacuated" value: nb_evacuated_LEAs color: #green;
		       	data "LEAs on board" value: nb_LEAs_on_board color: #blue;
		       	data "LEAs still to evacuate" value: nb_LEAs_on_island color: #red;
	       }
       }
       display "Behavioural Info" refresh: every(refresh_rate){
	       chart "People behaviour - Timeseries" type: series size: {0.5, 0.5} position: {0,0} {
	       		data "warned" value: nb_people_warned color: #yellow;
	       		data "prepared" value: nb_people_prepared color: #orange;
	       		data "enjoying their time" value: nb_people_enjoying_their_time color: #darkred;
	       		data "going to port" value: nb_people_going_to_port color: #blue;
	       		data "rescuing" value: nb_people_rescuing_others color: #red;
	       		data "waiting help" value: nb_people_waiting color: #black;
	       		data "going to safe area" value: nb_people_going_to_safe_area color: #darkblue;
	       		data "at port" value: nb_people_at_port color: #grey;
	       		data "left island" value: nb_people_who_left_the_island color: #green;
	       }
	       chart "People emotions" type: series size: {0.5, 0.5} position: {0.5,0} {
	       		data "joyous" value: nb_joyous_people color: #darkgreen;
	       		data "fearful" value: nb_fearful_people color: #purple;
	       		data "normal" value: nb_alright_people color: #grey;
	       }
	       chart "People behaviour - Histogram" type: histogram size: {1, 0.5} position: {0,0.5} {
	       		data "warned" value: nb_people_warned color: #yellow;
	       		data "prepared" value: nb_people_prepared color: #orange;
	       		data "enjoying their time" value: nb_people_enjoying_their_time color: #darkred;
	       		data "going to port" value: nb_people_going_to_port color: #blue;
	       		data "rescuing" value: nb_people_rescuing_others color: #red;
	       		data "waiting help" value: nb_people_waiting color: #black;
	       		data "going to safe area" value: nb_people_going_to_safe_area color: #darkblue;
	       		data "at port" value: nb_people_at_port color: #grey;
	       		data "left island" value: nb_people_who_left_the_island color: #green;
	       }			  
		}	       
	}
}


experiment multiple_runs type:batch until:simulation_ended repeat:1 parallel:true{
	parameter "nb groups" var:seed min:1.0 max:42.0;
	method exploration;
}

