require 'zuck/facebook/ad_creative'

module Zuck
  class AdGroup < RawFbObject
    attr_accessor :creative_id

    BID_TYPE_CPC = 'CPC'
    BID_TYPE_CPM = 'CPM'
    BID_TYPE_MULTI_PREMIUM = 'MULTI_PREMIUM'
    BID_TYPE_ABSOLUTE_OCPM = 'ABSOLUTE_OCPM'
    BID_TYPE_CPA = 'CPA'

    CONVERSION_ACTION_INSTALL = 'mobile_app_install'

    REQUIRED_FIELDS = [:name, :bid_type, :bid_info, :campaign_id, :creative_id, :targeting]

    # The [fb docs](https://developers.facebook.com/docs/reference/ads-api/adaccount/)
    # were incomplete, so I added here what the graph explorer
    # actually returned.
    known_keys :account_id,
               :adgroup_status,
               :bid_info,
               :bid_type,
               :campaign_id,
               :conversion_specs,
               :created_time,
               :creative_ids,               
               :id,
               :disapprove_reason_descriptions,
               :last_updated_by_app_id,
               :name,
               :targeting,
               :tracking_specs,
               :updated_time,
               :view_tags

    parent_object :ad_campaign
    list_path     :adgroups
    connections   :ad_creatives

    # @param graph [Koala::Facebook::API] A graph with access_token
    # @param data [Hash] The properties you want to assign, this is what
    #   facebook gave us (see known_keys).
    # @param parent [<FbObject] A parent context for this class, must
    #   inherit from {Zuck::FbObject}
    def initialize(graph, data = {}, parent=nil)
      super(graph, data, parent)
      self.bid_type ||= BID_TYPE_ABSOLUTE_OCPM
    end

    # Saves the current creative to Facebook
    # @throws Exception If not all required fields are present
    # @throws Exception If you try to save an exsiting record because we don't support updates yet
    def save
      response = false

      active_fields = self.data.keys
      missing_fields = (REQUIRED_FIELDS - active_fields)
      if (missing_fields.length != 0)
        raise "You need to set the following fields before saving: #{missing_fields.join(', ')}"
      elsif (!self.conversion_specs && (self.bid_type == BID_TYPE_ABSOLUTE_OCPM || self.bid_type == BID_TYPE_CPA))
        raise "You must specify 'conversion_specs' when the bid_type is OCPM or CPA"
      end

      args = {
        "creative" => {'creative_id' => self.creative_id.to_s}.to_json,
        "name" => self.name,
        "campaign_id" => self.campaign_id.to_s,
        "bid_type" => self.bid_type,
        "bid_info" => self.bid_info.to_json,        
        "targeting" => self.targeting.to_json,
        "conversion_specs" => self.conversion_specs.to_json,
        "redownload" => 1,
      }

      puts "------------------------------"
      puts "Saving AdGroup:"
      puts args

      if (!self.id)
        fb_response = Zuck.graph.put_connections(self.account_id,"adgroups", args)
        if (fb_response && fb_response.has_key?('id'))
          self.id = fb_response['id']
          response = true
        end
      else 
        # TODO: potentially support updating a creative
        raise "Updates are not yet implemented for creatives"
      end

      return response
    end

    def self.create(graph, data, ad_campaign)
      path = ad_campaign.ad_account.path
      data['campaign_id'] = ad_campaign.id
      super(graph, data, ad_campaign, path)
    end    

  end
end
