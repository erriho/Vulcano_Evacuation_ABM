/**
* Name: humanforces
* Based on the internal empty template. 
* Author: 39392
* Tags: 
*/


model BDI_ProtezioneCivile

global {
    int nb_trail <- 10;
    int nb_forces <- 5;
    int nb_people <- 20;
    int cycle <- 0;
    list<person> people_warned <- [];  // Definita qui
    geometry shape <- square(2#km);
    float step <- 1#s;  // passo temporale di 1 minuto
    civil_protection pc;

    string trail_at_location <- "path_at_location";
    string cleared_path <- "cleared_path";

    predicate block_trail <- new_predicate("block_trail");
    predicate warn_people <- new_predicate("warn_people");
    predicate go_to_assembly <- new_predicate("go_to_assembly_area");
    predicate move_to_assembly <- new_predicate("move_to_assembly"); // per le persone
	predicate see_person <- new_predicate("see_person");
	
    init {
    	create civil_protection {
        	pc <- self;
    	}

    	create trail number: nb_trail;
    	create assembly_area number: 3 {
        	location <- rnd(point(500, 500), point(1900, 1900));
    	}
    	
	create forces number: nb_forces {
    	trail chosen <- one_of(trail where (each.is_blocked = false));
    	trail_target <- chosen.location;
	}




    	create person number: nb_people {
        	location <- rnd(point(0, 0), point(2000, 2000));
    	}

    // Simulazione IT Alert - Allerta iniziale
    	write "🚨 IT ALERT: Evento di emergenza. Dirigersi verso aree di attesa o presidiare sentieri.";


    	ask person {
        	do add_belief(move_to_assembly);
    	}

    	ask forces {
        	do add_desire(block_trail);
    	}
	}
	
	reflex activate_alert when: cycle = 1 {
    		pc.alert <- true;
    		write "Alert attivato!";
		}
	reflex update_time {
        cycle <- cycle + 1;
    }

    reflex end_simulation when: cycle > 80000 {
        do pause;
    }
}


species civil_protection {
    bool alert <- false;
    bool assembly_order <- false;

    // Ordine extra eventuale dopo 200 tick
    reflex send_assembly_order when: cycle = 50000 {
    	write "TORNATEE";
        assembly_order <- true;
        ask forces {
            do remove_intention(block_trail, true);
            do add_desire(go_to_assembly);
        }
    }

    aspect default {
        draw square(5) color: #blue;
    }
}

species trail {
    bool is_blocked <- false;
    init {
        location <- rnd(point(0, 0), point(2000, 2000));
    }
    aspect default {
        draw rectangle(200,50) color: is_blocked ? #gray : #green border: #black;
    }
}

species assembly_area {
    aspect default {
        draw circle(30) color: #orange border: #black;
    }
}

species person skills: [moving] control: simple_bdi {
    float speed <- 0.5#km/#h;
    rgb color <- #pink;
    assembly_area target_area;
    init {
		target_area <- one_of(assembly_area);
	}
    rule belief: move_to_assembly new_desire: go_to_assembly strength: 2.0;

	plan go_to_assembly_plan intention: go_to_assembly {
    do goto target: target_area.location;
    if (location = target_area.location) {
        do remove_intention(go_to_assembly, true);
    }
}
	

    aspect default {
        draw circle(10) color: color border: #black;
    }
}

species forces skills: [moving] control: simple_bdi {
    float view_dist <- 10.0;
    float speed <- 0.5#km/#h;
    rgb my_color <- rnd_color(255);
	assembly_area target_area;
	point trail_target <- nil;
	point assembly_target <- nil;
	
    init {
    	target_area <- one_of(assembly_area);
        if (pc.alert) {
            do add_desire(block_trail);
        }    
    }
	
    perceive target: person in: view_dist {
        focus id: "see_person" var: location;
        do add_desire(warn_people);
    }

    rule belief: see_person new_desire: warn_people strength: 1.5;
    rule belief: block_trail new_desire: warn_people strength: 1.0;
    rule belief: warn_people new_desire: go_to_assembly strength: 2.0;
	rule belief: move_to_assembly new_desire: go_to_assembly strength: 2.0;

    plan block_paths intention: block_trail {
    	if (trail_target = nil) {
            trail chosen <- trail first_with (!each.is_blocked);
            if (chosen != nil) {
                trail_target <- chosen.location;
            } else {
                // Nessun sentiero libero: rimuovo intenzione block_trail e passo a go_to_assembly
                do remove_intention(block_trail, true);
                do add_desire(go_to_assembly);
            }
        }
		if (trail_target != nil) {
            do goto target: trail_target;
            if (self distance_to(trail_target) < 1) {
            	list<trail> all_trails <- trail;
			    list<trail> nearby_trails <- trail where (each distance_to(trail_target) < 1);
    			ask nearby_trails {
        			is_blocked <- true;
    			}
                do add_belief(new_predicate(trail_at_location, ["location_value"::trail_target]));
                  trail_target <- nil;
                
                // Passo all'area di attesa
                do remove_intention(block_trail, true);
                //do add_desire(go_to_assembly);
                
                }
        }
    }

    

                
      plan interact_with_people intention: warn_people {
        person nearby <- person with_min_of (each distance_to self);
        if (nearby != nil and self distance_to nearby < 200 and not (people_warned contains nearby)) {
            write name + " sta avvisando una persona a " + nearby.location;
            people_warned <- people_warned + [nearby];

            ask nearby {
                do add_belief(move_to_assembly);
            }
            do remove_intention(warn_people, true);
        }
    }
    
    plan go_to_assembly intention: go_to_assembly {
        if (assembly_target = nil) {
        	assembly_target <- target_area.location;
    	}
    	do goto target: assembly_target;
    	if (self distance_to(assembly_target) < 10) {
        	do remove_intention(go_to_assembly, true);
        	   assembly_target <- nil;
        	write name + " è arrivato all’area di attesa";
        }
    }
    
    aspect default {
        draw circle(20) color: my_color border: #black;
        draw circle(view_dist) color: my_color border: #black wireframe: true;
    }
}

experiment ProtezioneCivileBDI type: gui {
    output {
        display map type: 2d {
            species civil_protection;
            species trail;
            species forces;
            species person;
            species assembly_area;
        }

     }
}


/* Insert your model definition here */

