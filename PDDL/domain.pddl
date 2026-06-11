;; Carbon Footprint Planning Domain
;; Connected to MESA Agent-Based Simulation
;;
;; This PDDL domain models key decision points from the MESA carbon footprint simulation.
;; Agents (households, businesses, vehicles, energy-producers) perform actions to improve
;; efficiency and switch to low-emission sources, mirroring the goal_based_decision and
;; calculate_emissions methods in MESA agents.
;;
;; Emission factors are derived from MESA's download_real_datasets() defaults:
;; - energy_kwh: 0.5 kg CO2/kWh
;; - transport_car: 30 kg CO2/day, transport_public: 10 kg CO2/day
;; - production_energy: 0.65 kg CO2/kWh, resource: 0.50 kg CO2/unit
;; - vehicle_electric: 0.053 kg CO2/km, vehicle_gasoline: 0.192 kg CO2/km
;; - energy_renewable: 0.02 kg CO2/kWh, energy_fossil: 0.96 kg CO2/kWh
;; - waste: 0.47 kg CO2/kg
;;
;; Action effects (emission decreases) are calibrated to approximate one-step impacts
;; from MESA's continuous updates, scaled for discrete planning. Fixed constants used
;; for compatibility with basic PDDL parsers (no arithmetic expressions in increase/decrease).
;; A* optimization is reflected in the total-emissions minimization metric.
;;
;; Initial emissions in problem.pddl are sampled from MESA agent initializations
;; (using random.seed(42) for reproducibility). For BFWS or similar planners, this
;; ensures step-wise output in blocks (e.g., via plan visualization tools).
;; 
;; The metric graph in problem.pddl will track total emissions, 
;; allowing planners to optimize for the lowest carbon footprint across the plan.

