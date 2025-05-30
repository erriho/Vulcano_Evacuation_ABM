model evacuationvehicle

species evacuation_vehicle skills: [moving] control: fsm{
	point hub_location;
	bool should_board;
	bool should_unboard;
	int capacity; //the vehicle capacity
	int people_on_board; //it reflects how many people are on board
	bool full; //TRUE if the vehicle is completely filled (may be discontinued)
	float boarding_speed;
	float unboarding_speed;
	bool warned; //TRUE if an evacuation has been ordered
	bool safe; //TRUE if the agent feel safe in its location
	
	action boarding {}
	action unboarding {}
}

species ferry parent: evacuation_vehicle {
	
	image_file ferry_icon;
	aspect base {
		draw circle(2) color: #blue;
	}
	aspect icon {
		draw ferry_icon size: 1;
	}
}

species helicopter parent: evacuation_vehicle {
	float altitude <- 0.0 #m;
	float cruising_altitude <- 300.0 #m;
	float take_off_speed <- 2.0 #m/#s;
	float landing_speed <- 2.0 #m/#s;
	point desired_target <- nil;
	image_file helicopter_icon;
	
	state on_ground initial: true {
		do keep_still;
		transition to: take_off when: desired_target != nil;
		transition to: boarding when: should_board = true;
		transition to: unboarding when: should_unboard = true;
	}
	
	state take_off{
		do taking_off;
		transition to: flying when: altitude = cruising_altitude;	
	}
	
	state flying {
		do goto target: destination speed: speed;
		transition to: landing when: location = destination;
	}
	
	state landing {
		do landing;
		transition to: take_off when: safe = false;
	}
	
	state boarding {
		do boarding;
		exit {
			destination <- hub_location;
		}
		transition to: take_off when: safe = false;
		transition to: take_off when: people_on_board = capacity;
	}
	
	state unboarding {
		do unboarding;
		transition to: take_off when: safe = false;
	}
		
	action keep_still{
		altitude <- 0.0;
		speed <- 0.0;
	}
		
	action taking_off {
		altitude <- altitude + take_off_speed*step;
		speed <- 0.0;
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
	
}
