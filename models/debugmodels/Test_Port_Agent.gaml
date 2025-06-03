model PortTest

import "../world/VulcanoMap.gaml"

global {
	
	string font_name <- "Arial";
	
	file ports_shp <- file("../../includes/Shapefiles/Ports/Ports.shp");
	file ports_data <- csv_file("../../includes/csv/Ports.csv");
	matrix ports_data_matrix <- matrix(ports_data);
	
	file heliports_shp <- file("../../includes/Shapefiles/Heliports/Heliports.shp");
	file heliports_data <- csv_file("../../includes/csv/Heliports.csv");
	matrix heliports_data_matrix <- matrix(heliports_data);
	
	init {
		create Port from: ports_shp;
		create Heliport from: heliports_shp;
		loop port over: Port {
			loop row_index over: [0,1,2,3] {
				if port.name = string(ports_data_matrix[0, row_index]) {
					port.max_evacuation_vehicles_capacity <- int(ports_data_matrix[1, row_index]); 
					port.actual_evacuation_vehicles_capacity <- port.max_evacuation_vehicles_capacity;
					port.max_people_capacity <- int(ports_data_matrix[2, row_index]);
					port.actual_people_capacity <- port.max_people_capacity;
					write port.name + "-" + port.max_evacuation_vehicles_capacity + "-" + port.max_people_capacity;
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
					write heliport.name + "-" + heliport.max_evacuation_vehicles_capacity + "-" + heliport.max_people_capacity;
				}
			}
			if heliport.name = 'ZAE Cratere' {ask heliport {do die;}}
		}
	}
}

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


experiment main type: gui {     
    output {
	    display vulcano_map type: 3d{
	       species Island refresh: false;
	       species Roads refresh: false;
	       species Ferry_Route refresh: false;
	       species Buildings refresh: false; 
	       species Port;
	       species Heliport;
	    }
	}
}
