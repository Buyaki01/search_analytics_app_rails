class SearchesController < ApplicationController
  require 'net/http'
  require 'json'

  def index
  end

  def create
    search_query = params[:search_query]

    user_ip = request.remote_ip
  
    wikipedia_url = "https://en.wikipedia.org/w/api.php?action=query&format=json&list=search&srsearch=#{search_query}&utf8=1&srlimit=20&prop=extracts|pageimages&exintro=true&piprop=thumbnail&pithumbsize=300&titles=#{search_query}&utf8=1&srlimit=20"

    begin
      uri = URI(wikipedia_url)
      response = Net::HTTP.get(uri)
      data = JSON.parse(response)

      if data['query'] && data['query']['pages']
        # Extract relevant information
        page_info = data['query']['pages'].values.first
        pageid = page_info['pageid']
        title = page_info['title']
        text = page_info['extract']
        image_url = page_info.dig('thumbnail', 'source')

      else
        # Handle the case where 'pages' key is not present
        Rails.logger.error("No pages found in the API response.")
      end
    rescue Errno::ETIMEDOUT => e
      Rails.logger.error("Failed to connect to Wikipedia API: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("An error occurred: #{e.message}")
    end
  end
end
