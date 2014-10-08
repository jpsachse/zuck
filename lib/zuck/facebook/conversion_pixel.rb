module Zuck
  class ConversionPixel < RawFbObject

    CREATION_FIELDS = [:name, :tag]

    known_keys :account_id,
               :id,
               :creator,
               :js_pixel,
               :name,
               :status,
               :tag

    parent_object :ad_account
    list_path     :offsitepixels

    def initialize(graph, data = {}, parent=nil)
      super(graph, data, parent)
    end

    def save
      response = false

      active_fields = self.data.keys
      missing_fields = (CREATION_FIELDS - active_fields)
      if (missing_fields.length != 0)
        raise "You need to set the following fields before saving: #{missing_fields.join(', ')}"
      end

      # Setup the post body for Facebook 

      args = {"name" => self.name,
               "tag" => self.tag}

      if (!self.id)
        account_id = Zuck::AdAccount.id_for_api(self.account_id)
        fb_response = Zuck.graph.put_connections(account_id,"offsitepixels", args)
        if (fb_response && fb_response.has_key?('id'))
          self.id = fb_response['id']
          response = true
        end
      else 
        if (self.is_dirty?)          
          # Build up a hash with the dirty fields
          post_data = {}
          @dirty_keys.each do |dirty_key|
            post_data[dirty_key] = args[dirty_key.to_s]
          end
          
          # The FB API will return true if the save is successful. False otherwise.
          response = Zuck.graph.graph_call(self.id, post_data, "post")        
        end
      end

      reset_dirty if response
      return response
    end

    def delete
        Zuck.graph.delete_object(self.id)
    end

    def snippet 
      if !self.js_pixel
        response = Zuck.graph.get_connections(self.id, "snippets")
        if (response && response.has_key?('data') && 
          response['data'].has_key?(self.id) && 
          response['data'][self.id].has_key?('js'))
          self.js_pixel = response['data'][self.id]['js']
        end
      end
      self.js_pixel
    end

  end
end