(define (domain carbon-footprint)
(:requirements :strips :typing :fluents :negative-preconditions)
(:types
agent location energy-source transport-mode - object
household business vehicle energy-producer - agent
fossil renewable - energy-source
car public gasoline electric - transport-mode
)
(:predicates
(at ?a - agent ?l - location)
(using-energy ?a - agent ?e - energy-source)
(using-transport ?a - agent ?t - transport-mode)  ;; Added for vehicle/household transport choices
(goal-minimize-emissions ?a - household)
(goal-optimize-production ?a - business)
(goal-efficient-routing ?a - vehicle)
(goal-stable-supply ?a - energy-producer)
(is-renewable ?e - energy-source)
(is-fossil ?e - energy-source)
(improved-efficiency ?a - agent)
(switched-to-renewable ?a - agent)
(switched-to-low-emission-transport ?a - agent)  ;; New for transport switches
)
(:functions
(emissions ?a - agent) - number
(total-emissions) - number
(efficiency ?a - agent) - number
(a-star-cost ?a - agent) - number  ;; Added to reflect MESA's A* optimization tracking
)
;; ====================== HOUSEHOLD ACTIONS ======================
;; Mirrors HouseholdAgent: efficiency improvement, transport switch, renewable switch
(:action household-improve-efficiency
:parameters (?h - household ?l - location)
:precondition (and (at ?h ?l) (goal-minimize-emissions ?h) (not (improved-efficiency ?h)))
:effect (and
(improved-efficiency ?h)
(increase (efficiency ?h) 1)  ;; Scaled to 0.01 * 100 for integer tracking
(decrease (emissions ?h) 1)   ;; Approx 0.43 kg, scaled; reflects energy_use reduction
(decrease (total-emissions) 1)
(increase (a-star-cost ?h) 9) ;; Approx g(n) + h(n) = emissions * 0.1, scaled
)
)
(:action household-switch-transport
:parameters (?h - household ?l - location ?old - transport-mode ?new - transport-mode)
:precondition (and
(at ?h ?l)
(goal-minimize-emissions ?h)
(using-transport ?h ?old)
(not (using-transport ?h ?new))
(= ?old car)
(= ?new public)
(not (switched-to-low-emission-transport ?h)))
:effect (and
(not (using-transport ?h ?old))
(using-transport ?h ?new)
(switched-to-low-emission-transport ?h)
(decrease (emissions ?h) 20)  ;; 30-10=20 kg reduction per MESA factors
(decrease (total-emissions) 20)
)
)
(:action household-switch-to-renewable
:parameters (?h - household ?l - location ?old - energy-source ?new - energy-source)
:precondition (and
(at ?h ?l)
(goal-minimize-emissions ?h)
(using-energy ?h ?old)
(is-fossil ?old)
(is-renewable ?new))
:effect (and
(not (using-energy ?h ?old))
(using-energy ?h ?new)
(switched-to-renewable ?h)
(decrease (emissions ?h) 83)  ;; Approx 86 * 0.96 for fossil to renewable switch
(decrease (total-emissions) 83)
)
)
;; ====================== BUSINESS ACTIONS ======================
;; Mirrors BusinessAgent: efficiency and resource reduction, renewable switch
(:action business-improve-efficiency
:parameters (?b - business ?l - location)
:precondition (and (at ?b ?l) (goal-optimize-production ?b) (not (improved-efficiency ?b)))
:effect (and
(improved-efficiency ?b)
(increase (efficiency ?b) 1)  ;; Scaled to 0.008 * 125
(decrease (emissions ?b) 1)   ;; Approx 0.49 kg, scaled; reflects resource_use reduction
(decrease (total-emissions) 1)
(increase (a-star-cost ?b) 25) ;; Approx emissions * 0.15, scaled
)
)
(:action business-switch-to-renewable
:parameters (?b - business ?l - location ?old - energy-source ?new - energy-source)
:precondition (and
(at ?b ?l)
(goal-optimize-production ?b)
(using-energy ?b ?old)
(is-fossil ?old)
(is-renewable ?new)
(not (switched-to-renewable ?b)))
:effect (and
(not (using-energy ?b ?old))
(using-energy ?b ?new)
(switched-to-renewable ?b)
(decrease (emissions ?b) 155) ;; Approx 165 * 0.94 for production to renewable equiv
(decrease (total-emissions) 155)
)
)
;; ====================== VEHICLE ACTIONS ======================
;; Mirrors VehicleAgent: efficiency improvement, fuel switch
(:action vehicle-improve-efficiency
:parameters (?v - vehicle ?l - location)
:precondition (and (at ?v ?l) (goal-efficient-routing ?v) (not (improved-efficiency ?v)))
:effect (and
(improved-efficiency ?v)
(increase (efficiency ?v) 1)  ;; Scaled to 0.012 * 83
(decrease (emissions ?v) 1)   ;; Approx 0.04 kg, scaled; reflects distance reduction
(decrease (total-emissions) 1)
(increase (a-star-cost ?v) 1) ;; Approx emissions * 0.05, scaled
)
)
(:action vehicle-switch-fuel
:parameters (?v - vehicle ?l - location ?old - transport-mode ?new - transport-mode)
:precondition (and
(at ?v ?l)
(goal-efficient-routing ?v)
(using-transport ?v ?old)
(not (using-transport ?v ?new))
(= ?old gasoline)
(= ?new electric)
(not (switched-to-low-emission-transport ?v)))
:effect (and
(not (using-transport ?v ?old))
(using-transport ?v ?new)
(switched-to-low-emission-transport ?v)
(decrease (emissions ?v) 14)  ;; Approx 19.2 * 0.72 for gasoline to electric
(decrease (total-emissions) 14)
)
)
;; ====================== ENERGY PRODUCER ACTIONS ======================
;; Mirrors EnergyProducerAgent: efficiency improvement, type switch
(:action producer-improve-efficiency
:parameters (?e - energy-producer ?l - location)
:precondition (and (at ?e ?l) (goal-stable-supply ?e) (not (improved-efficiency ?e)))
:effect (and
(improved-efficiency ?e)
(increase (efficiency ?e) 1)  ;; Scaled to 0.01 * 100
(decrease (emissions ?e) 79)  ;; Approx 528 * 0.15 for efficiency modifier
(decrease (total-emissions) 79)
(increase (a-star-cost ?e) 11) ;; Approx emissions * 0.02, scaled
)
)
(:action producer-switch-to-renewable
:parameters (?e - energy-producer ?l - location ?old - energy-source ?new - energy-source)
:precondition (and
(at ?e ?l)
(goal-stable-supply ?e)
(using-energy ?e ?old)
(is-fossil ?old)
(is-renewable ?new)
(not (switched-to-renewable ?e)))
:effect (and
(not (using-energy ?e ?old))
(using-energy ?e ?new)
(switched-to-renewable ?e)
(decrease (emissions ?e) 519) ;; Approx 528 * 0.98 for fossil to renewable
(decrease (total-emissions) 519)
)
)
;; ====================== GENERAL ACTION: A* OPTIMIZATION STEP ======================
;; Simulates one step of MESA's a_star_optimization across all agents
;; (Note: Simplified; planners may parallelize per agent)
(:action perform-a-star-optimization
:parameters (?a - agent)
:precondition (and (improved-efficiency ?a))
:effect (and
(increase (a-star-cost ?a) 10) ;; Approx (+ total-emissions (* efficiency 0.1)), fixed scale
)
)
)