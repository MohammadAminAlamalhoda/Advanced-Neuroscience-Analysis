function [states, transitions] = update_state_and_transition(states_r, states,...
                                                        transitions, direction_no, learning_rate,...
                                                        discount_factor, agent_loc, agent_loc_past, ...
                                                        target_value, cat_value, softmax_func)
    transition = cell2mat(transitions(agent_loc_past(1,1), agent_loc_past(1,2)));
    probs = softmax_func(transition);
    % updating state values
    delta = states_r(agent_loc(1,1), agent_loc(1,2)) + ...
            discount_factor*states(agent_loc(1,1), agent_loc(1,2)) - ...
            states(agent_loc_past(1,1), agent_loc_past(1,2));
        
    states(agent_loc_past(1,1), agent_loc_past(1,2)) = states(agent_loc_past(1,1), agent_loc_past(1,2)) + ...
                                                        learning_rate*delta*probs(1, direction_no);

    if states(agent_loc_past(1,1), agent_loc_past(1,2)) >  target_value/2
        states(agent_loc_past(1,1), agent_loc_past(1,2)) = target_value - 1;
    elseif states(agent_loc_past(1,1), agent_loc_past(1,2)) <  cat_value/2
        states(agent_loc_past(1,1), agent_loc_past(1,2)) = cat_value + 1;
    end

    % updating transition values
    for i = 1:length(transition)
        if i == direction_no
            transition(1, i) = transition(1, i) + (1-probs(1, i)) * delta;
        else
            transition(1, i) = transition(1, i) - probs(1, i) * delta;  
        end
    end
    transitions(agent_loc_past(1,1), agent_loc_past(1,2)) = {transition};
end