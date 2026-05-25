Project Overview: The Business Problem

When flights are delayed, it creates a massive domino effect.
Airlines lose millions in fuel, crew overtime, and passenger compensation.
Airports face gate bottlenecks.

Solution:
A system that ingests flight and airport infrastructure data, tracks delay types, 
and calculates a Disruption Impact Score to help airport operations teams decide which delayed flights get priority access to available gates and ground crews.

Mechanical/Carrier delays get higher penalties because the airline has more direct operational liability.
To scale this, I would migrate the local MySQL data instance into a cloud platform like AWS RDS or Google BigQuery to manage streaming global flight telemetry streams.
I plan to integrate an API pipeline fetching real-time global weather radar data to dynamically shift penalties before flights take off.

# Hub Flight Delay & Disruption Management System

## 1. The Business Case: Optimizing Hub Resilience
In the commercial aviation sector, time is a high-stakes financial metric. When an aircraft experiences an operational delay, 
the negative externalities cascade rapidly across an airline's network—triggering missed passenger connections, crew duty-hour violations,
and escalating ground-handling penalties. 

This system acts as an operational decision-support tool. It ingests live flight data and structural airport constraints 
to programmatically prioritize resource allocation during severe network shocks. The platform directly targets and optimizes 
three critical aviation Key Performance Indicators (KPIs):

* **D0 (Departure Punctuality):** Minimizing the exact minute an aircraft pushes back from the gate past its scheduled departure time.
*  By automating gate re-assignments for inbound delayed flights, the system shortens ground turnarounds to protect the outbound D0 metric.
* **A14 (Arrival within 14 Minutes):** Protecting the industry-standard benchmark for on-time arrival performance.
* The system calculates real-time disruption severity to help air traffic and airport ops teams clear bottlenecks,
* ensuring delayed flights land and deplane within the critical 14-minute cushion.
* **AOG (Aircraft on Ground) Mitigation:** When a delay is flagged as structural or mechanical,
* every minute the asset sits idle incurs massive revenue losses.
* This system flags high-priority mechanical delays to accelerate the provisioning of maintenance crews,
* spare parts inventory, and dedicated hangar gates, reducing total AOG downtime.

---

## 2. System Architecture & Relational Schema
The database is architected to mirror an enterprise airport operational database (AODB), built using a relational structure in MySQL.

### Entity-Relationship Diagram (ERD)


<img width="651" height="414" alt="AVIATION SCHEMA DIAGRAM" src="https://github.com/user-attachments/assets/abaa7abe-4891-4bb3-b57e-a7fa43b48193" />




### Database Performance & Segregation Strategy
A core feature of this architecture is the deliberate isolation of operational flight status data (`flights`) from historical, multi-causal disruption logs (`delay_logs`). 

In a high-frequency hub environment, the `flights` table experiences constant transactional updates (OLTP) regarding gate changes, passenger counts, and dynamic timestamp tracking. By offloading granular, multi-row delay reasons (e.g., a single flight suffering from 20 minutes of weather delays *plus* 15 minutes of late-arriving catering) into a separate `delay_logs` table, we ensure the core transactional engine stays lean. This architectural segregation prevents database locking and maintains sub-millisecond query execution speeds during peak operational crises when volume spikes.

## 3. Business Logic Highlight: The Disruption Impact Algorithm
An effective IT Systems Analyst doesn't just display raw data; they build programmatic rules that translate complex operational realities 
into actionable business decisions. This system features a custom optimization engine that scores delayed flights to determine gate and ground-crew priority.

The mathematical scoring equation is structured as follows:

$$\text{Disruption Impact Score} = (\text{Total Delay Minutes} \times 1.2) + (\text{Passenger Count} \times 0.8) + \text{Operational Penalty}$$

### Decoding the Logic Weights:
* **Time Severity ($\times 1.2$):** Delay time is weighted heavily because extended delays exponentially increase crew duty costs
* and trigger statutory passenger compensation thresholds (e.g., EU261/Flight Rights frameworks).
* **Volume Impact ($\times 0.8$):** Passenger count ensures high-capacity widebody aircraft (carrying hundreds of passengers with
* downline connections) are prioritized over lower-capacity regional jets to limit the total volume of disrupted customers.
* **Operational Penalty Matrix:** The algorithm dynamically appends fixed cost penalties based on the systemic root cause of the delay:
    * *Mechanical/Technical Delay:* $+50$ points. (Triggers immediate AOG priority; forces infrastructure allocation close to maintenance hubs).
    * *Carrier/Airline-Caused Delay:* $+30$ points. (High internal liability where the airline bears direct financial responsibility for accommodation and rebooking).
    * *Weather/Air Traffic Control Delay:* $+0$ points. (Force majeure events where downline passenger compensation liabilities are legally legally mitigated).

By running this algorithm programmatically via Python, airport duty managers receive an instantaneous, objective priority queue rather than relying on manual,
ad-hoc decision-making during a scheduling shock.
