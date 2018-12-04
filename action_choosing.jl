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

function choose_betting_action()
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
