using Printf
using DataFrames
using JSON

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
    flowers and skulls each player has in possession at this phase in the game.
    An example hand state is shown below

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

function choose_action(player_state, phase, cur_bet, policy, passed, cur_player)
    """
    action 1: place flower
    action 2: place skull
    actions 3-14: place a bet of action - 2 (ie action 3 is betting 1)
    action 15: pass
    """
    #@printf("phase is %d, curbet is %d, player state is %d\n", phase, cur_bet, player_state)
    if phase == 1 # playing phase: actions 1-14 are valid
        # note - we could alternatively just select from 3 actions if that's
        # easier
        #15 actions sound good. but we need to know how to transition from playing to betting
        #@printf("action is %d\n", action)
        action = choose_playing_action(player_state, policy)
        if action > 2 # if player decides to bet
            phase = 2 # move to betting phase
            @printf("Player %d bets %d\n", cur_player, action - 2)
        end
    elseif phase == 2 # betting phase: actions 3-15 are valid
        action = choose_betting_action(player_state, cur_bet) + 2
        if action != 15
            @printf("Player %d bets %d\n", cur_player, action - 2)
        else
            @printf("Player %d passes\n", cur_player)
        end
    elseif phase == 3 # flipping phase
        #this is redundant... I don't think we need this -Kaylee
        action = choose_flipping_action(cur_player)
        # will need to add some way of knowing which cards are left
    end

    return (action, phase)
end

function process_json()
    #JSON.jl is trash so i had to process this json string manually :(

    data=JSON.parsefile("skull_Q.json")
    data = data[3:end-1]
    d = split(data, """,\"""" )
    values = []
    dict = Dict()
    for i in 1:length(d)
        string = d[i]
        right_paren = findfirst(")", string)
        key = string[2:right_paren[1]-1]
        keys = split(key, ",")
        sa_pair = (parse(Int32, keys[1]),parse(Int32, keys[2][1:end]))
        value = string[right_paren[1] + 3:end]
        value = parse(Float64,value)
        dict[sa_pair] = value
    end
    return dict
end


function choose_model_action(player_state, phase, cur_bet, cur_player)
     """
    Chooses action based on optimal policies learned in Value Iteration that
    are contained in Skull_Q.json

    action 1: place flower
    action 2: place skull
    actions 3-14: place a bet of action - 2 (ie action 3 is betting 1)
    action 15: pass
    """
    dict = process_json()
    max = -10 #impossible to go below, used as initial threshold for action selection
    if phase == 1 # playing phase: actions 1-14 are valid
        # note - we could alternatively just select from 3 actions if that's
        # easier
        #15 actions sound good. but we need to know how to transition from playing to betting
        #action = choose_playing_action(player_state, policy)
        action = 3 # default if nothing better
        for key in keys(dict)
            if player_state in key
                if key[1] < 15 && dict[key] > max
                    max = dict[key]
                    action = key[1]
                end
            end
        end
        if action > 2 # if player decides to bet
            phase = 2 # move to betting phase
            @printf("Player %d bets %d\n", cur_player, action - 2)
        end
    elseif phase == 2 # betting phase: actions 3-15 are valid
        #@printf("phase = 2\n")
        action = 15 # default to passing if nothing better
        for key in keys(dict)
            if player_state in key
                if key[1] > 3 && key[1] < 16 && dict[key] > max
                    max = dict[key]
                    action = key[1]
                end
            end
        end
        if action != 15
            @printf("Player %d bets %d\n", cur_player, action - 2)
        else
            @printf("Player %d passes\n", cur_player)
        end
    elseif phase == 3 # flipping phase
        #this is redundant... I don't think we need this -Kaylee
        action = choose_flipping_action(cur_player)
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
        @printf("Player %d places flower\n", cur_turn)

    elseif action == 2 # play skull

        if hand_state[cur_turn, 2] < 1
            @printf("Invalid action: Player does not have skull")
        end

        hand_state[cur_turn, 2] -= 1
        board_state[cur_turn, findfirst(isequal(0), board_state[cur_turn, :])] = 2
        @printf("Player %d places skull\n", cur_turn)
    end

    game_state = (board_state, hand_state)
    return game_state

end

function flip_cards(game_state, cur_turn, cur_bet)
    """
    Takes in a game_state, current player and the current bet.
    The player will then choose which cards to flip until
    they have met their bet or have gotten skulled.

    Returns the current player as a positive number if they were successful
        and the current player as a negative number if not.

    """
    (board_state, hand_state) = game_state
    #a boolean to determine whether or not the player flipping has seen a skull
    #a player will have to flip over as many cards as they have guessed unless they see skull
    skulled = false
    while (cur_bet > 0)
        player_state = game_state_to_player_state(game_state, cur_turn)
        player_to_flip = choose_flipping_action(cur_turn, board_state)
        ind = findlast(!isequal(0), board_state[player_to_flip, :])
        #flipped a flower
        if board_state[player_to_flip, ind] == 1
            board_state[player_to_flip, ind] = 0
            @printf("Player %d flips over player %d's flower\n", cur_turn, player_to_flip)
            cur_bet -= 1
        #flipped a skull
        else
            board_state[player_to_flip, ind] = 0
            @printf("Player %d flips over player %d's skull\n", cur_turn, player_to_flip)
            return -1 * cur_turn
        end
    end

    return cur_turn
