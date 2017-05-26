# Patch for zh-CN generation

module RailsGuides
  class Markdown
    private

    def dom_id(nodes)
      dom_id = dom_id_text(nodes.last)

      # Fix duplicate node by prefix with its parent node
      if @node_ids[dom_id]
        if @node_ids[dom_id].size > 1
          duplicate_nodes = @node_ids.delete(dom_id)
          new_node_id = "#{duplicate_nodes[-2][:id]}-#{duplicate_nodes.last[:id]}"
          duplicate_nodes.last[:id] = new_node_id
          @node_ids[new_node_id] = duplicate_nodes
        end

        dom_id = "#{nodes[-2][:id]}-#{dom_id}"
      end

      @node_ids[dom_id] = nodes
      dom_id
    end

    def dom_id_text(node)
      if node.previous_element && node.previous_element.inner_html.include?('class="anchor"')
        node.previous_element.children.first['id']
      else
        escaped_chars = Regexp.escape('\\/`*_{}[]()#+-.!:,;|&<>^~=\'"')

        node.text.downcase.gsub(/\?/, "-questionmark")
                          .gsub(/!/, "-bang")
                          .gsub(/[#{escaped_chars}]+/, " ").strip
                          .gsub(/\s+/, "-")
      end
    end

    def generate_index
      if @headings_for_index.present?
        raw_index = ""
        @headings_for_index.each do |level, node, label|
          if level == 1
            raw_index += "1. [#{label}](##{node[:id]})\n"
          elsif level == 2
            raw_index += "    * [#{label}](##{node[:id]})\n"
          end
        end

        @index = Nokogiri::HTML.fragment(engine.render(raw_index)).tap do |doc|
          doc.at("ol")[:class] = "chapters"
        end.to_html

        # Only change `Chapters' to `目录'
        @index = <<-INDEX.html_safe
        <div id="subCol">
          <h3 class="chapter"><img src="images/chapters_icon.gif" alt="" />目录</h3>
          #{@index}
        </div>
        INDEX
      end
    end

  end
end
