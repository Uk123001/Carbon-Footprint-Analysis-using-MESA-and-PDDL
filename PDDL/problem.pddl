;; Carbon City Planning Problem
;; Connected to MESA Simulation Outputs
;;
;; This problem instance reflects a small-scale urban setup from the MESA model.
;; Number of agents matches a subset: 3 households, 2 businesses, 3 vehicles, 2 energy-producers.
;; Initial emissions adjusted for high-emission baselines (fossil/gasoline):
;; - Household: 86 kg CO2/step (energy 75 kWh * 0.5 + car 30 + waste 15 kg * 0.47, eff 0.75)
;; - Business: 165 kg (prod_energy 250 * 0.65 + resource 75 * 0.5, eff 0.65)
;; - Vehicle: 19.2 kg (dist 100 km * 0.192 gasoline, eff 0.65)
;; - Energy: 528 kg (prod 550 * 0.96 fossil, eff 0.75)
;; Total initial: 1701.6 kg CO2/step
;;
;; Goal: Reduce total emissions <=300 kg via efficiency improvements and switches,
;; mirroring 100-step MESA simulation trends where emissions decrease over time.
;; Fixed reductions ensure compatibility; for BFWS planners, step blocks will display
;; sequential actions with precondition/effect traces.
(define (problem carbon-city)
(:domain carbon-footprint)
(:objects
h1 h2 h3 - household
b1 b2 - business
v1 v2 v3 - vehicle
e1 e2 - energy-producer
city-center suburbs - location
fossil renewable - energy-source
car public gasoline electric - transport-mode
)
(:init
;; Energy source properties
(is-fossil fossil)
(is-renewable renewable)
;; Initial locations (random grid approx to city/suburbs)
(at h1 city-center) (at h2 city-center) (at h3 suburbs)
(at b1 city-center) (at b2 suburbs)
(at v1 city-center) (at v2 city-center) (at v3 suburbs)
(at e1 city-center) (at e2 suburbs)
;; Agent goals (from MESA)
(goal-minimize-emissions h1) (goal-minimize-emissions h2) (goal-minimize-emissions h3)
(goal-optimize-production b1) (goal-optimize-production b2)
(goal-efficient-routing v1) (goal-efficient-routing v2) (goal-efficient-routing v3)
(goal-stable-supply e1) (goal-stable-supply e2)
;; Initial energy/transport usage (fossil/gasoline start, per MESA bias but set to high-emission for planning)
(using-energy h1 fossil) (using-energy h2 fossil) (using-energy h3 fossil)
(using-energy b1 fossil) (using-energy b2 fossil)
(using-energy e1 fossil) (using-energy e2 fossil)
(using-transport v1 gasoline) (using-transport v2 gasoline) (using-transport v3 gasoline)
(using-transport h1 car) (using-transport h2 car) (using-transport h3 car)
;; Initial emissions and efficiency (from MESA samples, scaled for integers)
(= (emissions h1) 86) (= (efficiency h1) 75) (= (a-star-cost h1) 0)
(= (emissions h2) 86) (= (efficiency h2) 75) (= (a-star-cost h2) 0)
(= (emissions h3) 86) (= (efficiency h3) 75) (= (a-star-cost h3) 0)
(= (emissions b1) 165) (= (efficiency b1) 65) (= (a-star-cost b1) 0)
(= (emissions b2) 165) (= (efficiency b2) 65) (= (a-star-cost b2) 0)
(= (emissions v1) 19) (= (efficiency v1) 65) (= (a-star-cost v1) 0)
(= (emissions v2) 19) (= (efficiency v2) 65) (= (a-star-cost v2) 0)
(= (emissions v3) 19) (= (efficiency v3) 65) (= (a-star-cost v3) 0)
(= (emissions e1) 528) (= (efficiency e1) 75) (= (a-star-cost e1) 0)
(= (emissions e2) 528) (= (efficiency e2) 75) (= (a-star-cost e2) 0)
;; Total initial emissions (sum of agent emissions)
(= (total-emissions) 1702)  ;; 386 + 2165 + 319 + 2528 (rounded)
)
(:goal
(and
(<= (total-emissions) 300)  ;; Achieve ~82% reduction, reflecting MESA efficiency gains over steps
(improved-efficiency h1) (improved-efficiency h2) (improved-efficiency h3)
(improved-efficiency b1) (improved-efficiency b2)
(improved-efficiency v1) (improved-efficiency v2) (improved-efficiency v3)
(improved-efficiency e1) (improved-efficiency e2)
(switched-to-renewable b1)  ;; Business renewable switch
(switched-to-renewable e1)
(switched-to-renewable e2)
(switched-to-low-emission-transport h1)  ;; Household public transport
(switched-to-low-emission-transport v1)  ;; Vehicle electric switch
)
)
(:metric minimize (total-emissions))  ;; Optimize for lowest final emissions, like MESA's A* cost minimization
)