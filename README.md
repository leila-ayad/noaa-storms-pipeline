# NOAA Storms Pipeline

A one-command pipeline that downloads a year of NOAA Storm Events data, converts it to GeoParquet, and lands it ready for analysis in DuckDB, GeoPandas, or QGIS.

## What it does

`pipeline.sh` takes a year (default: 2024), pulls the raw `details` file from NOAA's public archive, decompresses it, and converts it to a single GeoParquet file at `data/processed/storms_{YEAR}.parquet`.

Total runtime: about 90 seconds for a typical year on a home internet connection.

## The data

- **Source:** [NOAA Storm Events Database](https://www.ncei.noaa.gov/data/storm-events/)
- **License:** Public domain (US federal data)
- **What's in it:** every recorded storm event in the United States for the given year, including type, location, and damages

## How to run it

Requires GDAL (for `ogr2ogr`) and standard Unix utilities (`curl`, `gunzip`).

```bash
git clone https://github.com/{your-username}/noaa-storms-pipeline.git
cd noaa-storms-pipeline
chmod +x pipeline.sh
./pipeline.sh
```

To run for a specific year:

```bash
./pipeline.sh 2023
```

## What I learned

Bash syntax had more gotchas than expected — small things like missing $ before variable names (mkdir -p RAW_DIR vs mkdir -p "$RAW_DIR"), using / instead of \ for line continuation, and the spacing rules inside [ ]. Each one caused a real error that wasn't obvious to diagnose. Next time, I'll test each step incrementally by echoing variables before using them (echo "$RAW_DIR") to catch missing $ or wrong paths early. Also, I'll read variable definitions carefully before using them in paths. For example, RAW_CSV already included the directory, so prepending $RAW_DIR again caused the unzip step to silently skip. I think it's the right call to include the directory name inside a variable, instead of just the file name, but I wasn't tuned in to that pattern when I started this project.

## Stack

- bash
- curl
- GDAL / ogr2ogr
- GeoParquet
