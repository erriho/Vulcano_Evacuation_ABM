/**
* Name: people
* Based on the internal empty template. 
* Author: irenesilvestro
* Tags: 
*/

model people



/* Insert your model definition here */


global {
  graph road_network;
  
}



species people skills: [moving] control: simple_bdi{
	point target;
	
	rgb color <- #blue;
	predicate at_target <- new_predicate("at_target"); 
  // Piano di movimento lungo il grafo stradale
  
	
	
	plan normal_move intention: at_target  {
		if (target = nil) {
			//target <- any_location_in(one_of(road));
			
      		target <- one_of(road_network.vertices);
		} else {
			do goto target: target on: road_network  recompute_path: false;
			if (target = location)  {
				target <- nil;
				//noTarget<-true;
			}
		}
	}
	
	
	
	
	
}


