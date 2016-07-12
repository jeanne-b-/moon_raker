module MoonRaker
  module Helpers
    def markup_to_html(text)
      return '' if text.nil?
      if MoonRaker.configuration.markup.respond_to? :to_html
        MoonRaker.configuration.markup.to_html(text.strip_heredoc)
      else
        text.strip_heredoc
      end
    end

    attr_accessor :url_prefix

    def request_script_name
      Thread.current[:moon_raker_req_script_name] || ''
    end

    def request_script_name=(script_name)
      Thread.current[:moon_raker_req_script_name] = script_name
    end

    def full_url(path)
      unless @url_prefix
        @url_prefix = ''
        @url_prefix << request_script_name
        @url_prefix << MoonRaker.configuration.doc_base_url
      end
      path = path.sub(/^\//, '')
      ret = "#{@url_prefix}/#{path}"
      ret.insert(0, '/') unless ret =~ /\A[.\/]/
      ret.sub!(/\/*\Z/, '')
      ret
    end

    def include_javascripts
      %w( bundled/jquery.min.js
          bundled/bootstrap.js
          bundled/prettify.js
          moon_raker.js ).map do |file|
        "<script type='text/javascript' src='#{MoonRaker.full_url("javascripts/#{file}")}'></script>"
      end.join("\n").html_safe
    end

    def include_stylesheets
      %w( bundled/bootstrap.min.css
          bundled/prettify.css
          bundled/bootstrap-responsive.min.css
          bundled/material_icons.css ).map do |file|
        "<link type='text/css' rel='stylesheet' href='#{MoonRaker.full_url("stylesheets/#{file}")}'/>"
      end.join("\n").html_safe
    end

    def label_class_for_error(err)
      case err[:code]
        when 200
          'label label-info'
        when 201
          'label label-success'
        when 204
          'label label-info2'
        when 401
          'label label-warning'
        when 403
          'label label-warning2'
        when 422
          'label label-important'
        when 404
          'label label-inverse'
        else
          'label'
      end
    end
  end
end
