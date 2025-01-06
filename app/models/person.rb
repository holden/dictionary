class Person < Topic
  # Set STI type explicitly
  self.inheritance_column = :type

  # Person-specific behavior
  def self.model_name
    Topic.model_name
  end

  has_many :authored_quotes, class_name: 'Quote', foreign_key: :author_id
  has_many :authored_definitions, class_name: 'Definition', as: :source

  def self.find_or_create_from_open_library(name)
    # First try exact match
    person = find_by('lower(title) = ?', name.downcase)
    return person if person

    # Then try OpenLibrary
    open_library_data = OpenLibraryService.search_author(name)
    return nil unless open_library_data

    create_from_open_library(open_library_data)
  rescue => e
    Rails.logger.error "Error finding/creating person from OpenLibrary: #{e.message}"
    nil
  end

  private

  def self.create_from_open_library(data)
    raw_data = data[:raw_data]
    
    create(
      title: data[:name],
      type: 'Person',
      open_library_id: data[:open_library_id],
      metadata: {
        open_library: {
          birth_date: data[:birth_date],
          death_date: data[:death_date],
          alternate_names: raw_data['alternate_names'],
          top_subjects: raw_data['top_subjects'],
          top_work: raw_data['top_work'],
          work_count: raw_data['work_count'],
          ratings: {
            average: raw_data['ratings_average'],
            count: raw_data['ratings_count'],
            distribution: {
              '1': raw_data['ratings_count_1'],
              '2': raw_data['ratings_count_2'],
              '3': raw_data['ratings_count_3'],
              '4': raw_data['ratings_count_4'],
              '5': raw_data['ratings_count_5']
            }
          },
          reading_stats: {
            want_to_read: raw_data['want_to_read_count'],
            already_read: raw_data['already_read_count'],
            currently_reading: raw_data['currently_reading_count'],
            total: raw_data['readinglog_count']
          },
          raw_data: raw_data  # Store complete raw data for future use
        }
      }
    )
  end
end 