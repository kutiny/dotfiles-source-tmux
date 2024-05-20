#! /bin/bash
alias t=tmux
alias ta="tmux attach"

function taa() {
    opt=$1
    show_new_menu=0
    if [[ ! -z $opt ]]; then
        if [[ $opt == "-n" ]]; then
            show_new_menu=1
        fi
        shift
    fi

    new_label=" Create new"
    sockets_path=/tmp/tmux-$(id -u)/

    function create_socket() {
        read "s?Server name? "
        read "session?Session name? "

        tmux -L$s new -s$session
    }

    function get_sockets() {
        echo "$(ls $sockets_path)"
    }

    function get_socket_count() {
        sockets=$(get_sockets)
        if [[ -z $sockets ]]; then
            echo 0
        else
            echo "$(get_sockets | wc -l | tr -d ' ')"
        fi
    }

    function get_sessions() {
        socket_name=$1

        tmux -L $socket_name ls &> /dev/null

        if [[ $? -eq 1 ]]; then
            echo ""
        else
            echo "$(tmux -L $socket_name ls | awk -F ':' '{ print $1 }')"
        fi
    }

    function menu() {
        header=$1
        shift
        args=($@)
        echo $args | fzf --height 50% --layout=reverse --prompt='  ' --margin=5% --border --header="$header"
    }

    function get_session_count() {
        socket_name=$1
        sessions=$(get_sessions $socket_name)

        if [[ "$sessions" == "" ]]; then
            echo "0"
        else
            echo "$(echo $sessions | wc -l | tr -d ' ')"
        fi
    }

    function attach_to_socket() {
        socket_name=$1
        session_count=$(get_session_count $socket_name)

        if [[ "$session_count" == "0" ]]; then
            echo -e "There is no session in socket $socket_name. Creating a new one..."
            read "session?Session name? "
            tmux -L $socket_name new -s $session
            return
        elif [[ "$show_new_menu" == "1" || "$session_count" != "1" ]]; then
            session=$(menu "Select session:" "$(get_sessions $socket_name)\n${new_label}")

            if [[ "$session" == "$new_label" ]]; then
                read "session?Session name? "
                tmux -L $socket_name new -s $session
                return
            fi

            if [[ ! -z $session ]]; then
                tmux -L $socket_name attach -t $session
                return
            fi
        else
            tmux -L $socket_name attach
            return
        fi
    }

    function main() {
        socket_count=$(get_socket_count)

        if [[ "$socket_count" == "0" ]]; then
            echo -e "There are no active servers running. Let's create a new one"
            create_socket
            return
        fi

        if [[ $socket_count == "1" && "$show_new_menu" == "0" ]]; then
            attach_to_socket "$(ls $sockets_path | head -1)"
            return
        fi

        socket=$(menu "Select server" "$(get_sockets)\n$new_label")

        if [[ $socket == $new_label ]]; then
            create_socket
            return
        elif [[ $socket != "" ]]; then
            attach_to_socket $socket
            return
        fi

        return
    }

    main
}
