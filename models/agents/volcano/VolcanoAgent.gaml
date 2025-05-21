model VolcanoAgent

species Volcano {
    string name;  
    point location;
    float activity_level <- 0.0; // 0: dormant, 1: unrest, 2: eruption
    string eruption_type; //test: test, 0: phreatic, 1a: effusive, 1b: strombolian, 2a: vulcanian PDC absence, 2b: vulcanian effusive, 3: short-lived sustained explosive, 4: phreatomagmatic
    float eruption_probability <- 0.01; // Daily probability of eruption

    // Sub-agent: Magma Chamber
    action create_magma_chamber {
    }
    
    
    // Reflex to check for eruption conditions
    reflex ciao {
        if self.activity_level < 2 and rnd(1.0) < self.eruption_probability {
            do trigger_eruption;
        } else if self.activity_level = 2 {
            // Simulate ongoing eruption (e.g., decrease intensity over time)
            self.eruption_probability <- self.eruption_probability * 0.95;
            if self.eruption_probability < 0.001 {
                self.activity_level <- 0.0;
                write "Volcano " + self.name + " returns to a dormant state.";
            }
        } else if self.activity_level < 2 and rnd(1.0) < 0.05 {
            self.activity_level <- 1.0;
            write "Volcano " + self.name + " shows signs of unrest.";
        } else if self.activity_level = 1 and rnd(1.0) < 0.1 {
            self.activity_level <- 0.0;
            write "Volcano " + self.name + " returns to a dormant state.";
        }
    }
    
    // Action to trigger an eruption
    action trigger_eruption {
        write "Volcano " + self.name + " is erupting!";
        self.activity_level <- 2.0;
        ask my_sub_agents { // Ask all sub-agents
            doOnEruption; // Trigger a generic eruption behavior in sub-agents
        }
        // Optionally create dynamic agents like LavaFlow or AshCloud here
        create LavaFlow number: 1 {
            location <- self.location;
            initial_velocity <- {rnd(5.0), rnd(5.0)};
        }
        create AshCloud number: 1 {
            location <- self.location;
            initial_height <- rnd(1000.0);
        }
    }


	init {
        geometry a0 <- circle(2); // Simple circular representation
    }
}

species MagmaChamber {
}

