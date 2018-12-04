using Printf
using DataFrames
include("utils.jl")

function choose_playing_action(player_state, policy)
    """
    Takes in the state of a player's hand and their policy
    Returns the card they are playing
    """
    if policy == 0:
        return aggressive_play(player_state)
    end
    elif policy == 1:
        return random_play(player_state)
    end
    elif policy == 2:
        return flower_play(player_state)
    end
end

function choose_betting_action(player_state, cur_bet)
    #2 optons: pass or increase
    # There are two main reasons a player would want to pass.
    # They have laid down a skull so they **know** they can't be successful
    # They have enough uncertainty about other players cards that they do not **think** they can be successful
    cards, opp_state = player_state_as_tuple(player_state)
    skull = false
    for i in 1:4
        #we have already played the skull
        if cards[i] == 2
            skull = true
        end
    end
    if skull == true
        #pass almost all the time..
        return 15
    end
    #choose to increase bet
    #todo, this is a bad strategy... we need to have some number that is telling us how many we think we can get..
    #so like if that number is 3 and the bet is at 3 we wouldn't want to increase
    return cur_bet+1
end

function choose_flipping_action(cur_turn, board_state)
    """
    Takes in board_state
    Returns the player whose card will be flipped next
    """
    #if a player has cards in front of them, they must flip their own.
    if board_state[cur_turn, 0] > 0
        return cur_turn
    end
    #can choose any player it wants... probably want to do this as a beta or dirichlet..
    #but for now it's random...
    num_players = length(board_state)-1
    else
        #if we do not have proper checks to make sure there is definitely
        #a player who has a card to flip, this could be infinite
        while True
            player = rand(0:num_players)
            #we know this will never be true if the number is the current player
            if board_state[player, 0] > 0
                return player
            end
        end
    end
end
