#!/bin/bash

csv_file="game_collection.csv"
header="Game Name,Platform,Physical or Digital,Cost,Date Purchased,Store,Version,Cover,Original Box,Manual,Extras"

version_options=("Original" "Steelbook" "Greatest Hits" "Day One" "Deluxe" "Collectors")

if [ ! -f "$csv_file" ]; then
    echo "$header" > "$csv_file"
fi

collect_inputs() {
    read -p "Enter Game Name: " game_name
    read -p "Enter Platform: " platform

    while true; do
        echo "Select Format:"
        echo "1) Physical"
        echo "2) Digital"
        read -p "Enter choice [1 or 2]: " format_choice
        case "$format_choice" in
            1) format="Physical"; break ;;
            2) format="Digital"; break ;;
            *) echo "Invalid input. Please enter 1 or 2." ;;
        esac
    done

    read -p "Enter Cost (e.g., 59.99): $" cost_input
    cost="\$${cost_input}"

    read -p "Enter Date Purchased (YYYY-MM-DD): " date_purchased
    read -p "Enter Store: " store

    echo "Select Version:"
    for i in "${!version_options[@]}"; do
        printf "%d) %s\n" $((i + 1)) "${version_options[$i]}"
    done
    while true; do
        read -p "Enter choice [1-${#version_options[@]}]: " version_choice
        if [[ "$version_choice" =~ ^[1-9][0-9]*$ ]] && [ "$version_choice" -ge 1 ] && [ "$version_choice" -le ${#version_options[@]} ]; then
            version="${version_options[$((version_choice - 1))]}"
            break
        else
            echo "Invalid input."
        fi
    done

    for field in cover original_box manual; do
        while true; do
            label=$(echo "$field" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
            read -p "$label included? (Y/N): " input
            input=${input^^}
            if [[ "$input" =~ ^[YN]$ ]]; then
                if [[ "$input" == "Y" ]]; then
                    eval $field=TRUE
                else
                    eval $field=FALSE
                fi
                break
            else
                echo "Invalid input."
            fi
        done
    done

    read -p "Any Extras? (e.g., soundtrack): " extras
}
review_and_confirm() {
    while true; do
        echo ""
        echo "======= Summary ======="
        echo "1) Game Name      : $game_name"
        echo "2) Platform       : $platform"
        echo "3) Format         : $format"
        echo "4) Cost           : $cost"
        echo "5) Date Purchased : $date_purchased"
        echo "6) Store          : $store"
        echo "7) Version        : $version"
        echo "8) Cover Included : $cover"
        echo "9) Original Box   : $original_box"
        echo "10) Manual        : $manual"
        echo "11) Extras        : $extras"
        echo "======================="
        echo "Options: S) Save   D) Discard   E) Edit"
        read -p "Choose an option [S/D/E]: " decision
        decision=${decision^^}
        case $decision in
            S) echo "$game_name,$platform,$format,$cost,$date_purchased,$store,$version,$cover,$original_box,$manual,$extras" >> "$csv_file"
               echo "Entry saved." ; break ;;
            D) echo "Entry discarded." ; break ;;
            E) read -p "Enter field number to edit: " field_number
               edit_field "$field_number" ;;
            *) echo "Invalid input." ;;
        esac
    done
}

edit_field() {
    case $1 in
        1) read -p "Enter Game Name: " game_name ;;
        2) read -p "Enter Platform: " platform ;;
        3)
            while true; do
                echo "Select Format:"
                echo "1) Physical"
                echo "2) Digital"
                read -p "Enter choice [1 or 2]: " format_choice
                case "$format_choice" in
                    1) format="Physical"; break ;;
                    2) format="Digital"; break ;;
                    *) echo "Invalid input." ;;
                esac
            done ;;
        4)
            read -p "Enter Cost (e.g., 59.99): $" cost_input
            cost="\$${cost_input}" ;;
        5) read -p "Enter Date Purchased (YYYY-MM-DD): " date_purchased ;;
        6) read -p "Enter Store: " store ;;
        7)
            echo "Select Version:"
            for i in "${!version_options[@]}"; do
                printf "%d) %s\n" $((i + 1)) "${version_options[$i]}"
            done
            while true; do
                read -p "Enter choice [1-${#version_options[@]}]: " v_choice
                if [[ "$v_choice" =~ ^[1-9][0-9]*$ ]] && [ "$v_choice" -ge 1 ] && [ "$v_choice" -le ${#version_options[@]} ]; then
                    version="${version_options[$((v_choice - 1))]}"
                    break
                else
                    echo "Invalid input."
                fi
            done ;;
        8|9|10)
            label=$(case $1 in 8) echo "Cover";; 9) echo "Original Box";; 10) echo "Manual";; esac)
            field=$(case $1 in 8) echo "cover";; 9) echo "original_box";; 10) echo "manual";; esac)
            while true; do
                read -p "$label included? (Y/N): " input
                input=${input^^}
                if [[ "$input" =~ ^[YN]$ ]]; then
                    if [[ "$input" == "Y" ]]; then
                        eval $field=TRUE
                    else
                        eval $field=FALSE
                    fi
                    break
                else echo "Invalid input."
                fi
            done ;;
        11) read -p "Any Extras? (e.g., soundtrack): " extras ;;
        *) echo "Invalid field number." ;;
    esac
}
add_entry() {
    collect_inputs
    review_and_confirm
}
view_entries() {
    echo ""
    column -s, -t < "$csv_file" | less -S
}

while true; do
    clear
    echo ""
    echo "========= eWastelander Game Collection Utility ========="
    echo "1) Add New Game"
    echo "2) Browse Game Collection"
    echo "3) Search for a Game"
    echo "4) Calculate Total Money Spent"
    echo "5) Data Visualization"
    echo "6) Exit"
    read -p "Choose an option [1-6]: " option

    case $option in
        1) add_entry ;;
        2) ./browse_collection.sh ;;
        3) ./search_game.sh ;;
        4) ./calculate_total.sh ;;
        5) ./data_visualization.sh ;;
        6) echo "So Long Y'all!" ; break ;;
        *) echo "Invalid option." ;;
    esac
done
