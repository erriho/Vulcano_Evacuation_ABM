model VolcanoTest

import "../world/VulcanoMap.gaml"

global{
	
    init {	        
	    create Crater from: lafossa_crater_shp;
	    
		create Volcano number: 1{
			name <- "LaFossa";
			location <- any_location_in(one_of(Crater)); //location <- {2206.0655580625753,3096.5251492224634};
			activity_level <- 1;
			new_activity_level <- 2;
		}
	}
}

species Volcano {
    int activity_level; // 0: dormant, 1: unrest, 2: eruption
    int new_activity_level;
    string eruption_type; //test: test, 0: phreatic, 1a: effusive, 1b: strombolian, 2a: vulcanian PDC absence, 2b: vulcanian effusive, 3: short-lived sustained explosive, 4: phreatomagmatic
    rgb color;
    
    reflex check_activity_level {
    	if self.new_activity_level != self.activity_level{do update_eruption_status;}
    }
	reflex boom_emission {    
    	if (flip(0.01)) {create RoaringSoundEmission {location <- myself.location;}}
	}

    action update_eruption_status {
    	if self.new_activity_level = 0 {
    		write "Volcano " + self.name + " is dormant.";
    		self.activity_level <- self.new_activity_level;
    		color <- #green;
    		ask EruptivePhenomenon {self.activity_level<-myself.activity_level;}
		}
    	else if self.new_activity_level = 1 {
    		write "Volcano " + self.name + " is unrest.";
    		self.activity_level <- self.new_activity_level;
    		color <- #yellow;
    		ask EruptivePhenomenon {self.activity_level<-myself.activity_level;}
		}
    	else if self.new_activity_level = 2 {
    		write "Volcano " + self.name + " is erupting!";
    		self.activity_level <- self.new_activity_level;
    		color <- #red;
        	ask EruptivePhenomenon {self.activity_level<-myself.activity_level;}
    	}
	}

    action create_magma_chamber {}

	aspect default{
		draw triangle(50) color: color;
	}
}

species MagmaChamber {}

species EruptivePhenomenon {
	int activity_level;
	float intensity;
	float duration <- 0.0 #s;
	float max_duration;
	
	reflex execute {do update_duration;}
	action update_duration {
		duration <- duration + step;
		if duration > max_duration {do die;}
	}
}

species RoaringSoundEmission parent: EruptivePhenomenon {
	float size <- 0.0 #m;
	float speed_of_sound <- 343.3 #m/#s;
	float max_duration <- 20 #s;
	
	init {
		size <- 0.0;
		write "Boom!";
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
