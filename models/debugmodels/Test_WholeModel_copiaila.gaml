model TestModel

global {
	//gloal variables for results
		//evacuation variables
	int nb_humans_on_island; //done
	int nb_people_on_island; //done
	int nb_humans_on_board;  //done
	int nb_people_on_board;  //done
	int nb_evacuated_humans; //done
	int nb_evacuated_people; //done
	//TODO: update the following in the code
		//people status variables
	int nb_people_warned; //done 
	int nb_people_prepared; //done
	int nb_people_going_to_port; //done (missing belief removal, for this and all the following, at least the temporary ones)
	int nb_people_rescuing_others; //done
	int nb_people_waiting; //done
	int nb_people_at_port; //missing belief
	int nb_people_who_left_the_island; //done
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
	//TODO: add ferry and heli data 
	/* 
	 * PARAMETER INITIALIZIATION
	 */
	 	//volcano
	map glob_eruption_engine_params_map <- [
		"RoaringSoundEmission" :: roaring_sound_emission_map
	];
	map roaring_sound_emission_map <- [
		"lambda" :: 10
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
		"number":: 50,
		"arrival time":: 6000 #s
	];
	
		//people
	float preparing_time_avg <- 600 #s;
	float preparing_time_std <- 300 #s;
		
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
		 	ITalert <- ITalert_glob;
		 }
		 /*
		  * CREATING PEOPLE
		  */
		create People number: 50 {
			speed <- 30 #km/#h;
			view_dist <- 30 #m;
			if flip(1/2) {location <- any_location_in(one_of(Buildings));}
			else {location <- any_location_in(one_of(Roads));}
			total_preparing_time <- truncated_gauss({preparing_time_avg, preparing_time_std})#s;
			total_preparing_time <- 0 #s;
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
		create LawEnforcement number: 40 {
			float location_extraction <- rnd(1.0);
			if location_extraction <= 0.80 {
				float port_location_extraction <- rnd(1.0);
				if port_location_extraction <= 0.80 {location <- (first_with(Port,each.name = "Porto di Levante")).location;}
				else if port_location_extraction <= 0.80 + 0.15 {location <- (first_with(Port,each.name = "Molo di protezione civile di Gelso")).location;}
				else {location <- (first_with(Port,each.name = "Molo di protezione civile di Ponente")).location;}
			}
			else if location_extraction <= 0.80 + 0.0 {/*TODO: add caserma dei carabinieri*/}
			else {location <- any_location_in(one_of(road_network.vertices));}
			speed <-  50#km/#h;	  	
			//area_to_presidiate_location <- one_of(Waiting_Areas).location;
			//do add_desire(block_access); 		
			do add_desire(on_duty_regular);
		}
		 /*
		  * CREATING FERRIES AND HELICOPTERS
		  */
		create Ferry number: 4 {
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
	nb_humans_on_island <-length(People)+length(LawEnforcement);
	nb_people_on_island <-length(People);	
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
					if !(self.my_communicated_statuses contains "on board") {
						do add_subintention(get_current_intention(), communicate_status, true);		
						do current_intention_on_hold();							
			}
				}
				if People contains person {
					nb_people_on_board <- nb_people_on_board +1;
					nb_people_on_island <- nb_people_on_island - 1; 						
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
 	reflex alert_people_with_ITallert when: !empty(People - alerted_people) and issue_evacuation_order = true and ITalert = true {	
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
 			write person.name + person.belief_base + person.intention_base;
 		}
 		alerted_law_enforcement <- list(LawEnforcement);
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
	 			write "DEBUG: backups created.";
 			}
 				
 			should_create_backups <- false;
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
 		everybody_is_alerted <- true;
 	}
 	
 	reflex monitor_evacuation_status when: issue_evacuation_order {
 		nb_people_warned <- length(People where (each.has_belief(predicate(each.evacuation_order))));
		nb_people_prepared <- length(People where (each.has_belief(predicate(each.prepared_to_evacuate))));
		nb_people_going_to_port <- length(People where (each.has_belief(predicate(each.going_to_port))));
		nb_people_rescuing_others <- length(People where (each.has_belief(predicate(each.going_rescue_someone))));
		nb_people_waiting <- length(People where (each.has_belief(predicate(each.waiting_for_someone))));
		nb_people_at_port <- length(People where (each.has_belief(predicate(each.in_target_port))));
		nb_people_who_left_the_island <- length(People where (each.has_belief(predicate(each.left_the_island))));
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
								//TODO: insert personality in lifetime
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
	float view_dist;
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
			do remove_intention(at_target_port, true);
			do add_desire(in_target_port);
		}
	}
	
	plan go_to_nearest_port intention: at_target_port {
		if !(self.my_communicated_statuses contains "going to port") {
			do add_subintention(get_current_intention(), communicate_status, true);	
			do current_intention_on_hold();				
		}
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
		if location = port_to_evacuate_from.location and People contains self {
			if !(self.my_communicated_statuses contains "at port") {
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
			list<People> friends_I_worry_about <- list<People>((self.social_link_base where (each.liking > 0.8)) collect each.agent);
			if !empty(friends_I_worry_about) {
				list<predicate> my_friend_statuses <- get_beliefs_with_name("friend status") collect (predicate(get_predicate(mental_state (each))));
				list<predicate> my_close_friends_statuses <- [];
				loop close_friend over: friends_I_worry_about {
					predicate close_friend_status <- my_friend_statuses first_with ((each).values["name"] = close_friend.name);
					my_close_friends_statuses <+ close_friend_status; 
				}			
				loop cf_status over: my_close_friends_statuses {
					if cf_status.values["status"] = 'unknown' {
						//TODO: design this part
						/*
						 * Dobbiamo decidere tante cose:
						 * 1) Quali sono i possibili stati in generale
						 * 2) Cosa fa propendere per un piano o l'altro
						 * 3) Come si strutturano i vari piani
						 * 4) Perché ste domande se le fa ora e non quando si è avvicinato al porto?
						 */

						write self.name + " is waiting for " + cf_status.values["name"];
						boarding_decision <- true;
					}
					else if cf_status.values["status"] = 'at port'{
						boarding_decision <- true;
					}
					else if cf_status.values["status"] = 'rescuing'{
						boarding_decision <- true;
					}
					else {
						boarding_decision <- true;
					}
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
		//speed <- boarded_vehicle.speed; 
		//location <- boarded_vehicle.location; 
		do goto target: boarded_vehicle.location speed: boarded_vehicle.speed on:ferry_network; //computes much faster
	}
	
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
	
	//TODO: MOVEMENT and EVACUATION
	predicate enjoying_my_time <- new_predicate("enjoying my time");
		
	plan lets_wander intention: enjoying_my_time {
		do wander on: road_network;
	}
	
	predicate need_evac_decision <- new_predicate("need to take a decision on whether to evacuate");
	predicate took_evac_decision <- new_predicate("took an evacuation decision");
	predicate going_to_port <- new_predicate("decided to go to port"); 
	predicate going_rescue_someone <- new_predicate("decided to go rescue someone");
	predicate waiting_for_someone <- new_predicate("decided to wait for someone");
	predicate preparing <- new_predicate("preparing to evacuate");
	predicate prepared_to_evacuate <- new_predicate("prepared to evacuate");
	float time_spent_preparing <- 0 #s;
	float total_preparing_time <- 600 #s;
	rule belief: evacuation_order remove_desire: enjoying_my_time new_desire: need_evac_decision;
	rule belief: going_to_port remove_intention: need_evac_decision remove_desire: need_evac_decision new_desire: preparing;
	
	//TODO: finire la fase di preparazione
		/*
		 * L'idea è un po' questa, una volta che decido cosa fare dopo aver ricevuto l'ordine di evacuazione:
		 * - spendo del tempo a prepararmi
		 * - questo tempo è da inizializzare in create come in Bonadonna
		 * - sarà aumentato o diminuito di un coefficiente a seconda della cosa scelta (se scelgo di andare a cercare qualcuno ci metto di più)
		 * - trascorso questo tempo farà la cosa che ha deciso di fare
		 */
	plan prepare intention: preparing {
		time_spent_preparing <- time_spent_preparing + step;
		if time_spent_preparing >= total_preparing_time {
			if self.has_belief(going_to_port) {
				do remove_desire(preparing);
				do add_desire(at_target_port);
				do add_belief(prepared_to_evacuate);	
			}
			else if self.has_belief(going_rescue_someone) {
			}
			else if self.has_belief(waiting_for_someone) {
			}
		}
	}
	
	predicate rescue_someone <- new_predicate("rescue someone");
	predicate no_friend_needs_help <- new_predicate("no friend needs help");
	rule belief: going_rescue_someone remove_intention: need_evac_decision remove_desire: need_evac_decision new_desire: preparing;

	People friend_to_rescue;

	/*
	perceive target: friend_to_rescue when: friend_to_rescue != nil and self.has_intention(rescue_someone){		
	}
	*/
	action select_friend_to_help {
		list<string> help_statuses <- ["unknown", "waiting"];
		list<People> friends_that_might_need_help;
		//TODO: crea una lista dove hai le persone che sai già che non sono dove devono essere
		list<predicate> my_friends_statuses <- get_beliefs_with_name("friend status") collect (predicate(get_predicate(mental_state (each))));
		loop fr_stat over: my_friends_statuses {
			if help_statuses contains fr_stat.values["status"] {
				friends_that_might_need_help <+ my_friends first_with(each.name = fr_stat.values["name"]);
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
		if !empty(my_friends) and friend_to_rescue = nil {
			do select_friend_to_help;
		}
		else if friend_to_rescue != nil {
			list<predicate> my_friends_statuses <- get_beliefs_with_name("friend status") collect (predicate(get_predicate(mental_state (each))));
			point friend_location <- (my_friends_statuses first_with ((each).values["name"] = friend_to_rescue.name)).values["location"];
			if self.location != friend_location {
				//TODO: update with agent being faster
				do goto target: friend_location on: road_network;
			}
			else{
				if self distance_to(friend_to_rescue) < 150 #m {
					ask friend_to_rescue {
						//TODO: calmalo se ha paura
						//TODO: se stava aspettando, digli di seguirti
						//TODO: se stava facendo altro (e non stava già andando al porto), digli di andare al porto
					}
				}
				else {
					//TODO: aggiungi paura che non lo hai visto e non sai come sta					
				}
				
			}
			
		}
		else if empty(my_friends) {do add_belief(no_friend_needs_help);}	
	}
	
	plan choose_whether_to_evacuate intention: need_evac_decision {
		//decision process
		if self.has_emotion(fearEruption) {
			float fear_intensity <- get_intensity(get_emotion(fearEruption));
			if fear_intensity >= 0.6 {
				//TODO: make this line into a plan
				do goto target: closest_to(EvacuationInfrastructure,self) on: road_network;
			}
		}
		if flip(1) {
			do add_belief(going_to_port);
		} 
		/* 
		else if self.name = "oh"{
			//TODO: aggiungi se non hai il belief che siano tutti tutto okay
			do select_friend_to_help();
			do add_belief(going_rescue_someone);
		}
		else if self.name = "bah" {
			do add_belief(waiting_for_someone);
		}	
		* 
		*/
		int decision_lifetime <- int(max([300#s/step,1200#s/step*conscientiousness]));
		do add_belief(took_evac_decision, 1.0, decision_lifetime);
	}
	//TODO: SOCIAL LINKS
		//c'è solo da scegliere come inizializzarli, volendo fare un reflex per mostrare le reti sociali ma credo sia una perdita di tempo
	list<People> my_friends;
	predicate friend_status;
	
	plan update_friends intention: communicate_status instantaneous: true {
		if self.has_desire(in_target_port) {do update_status_to_my_friends("at port");}
		else if self.has_belief(left_the_island) {do update_status_to_my_friends("on board");}
		else if self.has_desire(at_target_port) {do update_status_to_my_friends("going to port");}
		else if self.has_desire(rescue_someone) {do update_status_to_my_friends("rescuing");}
		else if self.has_desire(waiting_for_someone) {do update_status_to_my_friends("waiting");}
		//else if self.has_desire(in_waiting_area) {do update_status_to_my_friends("in waiting area");}}
		do remove_intention(communicate_status, true);
	}
	
	action update_status_to_my_friends(string status) {
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

	//TODO: EMOTIONs
	emotion joyPort <- new_emotion("joy", in_target_port);
	//Ilaria: SE SONO AL PORTO E VOGLIO ESSERE AL PORTO SONO FELICE, E COSA FACCIO SE SONO FELICE?
		//Enrico: secondo me niente, farei solo che se sei felice contagi gli altri calmando la paura se ti percepiscono
	//Ilaria: CI SAREBBE DA AGGIUNGERE HAPPY FOR E SORRY FOR 
		//Enrico: sono d'accordo, ma forse non è immediato, ci penso su
	
	//TODO: EMOTIONAL RESPONSE TO VOLCANIC ACTIVITIES
	int max_perceived_boom_intensity <- 18; //TODO: make this value dependent also on personality (we could do so in the reflex so to leave this parameter on its own)
	float perceived_boom_coefficient <- 0.0;
	predicate boomHeard <- new_predicate("Boom");
	
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
	}
	
	predicate noEruption <- new_predicate("Eruption",false);
	predicate Eruption <- new_predicate("Eruption");
	emotion fearEruption <- new_emotion("fear", Eruption);

	rule belief: boomHeard new_uncertainty:Eruption strength: perceived_boom_coefficient when: not has_belief(Eruption);
	rule emotion:fearEruption new_desire: need_evac_decision remove_intention:enjoying_my_time remove_desire:enjoying_my_time;

	//TODO: EMOTIONAL CONTAGION

	float uncertaintyConversion <- 0.25;

		perceive target:People in:view_dist{

		if(has_belief(Eruption) and not myself.has_belief(Eruption)){

			focus id:"Eruption" strength: uncertaintyConversion is_uncertain:true;

//			ask myself{

//				do add_uncertainty(predicate:fireSaw,strength: uncertaintyConversion);

//			}

		}

	}		

	

	float contagionThreshold <- 0.5 parameter: true;

	People perceivedOther <- nil;

	perceive target: People in:view_dist parallel:false{
		emotional_contagion emotion_detected:fearEruption threshold:contagionThreshold;
		/*
		 * POSSIBILE ESPANSIONE DEL MODELLO, se ci chiede in quali direzioni possiamo andare
		 * socialize trust:gauss(0.0,0.33);
		myself.perceivedOther<-self;
		enforcement norm: "followOthers" sanction: "trustSanction" reward: "trustReward";
		* 
		*/
	}
	/*
	 * vedi sopra
	sanction trustSanction{
		do change_trust(perceivedOther,-0.1);
	}
	sanction trustReward{
		do change_trust(perceivedOther,0.1);
	}
	/* perceive target:LawEnforcement in:view_dist parallel:false{
		emotional_contagion emotion_detected:joy threshold:contagionThreshold;
		socialize trust:gauss(0.0,0.33);
		myself.perceivedOther<-self;
		enforcement norm: "followOthers" sanction: "trustSanction" reward: "trustReward";
	}

	sanction trustSanction{
		do change_trust(perceivedOther,-0.1);
	}
	* 
	
	sanction trustReward{
		do change_trust(perceivedOther,0.1);
	} 
	VORREI CHE QUESTO FOSSE UN MODO PER CALMARSI QUANDO SI VEDONO LE FORSE DELL'ORDINE */

	//TODO: EMOTIONAL CONTAGION

	aspect default {
		draw triangle(5) rotate: heading + 90 color: color border: #black;
		draw circle(view_dist) color: color border: #black wireframe: true;
	}
}
/*
 * TODO: FORZE ORDINE
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
			//do add_belief(new_predicate("see person", self));
			do add_belief(new_predicate("see person", ["person"::person_seen]));
		}
	}
	
	plan block_paths intention: block_access {
        do goto target: area_to_presidiate_location on: road_network;
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
			if current_person_intention  != at_target_port and current_person_intention != in_target_port{
				//write "DEBUG:" + myself.name + " - " + person_seen;
				do remove_intention(current_person_intention , true);
				do add_belief(going_to_port);
			}
			//ENRICO GUARDA CHE ABBIAMO FATTO!!
			if has_emotion(fearEruption){
			float fear_intensity <- get_intensity(get_emotion(fearEruption));
			write self.name + "Fear intensity 1: " + fear_intensity;
			fear_intensity <- fear_intensity - 0.1; 
			fearEruption <- set_intensity(fearEruption, fear_intensity); 
			float fear_intensity_2 <- get_intensity(get_emotion(fearEruption));
			write self.name + "Fear intensity 2: " + fear_intensity_2;
			
			}
		}
		do remove_intention(warn_person, true);
	}
	// TODO: quando c'è contagio emoozionale, fai che rassicura gli spaventati (o qualcosa del genere)
	
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
		do goto target: target_location on: road_network;

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
		do goto target: place_to_evacuate_from on: road_network;
	}
	
	plan wait_to_leave_island intention: lets_leave {
		if location != place_to_evacuate_from.location {
			do goto target: place_to_evacuate_from on: road_network;
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
			draw circle(10) rotate: heading + 90 color: #yellow;
			draw circle(view_dist) color: #yellow border: #black wireframe: true;
		}
		else if has_intention_op(self, predicate("alert population")) {
			draw triangle(10) rotate: heading + 90 color: #yellow;
			draw circle(alert_population_radius) color: rgb(1,0,0,0.3);
		} 
    	else {
    		draw triangle(10) rotate: heading + 90 color: color;
    		draw circle(view_dist) color: color border: #black wireframe: true;
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
		display Evacuation_Info refresh: every(120 #cycles) {
	       chart "People evacuated successfully" type: series size: {1,0.5}{
		       	data "People successfully evacuated" value: nb_evacuated_people color: #green;
		       	data "People on board" value: nb_people_on_board color: #blue;
		       	data "People still to evacuate" value: nb_people_on_island color: #red;
	       }
	       chart "Humans evacuated successfully" type: series size: {2,0.5}{
		       	data "Humans successfully evacuated" value: nb_evacuated_humans color: #green;
		       	data "Humans on board" value: nb_humans_on_board color: #blue;
		       	data "Humans still to evacuate" value: nb_humans_on_island color: #red;
	       }			
	       
		}	       
	}
}


