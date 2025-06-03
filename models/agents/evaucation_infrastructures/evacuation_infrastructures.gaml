model evacuationinfrastructures

global {string font_name <- "Arial";}

species EvacuationInfrastructure {
	int occupied_evacuation_spots;
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