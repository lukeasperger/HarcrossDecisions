using Printf
using DataFrames

function initialize_game(num_players)
    """
    usage: game_state = initialize_game(num_players)

    Creates an initial game state, which is a tuple of the full board
    state and the state of each player's hand.

    board_state has dimensions num_players by 4 where each element
    represents a card played (or not played). 0 represents no card, 1
    represents a flower, and 2 represents a skull. An example board state
    is shown below.

    │        │ Card 1 │ Card 2 │ Card 3 │ Card 4 │
    ├────────┼────────┼────────┼────────┼────────┤
    │Player 1│ 1      │ 2      │ 0      │ 0      │
    │Player 2│ 1      │ 1      │ 0      │ 0      │
    │Player 3│ 2      │ 0      │ 0      │ 0      │
    │Player 4│ 1      │ 0      │ 0      │ 0      │

    hand_state had dimensions num_players by 2 and represents the number of
    flowers and skulls each player has. An example hand state is shown below

    │        │ Flowers │ Skulls │
    ├────────┼─────────┼────────┤
    │Player 1│ 2       │ 0      │
    │Player 2│ 1       │ 1      │
    │Player 3│ 3       │ 0      │
    │Player 4│ 2       │ 1      │

    """

    board_state = zeros(Int64, num_players, 4)
    hand_state = repeat([3 1], num_players)
    game_state = (board_state, hand_state)

    return game_state
end

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
    opp_state = 1
    for i:length(opp_state)
        opp_state +=
    end

end

function simulate_move()

end

function simulate_round(state, action, opp_policies)
    """
    Takes in player's state action as well as an array of opponent policies
    and simulates game up until the player's next turn. Array of opponent
    policies should be in turn order.
    """
end
