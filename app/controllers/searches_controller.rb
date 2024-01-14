class SearchesController < ApplicationController
  require 'net/http'
  require 'json'
  include ActionView::Helpers::SanitizeHelper

  def create
    search_query = params[:search_query]

    if search_query.present?
      user_ip = request.remote_ip
  
      wikipedia_url = "https://en.wikipedia.org/w/api.php?action=query&format=json&list=search&srsearch=#{search_query}&utf8=1&srlimit=20&prop=extracts|pageimages&exintro=true&piprop=thumbnail&pithumbsize=300&titles=#{search_query}&utf8=1&srlimit=20"

      begin
        uri = URI(wikipedia_url)
        response = Net::HTTP.get(uri)
        data = JSON.parse(response)

        if data['query'] && data['query']['search']
          search_results = data['query']['search']
          
          # Create an array to store the results
          @results_array = []

          search_results.each do |result|
            pageid = result['pageid']
            title = result['title']

            # Use the full_sanitizer to remove HTML tags from the text
            text_with_tags = result['snippet']
            text_without_tags = strip_tags(text_with_tags)

            # Create a hash with relevant information and add it to the array
            result_hash = {
              pageid: pageid,
              title: title,
              text: text_without_tags,
            }

            @results_array << result_hash
          end

        else
          # Handle the case where 'pages' key is not present
          Rails.logger.error("No pages found in the API response.")
          @results_array = []
        end
      rescue Errno::ETIMEDOUT => e
        Rails.logger.error("Failed to connect to Wikipedia API: #{e.message}")
        @results_array = []
      rescue StandardError => e
        Rails.logger.error("An error occurred: #{e.message}")
        @results_array = []
      end
    else
       # If search_query is not present, don't perform a search
       @results_array = []
    end
  end
end
