class TmdbService
  include HTTParty
  base_uri 'https://api.themoviedb.org/3'

  def initialize
    @options = {
      headers: {
        'Authorization' => "Bearer #{Rails.application.credentials.tmdb[:access_token]}",
        'Content-Type' => 'application/json'
      }
    }
  end

  def search(query)
    response = self.class.get("/search/multi", @options.merge(query: { query: query }))
    return [] unless response.success?

    results = response['results']
    results.select { |r| r['media_type'].in?(['movie', 'tv']) }.map do |result|
      {
        title: result['title'] || result['name'],
        type: result['media_type'] == 'movie' ? 'Movie' : 'TVShow',
        source_id: result['id'].to_s,
        metadata: {
          overview: result['overview'],
          popularity: result['popularity'],
          poster_path: result['poster_path'] && "https://image.tmdb.org/t/p/w500#{result['poster_path']}",
          release_date: result['release_date'] || result['first_air_date'],
          vote_average: result['vote_average']
        }
      }
    end
  end

  def search_people(query)
    response = self.class.get("/search/person", @options.merge(
      query: { query: query }
    ))
    
    return [] unless response.success?
    
    response['results'].map do |person|
      {
        tmdb_id: person['id'],
        name: person['name'],
        profile_path: person['profile_path'] && "https://image.tmdb.org/t/p/w500#{person['profile_path']}",
        known_for_department: person['known_for_department'],
        popularity: person['popularity']
      }
    end
  end

  def person_details(person_id)
    response = self.class.get("/person/#{person_id}", @options)
    return nil unless response.success?
    
    {
      tmdb_id: response['id'],
      name: response['name'],
      biography: response['biography'],
      birthday: response['birthday'],
      deathday: response['deathday'],
      gender: response['gender'],
      place_of_birth: response['place_of_birth'],
      profile_path: response['profile_path'] && "https://image.tmdb.org/t/p/w500#{response['profile_path']}",
      known_for_department: response['known_for_department'],
      popularity: response['popularity'],
      imdb_id: response['imdb_id']
    }
  end

  def multi_search(query)
    response = self.class.get("/search/multi", @options.merge(
      query: { 
        query: query,
        include_adult: false 
      }
    ))
    
    return [] unless response.success?
    
    response['results'].map do |result|
      case result['media_type']
      when 'movie'
        format_movie(result)
      when 'tv'
        format_tv_show(result)
      when 'person'
        format_person(result)
      end
    end.compact
  end

  private

  def format_movie(result)
    {
      type: 'Movie',
      tmdb_id: result['id'].to_s,
      title: result['title'],
      metadata: {
        release_date: result['release_date'],
        overview: result['overview'],
        popularity: result['popularity'],
        vote_average: result['vote_average'],
        poster_path: result['poster_path'] ? "https://image.tmdb.org/t/p/w500#{result['poster_path']}" : nil
      }
    }
  end

  def format_tv_show(result)
    {
      type: 'TVShow',
      tmdb_id: result['id'].to_s,
      title: result['name'],
      metadata: {
        first_air_date: result['first_air_date'],
        overview: result['overview'],
        popularity: result['popularity'],
        vote_average: result['vote_average'],
        poster_path: result['poster_path'] ? "https://image.tmdb.org/t/p/w500#{result['poster_path']}" : nil
      }
    }
  end

  def format_person(result)
    {
      type: 'Person',
      tmdb_id: result['id'].to_s,
      name: result['name'],
      profile_path: result['profile_path'] ? "https://image.tmdb.org/t/p/w500#{result['profile_path']}" : nil
    }
  end
end 