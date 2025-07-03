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
            E) edit_entry "$entry" ;;
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
    local entry="$1"
    IFS=',' read -r game_name platform format cost date store version cover box manual extras <<< "$entry"
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
        echo "🔍 Showing results ($total found) — Page $((page + 1)) of $total_pages"

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

# 🔍 Main search loop
while true; do
    clear
    echo "===== Search Game Collection ====="
    read -p "Enter search term (or Q to quit): " term
    term="${term,,}"

    [[ "$term" == "q" ]] && break
    [[ -z "$term" ]] && { echo "No search term entered."; sleep 1; continue; }

    mapfile -t filtered < <(awk -F',' -v t="$term" 'tolower($1) ~ t' "$csv_file" | sort -t',' -k1)

    if [[ ${#filtered[@]} -eq 0 ]]; then
        echo "No matching games found for: $term"
        read -n 1 -s -r -p "Press any key to continue..."
        echo
    else
        paginate_results filtered
    fi
done
