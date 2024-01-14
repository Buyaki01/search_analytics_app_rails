class SearchesController < ApplicationController
  require 'net/http'
  require 'json'
  include ActionView::Helpers::SanitizeHelper

  before_action :most_searched_today, only: [:create]
  before_action :most_searched_last_seven_days, only: [:create]
  before_action :most_searched_last_month, only: [:create]

  def create
    search_query = params[:search_query]

    if search_query.present?
      user_ip = request.remote_ip

      Search.create!(
        query: search_query,
        user_ip: user_ip,
        timestamp: Time.current
      )
  
      wikipedia_url = "https://en.wikipedia.org/w/api.php?action=query&format=json&list=search&srsearch=#{search_query}&utf8=1&srlimit=20&prop=extracts|pageimages&exintro=true&piprop=thumbnail&pithumbsize=300&titles=#{search_query}&utf8=1&srlimit=20"

      begin
        uri = URI(wikipedia_url)
        response = Net::HTTP.get(uri)
        data = JSON.parse(response)

        if data['query'] && data['query']['search']
          search_results = data['query']['search']
          
          @results_array = []

          search_results.each do |result|
            pageid = result['pageid']
            title = result['title']

            text_with_tags = result['snippet']
            text_without_tags = strip_tags(text_with_tags)

            result_hash = {
              pageid: pageid,
              title: title,
              text: text_without_tags,
            }

            @results_array << result_hash
          end

        else
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
       @results_array = []
    end
  end

  private

  def most_searched_today
    @most_searched_today = Search.where('created_at >= ?', Time.current.beginning_of_day)
                                  .group(:query)
                                  .order('count_query DESC')
                                  .limit(10)
                                  .count(:query)
  end

  def most_searched_last_seven_days
    @most_searched_last_seven_days = Search.where('created_at >= ?', 7.days.ago)
                                        .group(:query)
                                        .order('count_query DESC')
                                        .limit(10)
                                        .count(:query)
  end

  def most_searched_last_month
    @most_searched_last_month = Search.where('extract(month from created_at) = ?', 1.month.ago.month)
                                       .group(:query)
                                       .order('count_query DESC')
                                       .limit(10)
                                       .count(:query)
  end
end
