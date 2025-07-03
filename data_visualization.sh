#!/bin/bash

csv_file="game_collection.csv"

if [ ! -f "$csv_file" ]; then
    echo "CSV file not found!"
    exit 1
fi

paginate_summary() {
    local -n count_map_ref=$1
    local -n cost_map_ref=$2
    local -n sorted_keys_ref=$3
    local title="$4"
    local total_games=$5
    local total_cost=$6

    local page=0
    local page_size=10
    local total_keys=${#sorted_keys_ref[@]}

    while true; do
        clear
        echo "📊 Stats by $title — Page $((page + 1)) / $(((total_keys + page_size - 1) / page_size))"
        echo "--------------------------------------------------"
        for ((i = page * page_size; i < (page + 1) * page_size && i < total_keys; i++)); do
            key="${sorted_keys_ref[$i]}"
            count=${count_map_ref["$key"]}
            subtotal=${cost_map_ref["$key"]}
            printf "%-20s %5d games  | \$%-10.2f\n" "$key" "$count" "$subtotal"
        done
        echo "--------------------------------------------------"
        echo "Total items: $total_games"
        printf "Total spent : \$%.2f\n" "$total_cost"
        echo ""
        echo "N = Next   P = Previous   Q = Quit"
        read -p "Choose: " nav
        nav=${nav^^}
        if [[ "$nav" == "N" && $(( (page + 1) * page_size )) -lt $total_keys ]]; then
            ((page++))
        elif [[ "$nav" == "P" && $page -gt 0 ]]; then
            ((page--))
        elif [[ "$nav" == "Q" ]]; then
            break
        fi
    done
}


calculate_stats() {
    field_name="$1"
    field_index="$2"

    clear
    mapfile -t data < <(tail -n +2 "$csv_file")
    declare -A count_map
    declare -A cost_map
    total_value=0
    total_count=0

    for row in "${data[@]}"; do
        IFS=',' read -r -a fields <<< "$row"
        key="${fields[$((field_index - 1))]}"
        cost="${fields[3]//\$}"

        if [[ -z "$key" || -z "$cost" || ! "$cost" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            continue
        fi

        (( count_map["$key"]++ ))
        cost_map["$key"]=$(echo "${cost_map["$key"]:-0} + $cost" | bc)
        total_value=$(echo "$total_value + $cost" | bc)
        (( total_count++ ))
    done

    mapfile -t sorted_keys < <(printf "%s\n" "${!count_map[@]}" | sort)
    paginate_summary count_map cost_map sorted_keys "$field_name" "$total_count" "$total_value"
}
show_games_over_time() {
    clear
    echo "📅 Games Collected Over Time"
    echo "1) Games per Year"
    echo "2) Games per Month (for a Year)"
    echo "3) Back"
    read -p "Choose an option [1-3]: " time_choice

    case $time_choice in
        1)
            clear
            echo "📊 Games per Year"
            cut -d',' -f5 "$csv_file" | tail -n +2 |
            grep -E '^[0-9]{4}' |
            cut -d'-' -f1 |
            sort | uniq -c | sort -k2 |
            awk '{printf "%-6s %3s games\n", $2, $1}'
            read -n 1 -s -r -p "Press any key to return..."
            echo ;;
        2)
            read -p "Enter year (e.g., 2023): " selected_year
            clear
            echo "📆 Games per Month in $selected_year"
            cut -d',' -f5 "$csv_file" | tail -n +2 |
            grep "^$selected_year-" |
            cut -d'-' -f2 |
            sort | uniq -c | sort -k2 |
            awk 'BEGIN {
                split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", m);
            }
            {
                month_num = $2 + 0
                printf "%-3s  %3s games\n", m[month_num], $1
            }'
            read -n 1 -s -r -p "Press any key to return..."
            echo ;;
        3) return ;;
        *) echo "Invalid input." ;;
    esac
}

while true; do
    clear
    echo "===== Data Visualization ====="
    echo "1) Games per Platform"
    echo "2) Physical vs Digital"
    echo "3) Games per Store"
    echo "4) Games Over Time"
    echo "5) Back to Main Menu"
    read -p "Choose an option [1-5]: " choice

    case $choice in
        1) calculate_stats "Platform" 2 ;;
        2) calculate_stats "Format (Physical/Digital)" 3 ;;
        3) calculate_stats "Store" 6 ;;
        4) show_games_over_time ;;
        5) break ;;
        *) echo "Invalid option." ;;
    esac
done