end

function simulate_to_next_turn(game_state, action, policies, starting_player, phase, cur_bet, passed)
    """
    Takes in player's state action as well as an array of policies
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
            cur_turn += 1
            continue
        elseif sum(passed) == num_players - 1
            #a player has won the bet and will flip cards to try and score a point
            #if result is +, then the player scores,
            #if result is -, then the player was not successful.
            @printf("%d players have passed, player %d is flipping\n", sum(passed), cur_turn)
            result = flip_cards(game_state, cur_turn, cur_bet)
            break
        end
        player_state = game_state_to_player_state(game_state, cur_turn)
        if cur_turn != 1
            (action, phase) = choose_action(player_state, phase, cur_bet, policies[cur_turn], passed, cur_turn)
        end
        if action == 1 || action == 2 # card-playing actions
            #perhaps based on the beta I suggested using for flipping,
            #we should have some sort o indicator here maybe that tells us
            #what card we think this is, bc for our betting strategy we need to
            #know how many we think we could flip. -Kaylee
            game_state = update_game_state(game_state, action, cur_turn)
        elseif action < 15 # betting action
            cur_bet = action - 2
        else # passed action
            passed[cur_turn] = 1
        end
        cur_turn += 1
    end

    return (game_state, phase, cur_bet, passed, result)
end

function result_to_reward(result)
    # parse result into rewards
    if result == 0 # game still going
        reward = 0
    elseif result > 1 # opponent wins
        reward = -4
    elseif result == 1 # player wins
        reward = 5
    elseif result == -1 # player loses card
        reward = -2
    else # opponent loses card
        reward = 1
    end
end

function simulate_round(num_players, starting_player, policies, filename)
    """
    Simulates a full round of Skull. Each player starts with 4 cards. Any player
    can go first, but player 1 is always the one we are keeping track of (the
    one learning) and the rest are opponents.

    Phase is int from 1 to 3. Phase 1 is playing, phase 2 is betting, phase 3 is
    flipping.
    """

    # Initialization
    game_state = initialize_game(num_players) # players 2, 3, 4 are opponents
    player_state = game_state_to_player_state(game_state, 1)
    passed = zeros(Int64, num_players) # no players have passed yet
    phase = 1 # playing phase
    cur_bet = 0 # we are not in betting yet
    @printf("Starting game: Player %d is first\n", starting_player)
    reward = 0
    if starting_player != 1
        action = 0 # don't choose action yet if oppenent is going first
    else
        #(action, phase) = choose_model_action(player_state, phase, cur_bet, starting_player)
        (action, phase) = choose_action(player_state, phase, cur_bet, policies[1], passed, starting_player)
    end

    (game_state, phase, cur_bet, passed, result) = simulate_to_next_turn(game_state, action, policies, starting_player, phase, cur_bet, passed)

    # record whatever we need for model (ie. state, reward, transition)
    next_player_state = game_state_to_player_state(game_state, 1)
    if action != 0
        open(filename, "a") do io
            @printf(io, "%d, %d, %d, %d\n", player_state, action, next_player_state, result_to_reward(result))
        end
    end

    while result == 0 # non-zero result means someone has won
        player_state = game_state_to_player_state(game_state, 1)
        if passed[1] == 0
            #(action, phase) = choose_model_action(player_state, phase, cur_bet, 1)
            (action, phase) = choose_action(player_state, phase, cur_bet, policies[1], passed, 1)
        else
            action = 0
        end
        (game_state, phase, cur_bet, passed, result) = simulate_to_next_turn(game_state, action, policies, 1, phase, cur_bet, passed)

        # record whatever we need for model (ie. state, reward, transition)
        next_player_state = game_state_to_player_state(game_state, 1)
        reward = result_to_reward(result)
        open(filename, "a") do io
            @printf(io, "%d, %d, %d, %d\n", player_state, action, next_player_state, reward)
        end
    end

    @printf("Player 1's reward is %d\n\n", reward)
    return reward
end

filename = ("test.txt")

num_players = 4
starting_player = 1
policies = [1 0 1 2] # random, aggressive, random, flower

#creating a beta distribution for each player, with a prior of 1,1
beta_flips = [1 for r in 1:num_players, c in 1:2]
# for i in 1:100000
#     for j in 1:4
#         policies[j] = rand(0:2)
#     end
#     starting_player = rand(1:4)
#     simulate_round(num_players, starting_player, policies, filename)
# end

reward_sum = 0
for i in 1:100
    starting_player = rand(1:4)
    reward = simulate_round(num_players, starting_player, policies, filename)
    global reward_sum += reward
end

@printf("Final reward is %d\n", reward_sum)
