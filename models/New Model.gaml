model exponential

global {
	
	init {
		create extractor number: 1{}
	}
}

species extractor {
	float lambda <- 5.0;
	float extraction;
	int i<-0;
	reflex extract_exp when: i < 50 {
		do extract;
		i <- i+1;
	}
	action extract {
		extraction <- exp_rnd(lambda);
		write extraction;
	}
	
	aspect default{
		draw triangle(50) color: #red;
	}
}

experiment main type: gui {     
    output {
	    display displayname type: 2d{
	       species extractor refresh: false;
       }
    }
}