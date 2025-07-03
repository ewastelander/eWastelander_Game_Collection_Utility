#!/bin/bash

csv_file="game_collection.csv"

if [ ! -f "$csv_file" ]; then
    echo "CSV file not found!"
    exit 1
fi

# Skip header and extract the cost column
mapfile -t costs < <(tail -n +2 "$csv_file" | cut -d',' -f4 | tr -d '$')

total_count=0
total_cost=0

for cost in "${costs[@]}"; do
    if [[ "$cost" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        total_cost=$(echo "$total_cost + $cost" | bc)
        ((total_count++))
    fi
done

echo ""
echo "🎮 Total Items in Collection: $total_count"
printf "💵 Total Spent on Collection : \$%.2f\n" "$total_cost"
echo ""

read -n 1 -s -r -p "Press any key to return..."
echo
