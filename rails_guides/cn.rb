# Patch for cn generator
require 'uri'

module RailsGuides
  class Markdown
    private

    def dom_id(nodes)
      dom_id = dom_id_text(nodes.last.text)

      # Fix duplicate node by prefix with its parent node
      if @node_ids[dom_id]
        if @node_ids[dom_id].size > 1
          duplicate_nodes = @node_ids.delete(dom_id)
          new_node_id = "#{duplicate_nodes[-2][:id]}-#{duplicate_nodes.last[:id]}"
          duplicate_nodes.last[:id] = new_node_id
          @node_ids[new_node_id] = duplicate_nodes
        end

        dom_id = "#{nodes[-2][:id]}-#{dom_id}" if nodes.size > 1
      end

      @node_ids[dom_id] = nodes
      dom_id
    end

    def dom_id_text(text)
      URI.escape(text, /[^\-_.!~*'()a-zA-Z\d;\/?:@&=+$,]/)
    end
  end
end
