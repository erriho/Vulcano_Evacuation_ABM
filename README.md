# Simulating a Volcanic Island Evacuation with Emotions and Social Structure:  
## An Agent-Based Model Applying the BEN Architecture  

**Authors:** Enrico Sansone, Irene Silvestro, Ilaria Vetrano  
**Course:** Econophysics and MAS Laboratory  - Università degli Studi di Torino (Italy)
**Exam Date:** September 2025 – Academic Year 2024/25  


##  Project Overview  

This project consists in an Agent-Based Model (ABM) built to simulate the evacuation of the population during a volcanic eruption of the island of Vulcano (Italy). Our approach integrates emotions and social structures in the decision-making process of the agents. To further provide a realistic environment, we also used the real-world road network of Vulcano island. The model was developed in GAMA (version 1.9.3). 
During a simulation run, the volcano agent acts as a trigger with its “boom”-events that are perceived by people on the island and changes the decisions of agents. The Civil Defence (CD) agent manages and coordinates Law Enforcement Agents (LEAs), the issuing of evacuation order to civilian population and the evacuation resources such as ferries, helicopters and ports as well as monitoring volcanic activity and evacuation status. Only when the civilian population is evacuated, LEAs can leave the island and as soon as they reach Milazzo’s port the simulation is terminated. 
Our research aim is to assess the impact that the emotional and social engine have on the evacuation time and to evaluate the effectiveness of a broadcast alert system (IT-Alert) in this crisis scenario by comparing it to a point-to-point one.

##  Repository structure
- Directory `includes` contains all shapefiles and csv used by the model
- Directory `models` contains two subdirectories:
  - `complete_models`: it contains two ready-to-run models, one with emotions, personality values and social links enabled and one without them-
  - `debugmodels`: it contains a series of model files that proved useful for debugging. At the moment of writing, `Test_WholeModel.gaml` and `Test_WholeModel_NoEm.gaml` are equivalent to the files contained in the aforementioned directory. 
- Directory `results_analysis` contains the notebooks used to generate the figures in the report
- File `Report.pdf` goes through a description of the model and the simulation scenarios that were studied. It was written to meet the exams' requirements.  


##  Implementation Details  

- **Modeling Platform:** GAMA 1.9.3  
- **Approach:** Agent-Based Modeling (ABM)  
- **Focus:** Integration of emotional dynamics and social structure using BEN architecture  
- **Case Study:** Vulcano Island (Italy)  
- **Main Agents:**  
  - Volcano  
  - Civil Defense (CD)  
  - Law Enforcement Agents (LEAs)  
  - Civilians (People)  
  - Evacuation infrastructures and vehicles  


##  Research Objectives  

- Analyze how **emotional states** and **social relationships** influence evacuation behavior and timing.  
- Compare the **IT-Alert broadcast system** with a **point-to-point alert mechanism** under emergency conditions.  
- Assess which and how **non-rational behaviors of agents** affect overall evacuation efficiency.
