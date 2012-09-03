require "active_support"

module ApiUmbrella
  module Gatekeeper
    module Rack
      # Rack middleware to return error responses in the correct format (XML,
      # JSON, etc). This allows other rack middlewares to return error messages
      # simply as strings. Then depending on the format of the request, the error
      # message will be wrapped appropriately. For example:
      #
      # /foo.xml
      # <?xml version="1.0" encoding="UTF-8"?>
      # <errors><error>The error message</error></errors>
      # 
      # /foo.json
      # {"errors": ["The error message"]}
      #
      # Note: This only applies to errors generated by other middleware inside
      # this Gatekeeper. Other errors (like those generated by the web services
      # after successuflly passing through Gatekeeper) aren't handled by this and
      # will need to be handled within the destination applications.
      class FormattedErrorResponse
        def initialize(app, options = {})
          @app = app
          @options = options
        end

        def call(env)
          status, headers, response = @app.call(env)

          if(status != 200)
            request = Rack::Request.new(env)

            format_extension = ::File.extname(request.path).to_s.downcase
            if(format_extension.empty? && !request.GET["format"].blank?)
              format_extension = ".#{request.GET["format"].to_s.downcase}"
            end

            headers["Content-Type"] = Rack::Mime.mime_type(format_extension, "text/plain")

            # The rack response should be an array (or something that responds to
            # #each). However, rack-throttle incorrectly returns a string for
            # errors, so we'll handle that too.
            error_message = ""
            if(response.kind_of?(String))
              error_message = response
            else
              response.each { |s| error_message << s.to_s }
            end

            response = [error_body(format_extension, error_message.strip)]
          end

          [status, headers, response]
        end

        private

        def error_body(format_extension, message)
          case(format_extension)
          when ".json"
            { :errors => [message] }.to_json
          when ".xml"
            { :error => message }.to_xml(:root => "errors")
          when ".csv"
            "Error\n#{message}"
          else
            "Error: #{message}"
          end
        end
      end
    end
  end
end
