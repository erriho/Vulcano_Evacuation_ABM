model VolcanoTest

import "../world/VulcanoMap.gaml"

global{
	
	map roaring_sound_emission_map <- [
		"lambda" :: 1000
	];

	map glob_eruption_engine_params_map <- [
		"RoaringSoundEmission" :: roaring_sound_emission_map
	];
	
    init {	        
	    create Crater from: lafossa_crater_shp;
	    
		create Volcano number: 1{
			name <- "LaFossa";
			location <- any_location_in(one_of(Crater)); //location <- {2206.0655580625753,3096.5251492224634};
			activity_level <- 1;
			new_activity_level <- 2;
			eruption_engine_params_map <- glob_eruption_engine_params_map;
		}
	}
}

species Volcano {
    //initialization variables
    int activity_level; // 0: dormant, 1: unrest, 2: eruption
    string eruption_type; //test: test, 0: phreatic, 1a: effusive, 1b: strombolian, 2a: vulcanian PDC absence, 2b: vulcanian effusive, 3: short-lived sustained explosive, 4: phreatomagmatic
	//optional
	map eruption_engine_params_map <- nil;
	//control
	bool correct_initialization <- false;
	//update ausiliary variables
    int new_activity_level;
    //aspect variables
    rgb color;
    
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
		correct_initialization <- true;
		write "Initialization completed.";
    }
    
    reflex check_activity_level {
    	if self.new_activity_level != self.activity_level{do update_eruption_status;}
    }

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

    action create_magma_chamber {}

	aspect default{
		draw triangle(50) color: color;
	}
}

species MagmaChamber {}

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

species RoaringSoundEmissionManager parent: EruptivePhenomenonManager{
	//generation variables
	float lambda;
	float time_waited <- 0.0 #s;
	float waiting_time <- 0.0 #s;
	bool can_create <- false;
	//phenomenon variables 
	float speed_of_sound;
	float max_duration;
	list intensity_distribution;
	
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
				intensity_distribution <- myself.intensity_distribution;
				self.should_initialize <- true;
			}
			can_create <- false;
			time_waited <- 0.0 #s;
		}
	}
}

species EruptivePhenomenon {
	int activity_level;
	float duration <- 0.0 #s;
	float max_duration;
	bool should_initialize <-false;
	reflex initialize when: should_initialize = true {should_initialize <- false;}
	
	reflex execute {do update_duration;}
	action update_duration {
		duration <- duration + step;
		if duration > max_duration {do die;}
	}
}

species RoaringSoundEmission parent: EruptivePhenomenon {
	int intensity;
	float size <- 0.0 #m;
	float speed_of_sound;
	list intensity_distribution;
	
	reflex initialize when: should_initialize = true {
		size <- 0.0;
		intensity <- rnd_choice(intensity_distribution);
		write "Boom!" + " - Intensity: " + string(intensity);
		should_initialize <- false;
	}
	
	reflex execute {
		do update_duration;
		size <- size + speed_of_sound * step;
	}
	
	aspect default{	
		draw circle(size) color: rgb(#blue, 0.1);
	}
}
 
experiment main type: gui {     
    output {
	    display vulcano_map type: 2d{
	       species Island refresh: false;
	       species Roads refresh: false;
	       species Ferry_Route refresh: false;
	       species Buildings refresh: false; 
	       species Volcano;
	       species RoaringSoundEmission;
	    }
	}
}
