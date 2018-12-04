using DataFrames
using Printf

function game_state_to_player_state(game_state, player_num)
    """
    Takes in a full game state and returns the state for any given player in
    the game.
    """
    (board_state, hand_state) = game_state
    num_players = size(board_state)[1]

    cards = board_state[player_num,:]
    indiv_state = 1 + cards[1] + 3*cards[2] + 3^2*cards[3] + 3^3*cards[4]

    # rearrange board arrays so they're in turn order after current player
    opp_board = zeros(Int64, num_players - 1, 4)
    for i = 1:(num_players - 1)
        opp_board[i, :] = board_state[1 + mod(i + player_num - 1,4),:]
    end
    opp_board = clamp.(opp_board, 0, 1)
    opp_state = sum(opp_board) # opp_state is just number of cards played

    player_state = indiv_state + opp_state * 81 # 1296 possibilities

    return player_state
end

function player_state_as_tuple(player_state)
    """
    Puts the player state in a form that is easier to interpret. Returns an
    array of the cards a player has placed on the board and also the total
    number of cards played by the opponents.
    """

    opp_state = div(player_state, 3^4)
    indiv_state = mod(player_state, 3^4)

    cards = zeros(Int64, 4)
    cards[1] = mod(indiv_state - 1, 3)
    cards[2] = mod(div(indiv_state - 1, 3), 3)
    cards[3] = mod(div(indiv_state - 1, 3^2), 3)
    cards[4] = mod(div(indiv_state - 1, 3^3), 3)

    return (cards, opp_state)

end
