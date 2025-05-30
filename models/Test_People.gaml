/**
* Name: TestPeople
* Based on the internal empty template. 
* Author: irenesilvestro
* Tags: 
*/


model Test_People

import "world/VulcanoMap_ire.gaml"
import "agents/people/people.gaml"

/* creation of people united with definition of map
 * define how people are setted in the map */
 /*
 global {
 	
 	init {
 		create people number: 200{
 			
			//location <- any_location_in(one_of(Roads));
			//location <- any_location_in(one_of(Roads).shape);
			location <- any_location_in(one_of(Roads).shape);


			
			
			//location <- location_on(one_of(Roads).shape, rnd(1.0));
			
			//location <- any_location_in(Roads);
			
			
 		}
 		
 	}
 	
 }
 */
global {
  graph road_network;
  
  init {
    create Roads from: road_shp;
    road_network <- as_edge_graph(Roads);

    create people number: 200 {
    	
     
      //location <- one_of(road_network.vertices);
	  location <- any_location_in(one_of(Roads));
	
      
      do add_desire(at_target);//gli aggiunge desiderio di raggiungere target 
			//la priorità di quella sopra non sembrerebbe esser fissata
			
    }
  }
}

 
 
 
experiment show_map type: gui {     
    output {
	    display vulcano_map type: 3d{
	       species Island refresh: false;
	       species Roads refresh: false;
	       species Ferry_Route refresh: false;
	       species people;
	    }
	}
}

