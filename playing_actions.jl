using Printf
using DataFrames
include("utils.jl")

#if a player has a skull, they play it.
function aggressive_play(player_state)
    #cards are the cards that they have played on the table
    cards, opp_state = player_state_as_tuple(player_state)
    skull = true
    for i in 1:4
        #the skull has already been played
        if cards[i] == 2
            skull = false
        end
    end
    if skull
        return 2
    end
    else
        return 1
    end
end

function random_play(player_state)
    cards, opp_state = player_state_as_tuple(player_state)
    skull = 1
    flowers = 3
    for i in 1:4
        #the skull has already been played
        if cards[i] == 2
            skull -= 1
        end
        if cards[i] == 1
            flower -= 1
        end
    end
    if flowers > 0
        if skull > 0
            #both avail
            card = rand(1:2)
            return card
        end
        else
            #skull not available
            return 1
        end
    end
    else
        #no flowers
        return 2
    end
end

function flower_play(player_state)
    cards, opp_state = player_state_as_tuple(player_state)
    flowers = 3
    for i in 1:4
        #counts how many flowers have been players
        if cards[i] == 1
            flower -= 1
        end
    end
    if flowers > 0
        return 1
    end
    else
        return 2
    end
end
