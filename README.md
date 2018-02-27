# Water When It Counts: Reducing Scarcity through Irrigation Monitoring in Central Mozambique

Replication files for Water When It Counts: Reducing Scarcity through Irrigation Monitoring in Central Mozambique by Paul Christian, Florence Kondylis, Valerie Mueller, Astrid Zwager and Tobias Siegfried

### Abstract
Management of common-pool resources in the absence of individual pricing can lead to suboptimal allocation. In the context of irrigation schemes, this can create water scarcity even when there is sufficient water to meet the total requirements. High-frequency data from three irrigation schemes in Mozambique reveal patterns consistent with inefficiency in allocations. A randomized control trial compares two feedback tools: i) general information, charting the water requirements for common crops, and ii) individualized information, comparing water requirements with each farmer's water use in the same season of the previous year. Both types of feedback tools lead to higher reported and observed sufficiency of water relative to recommendations, and nearly eliminate reports of conflicts over water. The experiment fails to detect an additional effect of individualized comparative feedback relative to a general information treatment

### [Full paper](http://documents.worldbank.org/curated/en/206391519136157728/Water-when-it-counts-reducing-scarcity-through-irrigation-monitoring-in-Central-Mozambique?cid=DEC_PolicyResearchEN_D_INT )

# How to use this repository
This repository contains all the files necessary to replicate the results shown in the paper. To do so, follow the instructions below.

1. **Download the replication folder** by clickling on the `Clone or download` button on the main page of the repository. If you don't have GitHub Desktop installed in your computer, you can still download the files by selecting `Donwload ZIP`. In this case, unzip the downloaded file.

1. **Use the Master do-file to replicate the results.** Results can be replicated by running `Master.do` in the `Do-files` folder. It is only necessary to add your computer's username and path to the downloaded replication folder as described in *PART 2* of `Master.do`. You can select which sections to run by editing the globals in *PART 1*. Make sure to run the *packages* section to install all necessary packages before running the other sections.

1. **Necessary data sets can be found in the Data folder.** Data sets used for analysis are aggregated in different levels and described below. Master data sets in Data/Master data sets contain records of all households and plots listed during surveys and are also required to run the analysis.

1. **Outputs will only be created one you run the Master do-file.** The Output folder and its subfolders will be empty until then. They are only included in this folder to reflect the folder structure in `Master.do` so it can run without errors.

# Data sets description
### Panel data sets

**hhwater_plotcropgs.dta**: Main dataset. Household-plot-crop-growth stage-round observations of water availability and requirement and reports of conflict and water sufficiency. ID variables: *scheme_id*, *plot_id*, *hh_id*, *crop_id*, *gs*, *round*.

**water_plot_long.dta:** Weekly water availability per plot-household combination. ID variables: *week*, *round*, *scheme_id*, *plot_id*, *hh_id*.

**plotweek_watergap.dta:** Similar to *hhwater_plotcropgs.dta*, but disaggregates growth stages into weekly observations. ID variables: *scheme_id*, *plot_id*, *hh_id*, *crop_id*, *round*, *week*.

**furrow_week.dta:** Weekly water availability and requirement at catchment area level. ID variables: *scheme_id*, *furrow_id*, *week*. 

### Master data sets
**master_hh.dta:** Includes all households listed and surveyed across all rounds of data collection. ID variable: *hh_id*.

**master_plot.dta:** Includes all plots listed across all rounds of data collection. ID variable: *plot_id*.

**plot_tracker.dta:** Includes all household-plot combinations listed in each round of data collection. ID variables: *hh_id*, *plot_id*, *round*.
