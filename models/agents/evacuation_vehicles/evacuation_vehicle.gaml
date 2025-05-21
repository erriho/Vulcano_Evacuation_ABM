model evacuationvehicle

species evacuation_vehicle skills: [moving]{
	string name;
	point location;
	int capacity; //the vehicle capacity
	int people_on_board; //it reflects how many people are on board
	bool full; //TRUE if the vehicle is completely filled (may be discontinued)
	bool warned; //TRUE if an evacuation has been ordered
	bool safe; //TRUE if the agent feel safe in its location
}

species ferry parent: evacuation_vehicle {
	
	image_file ferry_icon;
	aspect base {
		draw circle(2) color: #blue;
	}
	aspect icon {
		draw ferry_icon size: 1;
	}
}
