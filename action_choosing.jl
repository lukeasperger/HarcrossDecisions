using Printf
using DataFrames
include("utils.jl")
include("playing_actions.jl")

function choose_playing_action(player_state, policy)
    """
    Takes in the state of a player's hand and their policy
    Returns the card they are playing

    Currently, this is assuming they always will play. Need to know when to transition to betting mode.
    """
    cards, opp_state = player_state_as_tuple(player_state)
    skull = 1
    flowers = 3
    for i in 1:4
        #the skull has already been played
        if cards[i] == 2
            skull -= 1
        end
        if cards[i] == 1
            flowers -= 1
        end
    end
    if policy == 0
        return aggressive_play(skull, flowers)
    elseif policy == 1
        return random_play(skull, flowers)
    elseif policy == 2
        return flower_play(skull, flowers)
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
        return 13
    end

    #choose to increase bet
    #todo, this is a bad strategy... we need to have some number that is telling us how many we think we can get..
    #so like if that number is 3 and the bet is at 3 we wouldn't want to increase

    # add in check so we don't bet more than number of cards
    @printf("opp state is %d\n", opp_state)
    @printf("cards are %d, %d, %d, %d\n", cards[1], cards[2], cards[3], cards[4])
    our_cards = findlast(!isequal(0), cards)
    if iszero(cards)
        our_cards = 0
    end
    num_cards_on_board = opp_state + our_cards
    if cur_bet >= num_cards_on_board
        return 13
    end


    return cur_bet+1
end

function choose_flipping_action(cur_turn, board_state)
    """
    Takes in board_state
    Returns the player whose card will be flipped next
    """
    #if a player has cards in front of them, they must flip their own.
    if board_state[cur_turn, 1] > 0
        return cur_turn
    else
        #can choose any player it wants... probably want to do this as a beta or dirichlet..
        #but for now it's random...
        num_players = 4

        #if we do not have proper checks to make sure there is definitely
        #a player who has a card to flip, this could be infinite
        while true
            if count(!iszero(board_state)) == 0
                @printf("Something is wrong, board empty before all cards flipped\n")
            end
            player = rand(1:num_players)
            #we know this will never be true if the number is the current player
            if board_state[player, 1] > 0
                return player
            end
        end
    end
end
