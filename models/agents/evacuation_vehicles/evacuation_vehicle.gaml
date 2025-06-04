model evacuationvehicle

import "../evacuation_infrastructures/evacuation_infrastructures.gaml"

global {
	/*Here are external variables so that error messages do not pop up.*/
	graph ferry_network;
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

/*
species helicopter parent: evacuation_vehicle {
	float altitude <- 0.0 #m;
	float cruising_altitude <- 300.0 #m;
	float take_off_speed <- 2.0 #m/#s;
	float landing_speed <- 2.0 #m/#s;
	point desired_target <- nil;
	
	bool taking_off_bool;
	image_file helicopter_icon;
		
	action keep_still{
		altitude <- 0.0;
		speed <- 0.0;
	}
	
	action taking_off {
		altitude <- altitude + take_off_speed*step;
		speed <- 0.0;
		if people_on_board > 0 {should_unboard <- true;}
		else if people_on_board = 0 {should_board <- true;}
	}
	
	reflex take_off when: taking_off_bool = true {
		do taking_off;
		if altitude >= crusing_altitude {taking_off_bool <- false;}
	}
	
	action landing {
		altitude <- altitude - landing_speed*step;
		speed <- 0.0;
	}
	
	aspect base {
		draw circle(2) color: #yellow;
	}
	aspect icon {
		draw helicopter_icon size: 1;
	}
*/	
