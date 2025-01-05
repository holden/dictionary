class AuthorLookupService
  class NotFoundError < StandardError; end

  def self.find_or_create_author(name)
    # First try to find existing author
    author = Person.find_by("lower(title) = ?", name.downcase)
    return author if author.present?

    # Try OpenLibrary first
    author_data = OpenLibraryService.lookup_author(name)
    if author_data.present?
      # Get ConceptNet data as well
      concept = ConceptNetService.lookup_person(name)
      
      return Person.create!(
        title: author_data.fetch("name"),
        open_library_id: author_data.fetch("key"),
        concept_net_id: concept&.fetch("@id")
      )
    end

    # If OpenLibrary fails, try ConceptNet
    concept = ConceptNetService.lookup_person(name)
    if concept.present?
      return Person.create!(
        title: concept.fetch("name"),
        concept_net_id: concept.fetch("@id")
      )
    end

    # If both fail, create basic record
    Person.create!(
      title: name.titleize
    )
  rescue ActiveRecord::RecordInvalid => e
    raise NotFoundError, "Could not create author record for '#{name}'"
  end
end 