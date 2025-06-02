model evacuationinfrastructures

species EvacuationInfrastructure {
	int occupied_evacuation_spots;
	int actual_evacuation_vehicle_capacity;
	int max_evacuation_vehicle_capacity;
	int people_waiting;
	int actual_people_capacity;
	int max_people_capacity;
	rgb color <- #darkblue;
	float occupancy;
	bool full;
	bool viability;
	
	reflex check_occupancy {}
	
	action update_viability_status {
		if viability = true {}
		if viability = false {
			actual_evacuation_vehicle_capacity <- 0;
			actual_people_capacity <- 0;
		}
	}
}

species Port parent: EvacuationInfrastructure {
	aspect default {
		draw circle(20) color: rgb(color, 0.1) border: rgb(color);
	}
}

species Heliport parent: EvacuationInfrastructure {}

