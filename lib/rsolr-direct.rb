require 'java'
require 'rsolr'

#
# Connection for JRuby + DirectSolrConnection
#
module RSolr
  
  module Direct
    
    def direct_connect opts={}, &blk
      client = RSolr::Client.new Connection::Direct.new(opts)
      if block_given?
        yield client
        client.connection.close
        nil
      else
        client
      end
    end

  end
  
  extend Direct
  
  class Connection::Direct
    
    include RSolr::Connection::Requestable
    
    attr_accessor :opts
    
    # opts can be an instance of org.apache.solr.servlet.DirectSolrConnection
    # if opts is NOT an instance of org.apache.solr.servlet.DirectSolrConnection
    # then...
    # required: opts[:home_dir] is absolute path to solr home (the directory with "data", "config" etc.)
    def initialize(opts, &block)
      if defined?(Java::OrgApacheSolrCore::SolrCore) and opts.is_a?(Java::OrgApacheSolrCore::SolrCore)
        @connection = org.apache.solr.servlet.DirectSolrConnection.new(opts)
      elsif defined?(Java::OrgApacheSolrServlet::DirectSolrConnection) and opts.is_a?(Java::OrgApacheSolrServlet::DirectSolrConnection)
        @connection = opts
      else
        opts[:data_dir] ||= File.join(opts[:home_dir].to_s, 'data')
        @opts = opts
      end
    end
    
    # sets the @connection instance variable if it has not yet been set
    def connection
      @connection ||= (
        org.apache.solr.servlet.DirectSolrConnection.new(opts[:home_dir], @opts[:data_dir], nil)
      )
    end
    
    def close
      if @connection
        @connection.close
        @connection=nil
      end
    end
    
    # send a request to the connection
    # request '/select', :q=>'something'
    # request '/update', :wt=>:xml, '</commit>'
    def request(path, params={}, data=nil, opts={})
      data = data.to_xml if data.respond_to?(:to_xml)
      url = build_url(path, params)
      begin
        body = connection.request(url, data)
      rescue
        raise RSolr::RequestError.new($!.message)
      end
      {
        :status_code => 200,
        :url=>url,
        :body=>body,
        :path=>path,
        :params=>params,
        :data=>data,
        :headers => {},
        :message => ''
      }
    end
    
  end
  
end