require 'yaml'

module RailsGuides
  module Helpers
    def guide(name, url, options = {}, &block)
      link = content_tag(:a, :href => url) { name }
      result = content_tag(:dt, link)

      if options[:work_in_progress]
        result << content_tag(:dd, '原文撰写中', :class => 'work-in-progress')
      end

      if options[:needs_translation]
        result << content_tag(:dd, '待翻译', :class => 'work-in-progress')
      end

      result << content_tag(:dd, capture(&block))
      result
    end

    def documents_by_section
      if ENV['GUIDES_LANGUAGE'] == 'zh-CN'
        @documents_by_section ||= YAML.load_file(File.expand_path('../../source/documents_zh-CN.yaml', __FILE__))
      else
        @documents_by_section ||= YAML.load_file(File.expand_path('../../source/documents.yaml', __FILE__))
      end
    end

    def documents_flat
      documents_by_section.flat_map {|section| section['documents']}
    end

    def finished_documents(documents)
      documents.reject { |document| document['work_in_progress'] }
    end

    def docs_for_menu(position=nil)
      if position.nil?
        documents_by_section
      elsif position == 'L'
        documents_by_section.to(3)
      else
        documents_by_section.from(4)
      end
    end

    def author(name, nick, image = 'credits_pic_blank.gif', &block)
      image = "images/#{image}"

      result = tag(:img, :src => image, :class => 'left pic', :alt => name, :width => 91, :height => 91)
      result << content_tag(:h3, name)
      result << content_tag(:p, capture(&block))
      content_tag(:div, result, :class => 'clearfix', :id => nick)
    end

    def code(&block)
      c = capture(&block)
      content_tag(:code, c)
    end
  end
end
