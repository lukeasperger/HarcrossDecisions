using Printf
using DataFrames
include("action_choosing.jl")
include("utils.jl")

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

function choose_action(player_state, phase, cur_bet, policy, passed)
    """
    action 1: place flower
    action 2: place skull
    actions 3-14: place a bet of action - 2 (ie action 3 is betting 1)
    action 15: pass
    """

    if phase == 1 # playing phase: actions 1-14 are valid
        # note - we could alternatively just select from 3 actions if that's
        # easier
        action = choose_playing_action(player_state)
        if action > 2 # if player decides to flip
            phase = 2 # move to flipping phase
        end
    elseif phase == 2 # betting phase: actions 3-15 are valid
        action = choose_betting_action(player_state, cur_bet)
    elseif phase == 3 # flipping phase
        action = choose_flipping_action(player_state)
        # will need to add some way of knowing which cards are left
    end

    return (action, phase)
end

function update_game_state(game_state, action, cur_turn)
    """
    Takes in a game_state, player and action and returns the new game_state
    resulting from the action.

    """

    (board_state, hand_state) = game_state

    if action == 1 # play flower

        if hand_state[cur_turn, 1] < 1
            @printf("Invalid action: Player does not have flower")
        end

        hand_state[cur_turn, 1] -= 1
        board_state[cur_turn, findfirst(isequal(0), board_state[cur_turn, :])] = 1

    elseif action == 2 # play skull

        if hand_state[cur_turn, 2] < 1
            @printf("Invalid action: Player does not have skull")
        end

        hand_state[cur_turn, 2] -= 1
        board_state[cur_turn, findfirst(isequal(0), board_state[cur_turn, :])] = 2
    end

    game_state = (board_state, hand_state)
    return game_state

end

function flip_cards(game_state, cur_turn, cur_bet)
    (board_state, hand_state) = game_state
    while (cur_bet > 0)
        player_state = game_state_to_player_state(game_state, cur_turn)
        player_to_flip = choose_flipping_action(player_state)
        ind = findlast(!isequal(0), board_state[player_to_flip, :])
        if board_state[player_to_flip, ind] == 1
            cur_bet -= 1
        else
            return -1 * cur_turn
        end
    end

    return cur_turn
end

function simulate_to_next_turn(game_state, action, opp_policies,
    starting_player, phase, cur_bet)
    """
    Takes in player's state action as well as an array of opponent policies
    and simulates game up until the player's next turn. Array of opponent
    policies should be in turn order.

    Starting player should be an int representing which player makes the first
    move. If starting_player is not 1, then current player does not take an
    action (action = 0).

    Returns the state of the game

    """

    cur_turn = starting_player
    result = 0 # nobody has won yet

    while cur_turn <= num_players && result == 0
        if passed[cur_turn] == 1
            continue
        elseif sum(passed) == num_players - 1
            result = flip_cards(game_state, cur_turn, cur_bet)
            break
        end
        player_state = game_state_to_player_state(game_state, cur_turn)
        action = choose_action(player_state, phase, cur_bet, policy[cur_turn],
            passed)
        if action == 1 || action == 2 # card-playing actions
            game_state = update_game_state(game_state, action, cur_turn)
        elseif action < 15 # betting action
            cur_bet = action - 2
        else # passed action
            passed[cur_turn] = 1
        cur_turn += 1
    end

    return (game_state, phase, cur_bet, result)

end

function simulate_round(num_players, starting_player)
    """
    Simulates a full round of Skull. Each player starts with 4 cards. Any player
    can go first, but player 1 is always the one we are keeping track of (the
    one learning) and the rest are opponents.

    Phase is int from 1 to 3. Phase 1 is playing, phase 2 is betting, phase 3 is
    flipping.
    """

    # Initialization
    game_state = initialize_game(num_players) # players 2, 3, 4 are opponents
    player_state = player_state(game_state, 1)
    passed = zeros(Int64, num_players) # no players have passed yet
    phase = 1 # playing phase
    cur_bet = 0 # we are not in betting yet

    if starting_player != 1
        action = 0 # don't choose action yet if oppenent is going first
    else
        (action, phase) = choose_action(player_state)
    end

    (game_state, phase, cur_bet, result) = simulate_to_next_turn()

    while (result == 0) # non-zero result means someone has won

        player_state = game_state_to_player_state(game_state, 1)
        (action, phase) = choose_action(player_state, phase, policy)
        (game_state, phase, cur_bet, result) = simulate_to_next_turn(game_state, phase)

        # TODO record whatever we need for model (ie. state, reward, transition)
    end

    return result

end
