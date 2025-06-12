model evacuationinfrastructures

global {string font_name <- "Arial";}

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

species Port parent: EvacuationInfrastructure {
	rgb color <- #blue;
	rgb std_color <- #blue;
	
	aspect default {
		draw circle(20) color: rgb(color, 0.9);
		if self.name != "Porto di Milazzo" {draw string(string(people_waiting_nb) + "/" + string(actual_people_capacity)) font: font(font_name, 5) color: color;}
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