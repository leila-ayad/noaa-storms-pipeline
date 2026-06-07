#!/usr/bin/env bash
#
# pipeline.sh — Download a year of NOAA Storm Events, convert to GeoParquet.
#
# Usage:   ./pipeline.sh [YEAR]
# Example: ./pipeline.sh 2024
#
# Requires: bash, curl, gunzip, ogr2ogr (GDAL >= 3.5)
#
# This is a starter scaffold. Read the comments. Replace the [TODO] markers
# with the actual logic. Do not change the structure unless you have a reason.

set -euo pipefail

# -----------------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------------

# Year to pull. Override by passing as the first argument.
YEAR="${1:-2024}"

# NOAA file naming pattern. The "c{CREATED_DATE}" portion changes when NOAA
# republishes a year. Look at https://www.ncei.noaa.gov/pub/data/swdi/stormevents/csvfiles/
# and update CREATED_DATE for the year you want.
CREATED_DATE="20260323"

BASE_URL="https://www.ncei.noaa.gov/pub/data/swdi/stormevents/csvfiles/"
FILE_NAME="StormEvents_details-ftp_v1.0_d${YEAR}_c${CREATED_DATE}.csv.gz"
URL="${BASE_URL}/${FILE_NAME}"

RAW_DIR="data/raw"
PROCESSED_DIR="data/processed"
RAW_GZ="${RAW_DIR}/${FILE_NAME}"
RAW_CSV="${RAW_DIR}/${FILE_NAME%.gz}"
OUT_PARQUET="${PROCESSED_DIR}/storms_${YEAR}.parquet"

# -----------------------------------------------------------------------------
# Step 1: Set up directories
# -----------------------------------------------------------------------------

echo "[1/4] Setting up directories"

mkdir -p $RAW_DIR
mkdir -p $PROCESSED_DIR

# -----------------------------------------------------------------------------
# Step 2: Download the raw file
# -----------------------------------------------------------------------------

echo "[2/4] Downloading ${FILE_NAME}"

if [ -f "$RAW_DIR/$FILE_NAME" ]; then 
    echo "${FILE_NAME} already exists; skipping..."
else 
    echo "Downloading ${FILE_NAME}"
    curl -L --fail -o "${RAW_DIR}/${FILE_NAME}" "${URL}"

           # Guard against failed downloads (HTML error pages are small)
        FILE_SIZE=$(wc -c < "${RAW_DIR}/${FILE_NAME}" | tr -d ' ')
        if [ "$FILE_SIZE" -lt 10000 ]; then
            echo "❌ ERROR: $GZ_FILE is only $FILE_SIZE bytes — download likely failed."
            echo "   Check that the filename is current at:"
            echo "   $BASE_URL/"
            rm "$RAW_DIR/$FILE_NAME"
            exit 1
        fi
        echo "✅ Downloaded ($FILE_SIZE bytes compressed)"
fi

# -----------------------------------------------------------------------------
# Step 3: Decompress
# -----------------------------------------------------------------------------

echo "[3/4] Decompressing"

if [ -f "${RAW_CSV}" ]; then
    echo "Skipping...${RAW_DIR}/${RAW_CSV} already exists"
else
    echo "Unzipping ${RAW_GZ}"
    gunzip -k "${RAW_GZ}"
fi

# -----------------------------------------------------------------------------
# Step 4: Convert CSV to GeoParquet
# -----------------------------------------------------------------------------

echo "[4/4] Converting to GeoParquet"

ogr2ogr -f PARQUET "$OUT_PARQUET" "$RAW_CSV" \
        -oo X_POSSIBLE_NAMES=BEGIN_LON \
        -oo Y_POSSIBLE_NAMES=BEGIN_LAT \
        -a_srs EPSG:4326

echo "Done. Output: ${OUT_PARQUET}"
echo "Open it in DuckDB:"
echo "  duckdb -c \"INSTALL spatial; LOAD spatial; SELECT COUNT(*) FROM read_parquet('${OUT_PARQUET}');\""
