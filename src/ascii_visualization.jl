function create_ascii_tree(tree::MCTS.MCTSTree,
                           root_id::Any = 1; 
                           max_depth::Int = 5,
                           show_stats::Bool = true)::String
    lines = String[]
    visited_nodes = Set{Any}()
    
    function format_state_node(state_id::Any, show_stats::Bool)
        state = tree.s_labels[state_id]
        if show_stats
            visits = tree.total_n[state_id]
            return "$(state) (N:$visits)"
        else
            return string(state)
        end
    end
    
    function format_action_node(action_id::Any, show_stats::Bool)
        action = tree.a_labels[action_id]
        if show_stats
            visits = tree.n[action_id]
            q_val = round(tree.q[action_id], digits=3)
            return "$(action) (N:$visits, Q:$q_val)"
        else
            return string(action)
        end
    end
    
    function traverse_tree(state_id::Any, prefix::String, is_last::Bool, 
                          current_depth::Int, max_depth::Int)
        # Prevent infinite loops and respect depth limit
        if state_id in visited_nodes || current_depth > max_depth
            return
        end
        
        push!(visited_nodes, state_id)
        
        # Current node connector
        connector = is_last ? "+-- " : "+-- "
        node_label = format_state_node(state_id, show_stats)
        push!(lines, prefix * connector * node_label)
        
        # Prepare prefix for children
        child_prefix = prefix * (is_last ? "    " : "|   ")
        
        # Get action children
        action_children = tree.child_ids[state_id]
        
        for (i, action_id) in enumerate(action_children)
            is_last_action = (i == length(action_children))
            
            # Draw action node
            action_connector = is_last_action ? "+-- " : "+-- "
            action_label = format_action_node(action_id, show_stats)
            push!(lines, child_prefix * action_connector * action_label)
            
            # Prepare prefix for state children of this action
            action_child_prefix = child_prefix * (is_last_action ? "    " : "|   ")
            
            # Find next states from this action (using transition data if available)
            next_states = find_next_states(tree, action_id)
            
            for (j, next_state_id) in enumerate(next_states)
                is_last_state = (j == length(next_states))
                traverse_tree(next_state_id, action_child_prefix, is_last_state, 
                            current_depth + 1, max_depth)
            end
        end
    end
    
    # Start with root node label
    root_label = format_state_node(root_id, show_stats)
    push!(lines, root_label)
    
    # Begin traversal
    traverse_tree(root_id, "", true, 0, max_depth)
    
    return join(lines, "\n")
end

function find_next_states(tree::MCTS.MCTSTree, action_id::Any)
    next_states = Any[]

    if !isempty(tree._vis_stats)
        for ((said, sid), count) in tree._vis_stats
            if said == action_id
                push!(next_states, sid)
            end
        end
    end

    return unique(next_states)
end
