#!/bin/bash

csv_file="game_collection.csv"
page_size=10
version_options=("Standard" "Deluxe" "Collector's" "Limited")

if [ ! -f "$csv_file" ]; then
    echo "CSV file not found!"
    exit 1
fi

view_details() {
    local entry="$1"
    IFS=',' read -r game_name platform format cost date store version cover box manual extras <<< "$entry"

    while true; do
        echo ""
        echo "====== Game Details ======"
        echo "1) Game Name      : $game_name"
        echo "2) Platform       : $platform"
        echo "3) Format         : $format"
        echo "4) Cost           : $cost"
        echo "5) Date Purchased : $date"
        echo "6) Store          : $store"
        echo "7) Version        : $version"
        echo "8) Cover Included : $cover"
        echo "9) Original Box   : $box"
        echo "10) Manual        : $manual"
        echo "11) Extras        : $extras"
        echo "=========================="
        echo "E) Edit   D) Delete   B) Back   M) Main Menu"
        read -p "Choose an action: " action
        action=${action^^}

        case "$action" in
            E) edit_entry ;;
            D)
                read -p "Are you sure you want to delete this entry? (Y/N): " confirm
                confirm=${confirm^^}
                if [[ "$confirm" == "Y" ]]; then
                    awk -v line="$entry" '$0 != line' "$csv_file" > tmp && mv tmp "$csv_file"
                    echo "Entry deleted."
                    sleep 1
                    break
                fi ;;
            M) exit 0 ;;
            B) break ;;
            *) echo "Invalid choice." ;;
        esac
    done
}

edit_entry() {
    read -p "Enter field number to edit (1-11): " field

    case "$field" in
        1) read -p "New Game Name: " game_name ;;
        2) read -p "New Platform: " platform ;;
        3)
            echo "Format: 1) Physical  2) Digital"
            read -p "Choose format [1/2]: " f
            [[ "$f" == "1" ]] && format="Physical" || format="Digital" ;;
        4)
            read -p "New Cost (e.g., 59.99): $" cost_raw
            cost="\$${cost_raw}" ;;
        5) read -p "New Purchase Date (YYYY-MM-DD): " date ;;
        6) read -p "New Store: " store ;;
        7)
            echo "Version options:"
            for i in "${!version_options[@]}"; do
                printf "%d) %s\n" $((i + 1)) "${version_options[$i]}"
            done
            read -p "Choose version [1-${#version_options[@]}]: " v
            version="${version_options[$((v-1))]}" ;;
        8|9|10)
            label=$(case $field in 8) echo "Cover";; 9) echo "Original Box";; 10) echo "Manual";; esac)
            read -p "$label included? (Y/N): " yn
            [[ "${yn^^}" == "Y" ]] && val=TRUE || val=FALSE
            case $field in
                8) cover=$val ;;
                9) box=$val ;;
                10) manual=$val ;;
            esac ;;
        11) read -p "New Extras: " extras ;;
        *) echo "Invalid field number." ;;
    esac

    new_entry="$game_name,$platform,$format,$cost,$date,$store,$version,$cover,$box,$manual,$extras"
    awk -v line="$entry" '$0 != line' "$csv_file" > tmp && mv tmp "$csv_file"
    echo "$new_entry" >> "$csv_file"
    entry="$new_entry"
    echo "✅ Field updated."
    sleep 1
}

paginate_results() {
    local -n data=$1
    local total=${#data[@]}
    local page=0

    while true; do
        clear
        total_pages=$(( (total + page_size - 1) / page_size ))
        echo ""
        echo "📚 Showing $page_size per page — $total entries total"
        echo "📄 Page $((page + 1)) of $total_pages"

        for ((i = page * page_size; i < (page + 1) * page_size && i < total; i++)); do
            IFS=',' read -r name platform _ <<< "${data[$i]}"
            printf "%2d) %s (%s)\n" $((i + 1)) "$name" "$platform"
        done

        echo ""
        echo "N = Next   P = Previous   Q = Quit"
        read -p "Select entry number or action: " input
        input=${input^^}

        if [[ "$input" == "Q" ]]; then
            break
        elif [[ "$input" == "N" && $(( (page + 1) * page_size )) -lt $total ]]; then
            ((page++))
        elif [[ "$input" == "P" && $page -gt 0 ]]; then
            ((page--))
        elif [[ "$input" =~ ^[0-9]+$ && "$input" -ge 1 && "$input" -le $total ]]; then
            view_details "${data[$((input - 1))]}"
            mapfile -t data < <(printf "%s\n" "${data[@]}" | sort -t',' -k1)
            total=${#data[@]}
            page=$(( (input - 1) / page_size ))
        else
            echo "Invalid input."
            sleep 1
        fi
    done
}
paginate_categories() {
    local -n options=$1
    local label=$2
    local column=$3
    local page=0
    local total=${#options[@]}

    while true; do
        clear
        total_pages=$(( (total + page_size - 1) / page_size ))
        echo ""
        echo "Available $label:"
        echo "📄 Page $((page + 1)) of $total_pages — $total total"

        for ((i = page * page_size; i < (page + 1) * page_size && i < total; i++)); do
            count=$(awk -F',' -v val="${options[$i]}" -v col="$column" '$col == val' "$csv_file" | wc -l)
            printf "%2d) %-20s (%d games)\n" $((i + 1)) "${options[$i]}" "$count"
        done
        echo ""
        echo "N = Next   P = Previous   Q = Cancel"
        read -p "Select a $label number or action: " input
        input=${input^^}

        if [[ "$input" == "Q" ]]; then
            return 1
        elif [[ "$input" == "N" && $(( (page + 1) * page_size )) -lt $total ]]; then
            ((page++))
        elif [[ "$input" == "P" && $page -gt 0 ]]; then
            ((page--))
        elif [[ "$input" =~ ^[0-9]+$ && "$input" -ge 1 && "$input" -le $total ]]; then
            selected_index=$((input - 1))
            return $((selected_index + 10))
        else
            echo "Invalid input."
            sleep 1
        fi
    done
}

browse_all() {
    mapfile -t games < <(tail -n +2 "$csv_file" | sort -t',' -k1)
    paginate_results games
}

browse_by_platform() {
    mapfile -t platforms < <(tail -n +2 "$csv_file" | cut -d',' -f2 | sort | uniq)
    paginate_categories platforms "Platforms" 2
    rc=$?
    if [[ "$rc" -lt 10 ]]; then return; fi
    result=$((rc - 10))
    selected="${platforms[$result]}"
    mapfile -t filtered < <(awk -F',' -v p="$selected" '$2 == p' "$csv_file" | sort -t',' -k1)
    paginate_results filtered
}

browse_by_store() {
    mapfile -t stores < <(tail -n +2 "$csv_file" | cut -d',' -f6 | sort | uniq)
    paginate_categories stores "Stores" 6
    rc=$?
    if [[ "$rc" -lt 10 ]]; then return; fi
    result=$((rc - 10))
    selected="${stores[$result]}"
    mapfile -t filtered < <(awk -F',' -v s="$selected" '$6 == s' "$csv_file" | sort -t',' -k1)
    paginate_results filtered
}

while true; do
    clear
    echo "===== Browse Game Collection ====="
    echo "1) Browse All Games"
    echo "2) Browse by Platform"
    echo "3) Browse by Store"
    echo "4) Return to Main Menu"
    read -p "Choose an option [1-4]: " choice

    case "$choice" in
        1) browse_all ;;
        2) browse_by_platform ;;
        3) browse_by_store ;;
        4) break ;;
        *) echo "Invalid option." ; sleep 1 ;;
    esac
done
