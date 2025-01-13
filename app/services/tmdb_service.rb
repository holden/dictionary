class TmdbService
  include HTTParty
  base_uri 'https://api.themoviedb.org/3'

  def initialize
    @options = {
      headers: {
        'Authorization' => "Bearer #{Rails.application.credentials.tmdb.access_token}",
        'Content-Type' => 'application/json'
      }
    }
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
end 