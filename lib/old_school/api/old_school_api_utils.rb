module OldSchool
  module APIUtils

    def init_resource_metadata
      @resource_metadata = get_resource_metadata if @resource_metadata.nil?
      @resource_metadata
    end

    def invalidate_token
      @token = nil   
    end

    def get_resource_metadata
      hash_from_successful_response(get('/ws/v1/metadata'),'metadata')
    end

    def get_token
      return @token unless @token.nil?
      response = Typhoeus.post(
        "#{@host}/oauth/access_token/",
        userpwd: "#{@id}:#{@secret}",
        params: {
          grant_type: 'client_credentials'
        })

      @token = hash_from_successful_response(response, 'access_token')
    end

    def hashes_from_successful_response(response, keys = nil)
      hashes = hash_from_successful_response!(response, keys) { [] }
      hashes = [hashes] unless hashes.is_a?(Array)
      hashes
    end

    def hash_from_successful_response(response, keys = nil)
      hash_from_successful_response!(response, keys) do |body, key|
        raise ResponseError, "Key: #{key} not in response object:\n #{response.body}:\nfrom original:\n#{response.inspect.to_s}" unless body.has_key?(key)
      end
    end

    def hash_from_successful_response!(response, keys)
      keys = [keys] if keys.is_a? String
      keys = [] if keys.nil?

      handle_response_success(response) do
        body = {}
        begin
          body = JSON.parse(response.body)
        rescue
          raise ResponseError, "Could not parse body as JSON: #{response.body}"
        end
        
        while keys.size > 0
          key = keys.shift
          if body.has_key?(key)
            body = body[key]
          else
            if block_given?
              return yield(body, key)
            else
              return nil
            end
          end
        end
        return body
      end
      nil
    end

    def handle_response_success(response)
      if response.success?
        yield
      elsif response.timed_out?
        raise ResponseError, 'the request timed out'
      elsif response.code == 0
        raise ResponseError, response.return_message
      else
        reason = extract_from_response_options(response, :response_headers)
        raise ResponseError, "HTTP request failed #{response.code}:\n#{reason}"
      end
    end

    def extract_from_response_options(response, key)
      begin
        return response.options[key]
      rescue
        return nil
      end
    end

    def get_any_response
      begin
        return yield
      rescue ResponseError => e
        return e
      end
    end

    def default_headers
      {
        Authorization: "Bearer #{get_token}",
        Accept: 'application/JSON',
        'Content-Type'=>'application/JSON'
      }
    end

    def get(uri)
      Typhoeus.get(
        "#{@host}#{uri}",
        headers: default_headers
      )
    end

    def get_wait(uri)
      Typhoeus::Request.new(
        "#{@host}#{uri}",
        method: :get,
        headers: default_headers)
    end

    def put(uri, body)
      Typhoeus.put(
        "#{@host}#{uri}",
        headers: default_headers,
        body: body
      )
    end

    def put_wait(uri, body)
      Typhoeus::Request.new(
        "#{@host}#{uri}",
        headers: default_headers,
        method: :post,
        body: body)
    end

    def delete(uri)
      Typhoeus.delete(
        "#{@host}#{uri}",
        headers: default_headers
      )
    end

    def post(uri, body)
      Typhoeus.post(
        "#{@host}#{uri}",
        headers: default_headers,
        body: body
        )
    end

    def get_with_pagination_url(resource, num_items)
      return [] if num_items == 0 #if paginating for zero items, just return an empty list

      #calculate page size based on 
      page_size = init_resource_metadata["#{resource}_max_page_size"]
      pages = num_items / page_size + 1

      items = []
      pages.each do |page|
        url = yield(page)
        items_from_page = hash_from_successful_response(get(url), ["#{resource}s",resource])
        if items_from_page.is_a? Array
          items_from_page.each {|i| items << i } unless items_from_page.nil?
        else
          items << items_from_page
        end
      end
      items
    end

    def get_many(items, keys, uri_proc, complete_proc = nil)
      hydra = Typhoeus::Hydra.hydra
      requests = []
      items.each do |item|
        uri = uri_proc.call(item)
        request = get_wait(uri)
        request.on_complete {|response| complete_proc.call(response)} unless complete_proc.nil?
        requests << [item, request]
        hydra.queue request
      end

      hydra.run

      responses = {}
      requests.each do |request|
        responses[request[0]] = hash_from_successful_response(request[1].response, keys)
      end
      responses
    end
  end
end