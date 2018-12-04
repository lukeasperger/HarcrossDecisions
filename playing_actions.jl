using Printf
using DataFrames
include("utils.jl")

function aggressive_play(skull, flowers)
    """
    they want to play their skull, but not always first because
    the top of their stack is going to stump people..
    >first turn
        -play skull first 10% of time
        -play flower 90% of time
        -never bet
    if possible
        >play skull second with 50% chance
    if possible
        >play skull third with 50% chance
    this player bets rarely, and usually only low to egg people on
    """
    #skull avail..
    if skull == 1
        #first turn.
        if flowers == 3
            odds = rand(1:10)
            if odds == 1
                return 2
            else
                return 1
            end
        elseif flowers == 0
            #no flowers to play..
            return 2
        else
            #play skull at 50% odds.
            odds = rand(1:2)
            if odds  1
                return 2
            else
                return 1
            end
    end
    else
        odds = rand(1:20)
        if odds == 1
            #bet 2 with 5% likelihood
            return 4
        end
        return 1
    end
end

function random_play(skull, flowers)
    if flowers > 0
        if skull > 0
            if flowers == 3
                #first turn, have to play a card
                move = rand(1:2)
            else
                #both avail, or we can bet...
                #choosing 5 arbitrarily.. means that our initial bet will always be 3
                move = rand(1:5)
            end
            return move
        else
            #skull not available, prob don't wanna bet.
            return 1
        end
    else
        #no flowers, either bet or play skull ;)
        card = rand(2:5)
        return card
    end
end

function flower_play(skull, flowers)
    """
    they want to always play their flower when they can
    >first turn
        -always play flower
    >second turn
        - always play flower
    >third turn
        -50% of time they will bet.
            -1/3 of the this time they bet 2, 1/3 bet 3, 1/3 bet 4...
    >Last turn
        -play their skull 1/25 time, otherwise bet.
    """
    if flowers > 0
        #have flowers to play
        if flowers == 1
            #we have two flowers down
            odds = rand(1:2)
            if odds == 1
                #bet 50% of the time
                return rand(4:6)
            end
        end
        return 1
    else
        #no flowers, either bet or play skull ;)
        card = rand(2:6)
        if card == 2
            #since this is the flower policy and we don't want to play skulls much,
            # reducing the event space for laying skulls from 1/5 to 1/25
            card = rand(2:6)
        end
        if card == 3
            #we know that we can successfully flip over our own three.
            card += 1
        end
        return card
    end
end
