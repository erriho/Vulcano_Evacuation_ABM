model PortTest

global {
	
	string font_name <- "Arial";

	file island_shp <- file("../../includes/Shapefiles/Island/Vulcano_Island.shp");
	file roads_shp <- file("../../includes/Shapefiles/Roads/Vulcano_Roads_and_Paths_United_Cleaned.shp");
	file Milazzo_route_shp <- file("../../includes/Shapefiles/Ferry_Routes/Vulcano_Milazzo.shp");
 	file buildings_shp <- file("../../includes/Shapefiles/Buildings/Vulcano_Buildings.shp");
 	file lafossa_crater_shp <- file("../../includes/Shapefiles/Craters/LaFossaCrater.shp");
    geometry shape <- envelope(island_shp);
    
	file ports_shp <- file("../../includes/Shapefiles/Ports/Ports.shp");
	file ports_data <- csv_file("../../includes/csv/Ports.csv");
	matrix ports_data_matrix <- matrix(ports_data);
	file heliports_shp <- file("../../includes/Shapefiles/Heliports/Heliports.shp");
	file heliports_data <- csv_file("../../includes/csv/Heliports.csv");
	matrix heliports_data_matrix <- matrix(heliports_data);
	
	graph road_network;
	graph ferry_network;
	
	init {
	    create Island from: island_shp;
	    create Roads from: roads_shp where (each != nil);
	    create Ferry_Route from: Milazzo_route_shp where (each != nil);
	    create Buildings from: buildings_shp;
		create Port from: ports_shp;
		create Heliport from: heliports_shp;
		loop port over: Port {
			loop row_index over: [0,1,2,3] {
				if port.name = string(ports_data_matrix[0, row_index]) {
					port.max_evacuation_vehicles_capacity <- int(ports_data_matrix[1, row_index]); 
					port.actual_evacuation_vehicles_capacity <- port.max_evacuation_vehicles_capacity;
					port.max_people_capacity <- int(ports_data_matrix[2, row_index]);
					port.actual_people_capacity <- port.max_people_capacity;
					write port.name + " - " + port.max_evacuation_vehicles_capacity + " - " + port.max_people_capacity + " - " + port.location; 
				}
			}
			if port.name = 'Molo di protezione civile di Gelso' {ask port {do die;}}
			else if port.name = 'Molo di protezione civile di Ponente' {ask port {do die;}}	
		}
		loop heliport over: Heliport {
			loop row_index over: [0,1,2,3,4] {
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
	    
		create ferry number: 1 {
			evacuation_mode <- true;
			ready_to_evacuate <- true;
			safe <- true;
			cruising_speed <- 20 #km/#h;
			speed <- cruising_speed;
			approach_distance <- 0.003 #km;
			max_waiting_time <- 3000 #s;
			capacity <- 1;
			location <- any_location_in(one_of(ferry_network.edges));
			write ferry_network;
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
					//self.target_destination <- port.location;
					//write string(self.target_destination) + "-" + port.location;
				}
			}
		}
	}
}

species EvacuationInfrastructure {
	int occupied_evacuation_spots <- 0;
	int actual_evacuation_vehicles_capacity;
	int max_evacuation_vehicles_capacity;
	int people_waiting;
	int actual_people_capacity;
	int max_people_capacity;
	float occupancy;
	bool full <- false;
	bool viability <- true;
	//aspect
	rgb color;
	rgb std_color;
	rgb full_color <- #red;
	rgb unviable_color <- #black;
	
	reflex check_occupancy {
		if occupied_evacuation_spots >= actual_evacuation_vehicles_capacity {full <- true; color <- full_color;}
		else if occupied_evacuation_spots < actual_evacuation_vehicles_capacity {full <- false; color <- std_color;}
	}
	
	action board_people (float boarding_speed, int people_on_board){
		int max_people_to_board <- round (boarding_speed*step);
		return people_on_board;
	}
	action unboard_people (float boarding_speed, int people_on_board){
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

species Port parent: EvacuationInfrastructure {
	rgb color <- #blue;
	rgb std_color <- #blue;
	
	aspect default {
		draw circle(20) color: rgb(color, 0.9);
		if self.name != "Porto di Milazzo" {draw string(string(people_waiting) + "/" + string(actual_people_capacity)) font: font(font_name, 5) color: color;}
	}
}

species Heliport parent: EvacuationInfrastructure {
	bool lights;
	rgb color <- #orange;
	rgb std_color <- #orange;
	
	aspect default {
		draw circle(20) color: rgb(color, 0.9);
	}
}

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
			myself.people_on_board <- int(board_people(myself.boarding_speed, myself.people_on_board));
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
			myself.people_on_board <- int(unboard_people(myself.boarding_speed, myself.people_on_board));
		}
		if people_on_board = 0 {
			write self.name + " - Unboarding complete.";
			ready_to_evacuate <- true;
			free_to_go <- false;
			should_unboard <- false;
		}
	}
}

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


experiment main type: gui {     
    output {
	    display vulcano_map type: 3d{
	       species Island refresh: false;
	       species Roads refresh: false;
	       species Ferry_Route refresh: false;
	       species Buildings refresh: false; 
	       species Port;
	       species Heliport;
	       species ferry aspect: base;
	    }
	}
}
