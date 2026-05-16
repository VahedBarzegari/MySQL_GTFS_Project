# GTFS MySQL Project

Load [General Transit Feed Specification (GTFS)](https://gtfs.org/) static data into MySQL and analyze it with SQL. The workflow is agency-agnostic: any transit provider that publishes a GTFS zip can be imported the same way. This repository is built around **TTC (Toronto Transit Commission)** data as the primary example.

This project is **for education only**. It has no financial or commercial purpose—it is meant to help you learn GTFS, SQL, and transit data analysis.

## Data source

TTC GTFS is downloaded from the [City of Toronto Open Data Portal](https://open.toronto.ca/). Thank you to the City of Toronto for making this dataset openly available.

## What is in this repo

| File | Purpose |
|------|---------|
| `convert_format.ipynb` | Reads standard GTFS `.txt` files (`agency`, `calendar`, `routes`, `trips`, `stops`, `stop_times`, `shapes`, etc.) and exports them as `.csv` for import into MySQL. |
| `Project.sql` | SQL examples ordered from **simple to advanced**. They cover many concepts—filtering, aggregation, joins, subqueries, `GROUP BY` / `HAVING`, date conversion, derived tables, CTEs, and building summary tables—applied to routes, stops, trips, calendars, and shapes. |

## Getting started

1. **Download a GTFS feed**  
   For TTC, search the [open data catalogue](https://open.toronto.ca/) for the TTC GTFS package and download the zip. Other agencies publish GTFS on their own sites or regional open-data portals.

2. **Extract the feed**  
   Unzip to get the GTFS text files (e.g. `routes.txt`, `trips.txt`, `stops.txt`).

3. **Optional: convert to CSV**  
   Run `convert_format.ipynb` if you prefer `.csv` files for MySQL import tools.

4. **Import into MySQL**  
   Create a database and load each GTFS file into tables with matching names (`routes`, `trips`, `stops`, `stop_times`, `calendar`, `calendar_dates`, `shapes`, `agency`, and any optional files your feed includes). Use MySQL Workbench, `LOAD DATA`, or your preferred import method.

5. **Run analyses**  
   Open `Project.sql` and work through the examples in order—they start with basic counts and filters and progress to multi-table joins and production-style summary tables. Many examples use TTC-specific patterns (e.g. streetcar `route_type`, night routes, stops near York University); adapt filters and IDs for other agencies.

## GTFS tables used here

Core tables referenced in this project:

- `agency` — transit operator metadata  
- `routes` — lines (bus, streetcar, subway, etc.)  
- `trips` — scheduled runs of a route  
- `stops` — stop locations and names  
- `stop_times` — arrival/departure times per trip and stop  
- `calendar` / `calendar_dates` — which days service runs  
- `shapes` — path geometry and distance along each shape  

After import, you can explore schedules, service coverage, trip lengths, and build derived tables for reporting or further analysis.

## License and attribution

GTFS content is provided by each transit agency under its own terms. When using TTC data, follow the licence and attribution requirements on [open.toronto.ca](https://open.toronto.ca/) for that dataset.
